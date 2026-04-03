import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/email_utils.dart';
import 'package:example/data/utils/repository_db_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/services/csv_import_domain_service.dart';

class GroupRepositoryImpl implements IGroupRepository {
  final DatabaseService _db;
  final CsvImportDomainService _csvImportDomainService;

  GroupRepositoryImpl(
    this._db, {
    CsvImportDomainService? csvImportDomainService,
  }) : _csvImportDomainService =
           csvImportDomainService ?? const CsvImportDomainService();

  bool _looksLikeAlreadyRegistered(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('409') ||
        msg.contains('registrado') ||
        msg.contains('already') ||
        msg.contains('duplicate');
  }

  String _asString(dynamic value) => value?.toString().trim() ?? '';

  String _firstNonEmptyField(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _asString(row[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _userReferenceFromRow(Map<String, dynamic> row) {
    return _firstNonEmptyField(row, const ['user_id', 'id', '_id']);
  }

  String _courseReferenceFromRow(Map<String, dynamic> row) {
    return _firstNonEmptyField(row, const ['course_id', 'id', '_id']);
  }

  String _categoryReferenceFromRow(Map<String, dynamic> row) {
    return _firstNonEmptyField(row, const ['category_id', 'id', '_id']);
  }

  String _groupReferenceFromRow(Map<String, dynamic> row) {
    return _firstNonEmptyField(row, const ['group_id', 'id', '_id']);
  }

  int _domainIdFromReference(String reference, {required int fallback}) {
    if (reference.isEmpty) return fallback;
    return DatabaseService.stableNumericIdFromSeed(reference);
  }

  Future<String> _resolveCourseReference(int courseId) async {
    final rows = await _db.robleRead(RobleTables.course);
    for (final row in rows) {
      final ref = _courseReferenceFromRow(row);
      if (ref.isEmpty) continue;

      final candidateIds = <int>{
        asInt(row['course_id'], fallback: -1),
        asInt(row['id'], fallback: -1),
        asInt(row['_id'], fallback: -1),
      };
      if (candidateIds.contains(courseId)) {
        return ref;
      }
    }

    return courseId.toString();
  }

  String _extractAuthUserId(Map<String, dynamic> payload) {
    String firstNonEmpty(List<dynamic> candidates) {
      for (final candidate in candidates) {
        final text = _asString(candidate);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final topLevel = firstNonEmpty([
      payload['user_id'],
      payload['userId'],
      payload['sub'],
      payload['_id'],
      payload['id'],
    ]);
    if (topLevel.isNotEmpty) return topLevel;

    final user = payload['user'];
    if (user is Map) {
      final userMap = Map<String, dynamic>.from(user);
      final nested = firstNonEmpty([
        userMap['user_id'],
        userMap['userId'],
        userMap['sub'],
        userMap['_id'],
        userMap['id'],
      ]);
      if (nested.isNotEmpty) return nested;
    }

    final accessToken = _asString(payload['accessToken']);
    if (accessToken.isEmpty) return '';

    final claims = _db.decodeJwtClaims(accessToken);
    return _asString(claims['sub']);
  }

  Future<Map<String, dynamic>> _upsertUserProfile({
    required String authUserId,
    required String email,
    required String name,
    required String role,
    Map<String, dynamic>? existingProfile,
  }) async {
    final payload = {
      'user_id': authUserId,
      'email': email,
      'name': name,
      'role': role,
    };

    final existing = existingProfile;
    if (existing != null) {
      final key = existing['_id']?.toString() ?? '';
      if (key.isNotEmpty) {
        await _db.robleUpdate(RobleTables.users, key, payload);
        return {
          ...existing,
          ...payload,
        };
      }
    }

    try {
      return await _db.robleCreate(RobleTables.users, payload);
    } catch (_) {
      final fallbackExisting = existing ?? await _db.robleFindUserByEmail(email);
      if (fallbackExisting == null) rethrow;

      final key = fallbackExisting['_id']?.toString() ?? '';
      if (key.isEmpty) rethrow;

      await _db.robleUpdate(RobleTables.users, key, payload);
      return {
        ...fallbackExisting,
        ...payload,
      };
    }
  }

  String _relationKey(dynamic left, dynamic right) {
    return '${left.toString()}::${right.toString()}';
  }

  Future<void> _ensureUserCourseRelation({
    required String courseReference,
    required String userReference,
    required String role,
    required bool tableAvailable,
    required Set<String> relationKeys,
  }) async {
    if (!tableAvailable) return;
    final key = _relationKey(courseReference, userReference);
    if (relationKeys.contains(key)) return;

    await _db.robleCreate(RobleTables.userCourse, {
      'course_id': courseReference,
      'user_id': userReference,
      'role': role,
    });
    relationKeys.add(key);
  }

  Future<void> _ensureUserGroupRelation({
    required String groupReference,
    required String userReference,
    required bool tableAvailable,
    required Set<String> relationKeys,
  }) async {
    if (!tableAvailable) return;
    final key = _relationKey(groupReference, userReference);
    if (relationKeys.contains(key)) return;

    await _db.robleCreate(RobleTables.userGroup, {
      'group_id': groupReference,
      'user_id': userReference,
    });
    relationKeys.add(key);
  }

  Future<String> _resolveStudentAuthId({
    required String email,
    required String name,
    required String sharedPassword,
    required String teacherAccessToken,
    required String teacherRefreshToken,
    Map<String, dynamic>? cachedProfile,
  }) async {
    final existingProfile = cachedProfile ?? await _db.robleFindUserByEmail(email);
    final existingAuthId = _asString(existingProfile?['user_id']);
    if (existingAuthId.isNotEmpty) {
      return existingAuthId;
    }

    var alreadyRegistered = false;
    var signupPayload = <String, dynamic>{};

    try {
      signupPayload = await _db.robleSignupDirect(
        email: email,
        password: sharedPassword,
        name: name,
      );
    } catch (e) {
      if (!_looksLikeAlreadyRegistered(e)) rethrow;
      alreadyRegistered = true;
    }

    final authIdFromSignup = _extractAuthUserId(signupPayload);
    if (authIdFromSignup.isNotEmpty) {
      return authIdFromSignup;
    }

    if (alreadyRegistered) {
      final refreshedAuthId = _asString(existingProfile?['user_id']);
      if (refreshedAuthId.isNotEmpty) {
        return refreshedAuthId;
      }

      // Legacy fallback to keep import resilient when auth profile exists
      // but does not expose a user_id in local records.
      final seed = DatabaseService.stableNumericIdFromSeed(email);
      return 'legacy-$seed';
    }

    final login = await _db.robleLogin(email: email, password: sharedPassword);
    final authUserId = _extractAuthUserId(login);
    if (authUserId.isEmpty) {
      throw Exception('No se pudo obtener user_id auth para: $email');
    }

    // Restore teacher token context to continue data writes.
    _db.setSessionTokens(
      accessToken: teacherAccessToken,
      refreshToken: teacherRefreshToken,
    );

    return authUserId;
  }

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async {
    final catRows = await _db.robleRead(RobleTables.category);
    final courseRows = await _db.robleRead(RobleTables.course);
    final usersRows = await _db.robleRead(RobleTables.users);

    final usersByReference = <String, Map<String, dynamic>>{};
    for (final u in usersRows) {
      final canonical = _userReferenceFromRow(u);
      if (canonical.isNotEmpty) {
        usersByReference[canonical] = u;
      }

      final legacyId = _asString(u['id']);
      if (legacyId.isNotEmpty) {
        usersByReference.putIfAbsent(legacyId, () => u);
      }

      final rowKey = _asString(u['_id']);
      if (rowKey.isNotEmpty) {
        usersByReference.putIfAbsent(rowKey, () => u);
      }
    }

    final teacherCourseIds = <int>{};
    if (await tableExists(_db, RobleTables.userCourse)) {
      final claims = await _db.readAuthTokenClaims();
      final email = (claims['email'] ?? '').toString().trim().toLowerCase();
      if (email.isNotEmpty) {
        final teacherUser = await _db.robleFindUserByEmail(email);
        final teacherUserCandidates = <String>{
          _asString(teacherUser?['user_id']),
          _asString(teacherUser?['id']),
          _asString(teacherUser?['_id']),
        }..removeWhere((value) => value.isEmpty);

        if (teacherUserCandidates.isNotEmpty) {
          for (final candidate in teacherUserCandidates) {
          final relations = await _db.robleRead(
            RobleTables.userCourse,
            filters: {'user_id': candidate, 'role': 'teacher'},
          );
          for (final rel in relations) {
            teacherCourseIds.add(asInt(rel['course_id']));
          }
          }
        }
      }
    }

    if (teacherCourseIds.isEmpty) {
      for (final c in courseRows) {
        final createdBy = asInt(c['created_by'] ?? c['teacher_id']);
        if (createdBy != teacherId) continue;

        final courseRef = _courseReferenceFromRow(c);
        final domainId = _domainIdFromReference(
          courseRef,
          fallback: rowIdFromMap(c),
        );
        teacherCourseIds.add(domainId);
      }
    }

    if (teacherCourseIds.isEmpty) {
      return const <GroupCategory>[];
    }

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final courseId = asInt(cat['course_id']);
      if (teacherCourseIds.isNotEmpty && !teacherCourseIds.contains(courseId)) {
        continue;
      }

      final catReference = _categoryReferenceFromRow(cat);
      final catId = _domainIdFromReference(
        catReference,
        fallback: rowIdFromMap(cat),
      );
      var grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': catReference},
      );
      if (grpRows.isEmpty) {
        final legacyCategoryRef = catId.toString();
        if (legacyCategoryRef != catReference) {
          grpRows = await _db.robleRead(
            RobleTables.groups,
            filters: {'category_id': legacyCategoryRef},
          );
        }
      }

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final groupReference = _groupReferenceFromRow(grp);
        final grpId = _domainIdFromReference(
          groupReference,
          fallback: rowIdFromMap(grp),
        );
        var memberRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': groupReference},
        );
        if (memberRows.isEmpty) {
          final legacyGroupRef = grpId.toString();
          if (legacyGroupRef != groupReference) {
            memberRows = await _db.robleRead(
              RobleTables.userGroup,
              filters: {'group_id': legacyGroupRef},
            );
          }
        }

        final members = <GroupMember>[];
        for (final membership in memberRows) {
          final userReference = _asString(membership['user_id']);
          if (userReference.isEmpty) continue;

          final user = usersByReference[userReference];
          if (user == null) continue;

          final userId = _domainIdFromReference(
            userReference,
            fallback: asInt(user['id'] ?? user['_id']),
          );

          members.add(
            GroupMember(
              id: userId,
              name: (user['name'] ?? '').toString(),
              username: (user['email'] ?? '').toString(),
            ),
          );
        }

        groups.add(
          CourseGroup(
            id: grpId,
            name: (grp['name'] ?? '').toString(),
            members: members,
          ),
        );
      }

      result.add(
        GroupCategory(
          id: catId,
          name: (cat['name'] ?? '').toString(),
          importedAt: asDate(cat['created_at'] ?? cat['imported_at']),
          groups: groups,
          courseId: courseId,
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }

  @override
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  ) async {
    final teacherTokens = await _db.readAuthTokens();
    final teacherAccessToken = teacherTokens?['access_token']?.toString() ?? '';
    final teacherRefreshToken =
        teacherTokens?['refresh_token']?.toString() ?? '';
    if (teacherAccessToken.isEmpty || teacherRefreshToken.isEmpty) {
      throw Exception('Sesion de profesor no valida para aprovisionar datos');
    }

    final parsed = _csvImportDomainService.parse(csvContent);
    final courseReference = await _resolveCourseReference(courseId);

    final usersByEmail = <String, Map<String, dynamic>>{};
    final authUserIdByEmail = <String, String>{};
    final allUsers = await _db.robleRead(RobleTables.users);
    for (final row in allUsers) {
      final email = normalizeEmail((row['email'] ?? '').toString());
      if (email.isEmpty) continue;
      usersByEmail[email] = row;
      final authUserId = _asString(row['user_id']);
      if (authUserId.isNotEmpty) {
        authUserIdByEmail[email] = authUserId;
      }
    }

    var hasUserCourseTable = false;
    final userCourseRelationKeys = <String>{};
    try {
      final relationRows = await _db.robleRead(RobleTables.userCourse);
      hasUserCourseTable = true;
      for (final relation in relationRows) {
        final relCourseId = _asString(relation['course_id']);
        final relUserId = _asString(relation['user_id']);
        if (relCourseId.isEmpty || relUserId.isEmpty) continue;
        userCourseRelationKeys.add(_relationKey(relCourseId, relUserId));
      }
    } catch (_) {
      hasUserCourseTable = false;
    }

    var hasUserGroupTable = false;
    final userGroupRelationKeys = <String>{};
    try {
      final relationRows = await _db.robleRead(RobleTables.userGroup);
      hasUserGroupTable = true;
      for (final relation in relationRows) {
        final relGroupId = _asString(relation['group_id']);
        final relUserId = _asString(relation['user_id']);
        if (relGroupId.isEmpty || relUserId.isEmpty) continue;
        userGroupRelationKeys.add(_relationKey(relGroupId, relUserId));
      }
    } catch (_) {
      hasUserGroupTable = false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseReference,
    });

    final categoryReference = _categoryReferenceFromRow(catRow);
    final catId = _domainIdFromReference(
      categoryReference,
      fallback: rowIdFromMap(catRow),
    );
    final groups = <CourseGroup>[];

    for (final group in parsed.groups) {
      final grpRow = await _db.robleCreate(RobleTables.groups, {
        'category_id': categoryReference,
        'name': group.name,
      });

      final groupReference = _groupReferenceFromRow(grpRow);
      final grpId = _domainIdFromReference(
        groupReference,
        fallback: rowIdFromMap(grpRow),
      );
      final members = <GroupMember>[];
      for (final member in group.members) {
        final studentEmail = normalizeEmail(member.username);
        final cachedUser = usersByEmail[studentEmail];
        var studentAuthId = authUserIdByEmail[studentEmail] ?? '';
        if (studentAuthId.isEmpty) {
          studentAuthId = await _resolveStudentAuthId(
            email: studentEmail,
            name: member.name,
            sharedPassword: _db.studentDefaultPassword,
            teacherAccessToken: teacherAccessToken,
            teacherRefreshToken: teacherRefreshToken,
            cachedProfile: cachedUser,
          );
          authUserIdByEmail[studentEmail] = studentAuthId;
        }

        final userRow = await _upsertUserProfile(
          authUserId: studentAuthId,
          email: studentEmail,
          name: member.name,
          role: 'student',
          existingProfile: cachedUser,
        );
        usersByEmail[studentEmail] = userRow;
        final userReferenceCandidate = _userReferenceFromRow(userRow);
        final userReference =
          userReferenceCandidate.isEmpty ? studentAuthId : userReferenceCandidate;
        final userId = _domainIdFromReference(
          userReference,
          fallback: asInt(userRow['id'] ?? userRow['_id']),
        );

        await _ensureUserGroupRelation(
          groupReference: groupReference,
          userReference: userReference,
          tableAvailable: hasUserGroupTable,
          relationKeys: userGroupRelationKeys,
        );
        await _ensureUserCourseRelation(
          courseReference: courseReference,
          userReference: userReference,
          role: 'student',
          tableAvailable: hasUserCourseTable,
          relationKeys: userCourseRelationKeys,
        );

        members.add(
          GroupMember(id: userId, name: member.name, username: studentEmail),
        );
      }

      groups.add(CourseGroup(id: grpId, name: group.name, members: members));
    }

    return GroupCategory(
      id: catId,
      name: categoryName,
      importedAt: DateTime.fromMillisecondsSinceEpoch(now),
      groups: groups,
      courseId: courseId,
    );
  }

  @override
  Future<void> delete(int categoryId) async {
    final catRows = await _db.robleRead(RobleTables.category);
    Map<String, dynamic>? target;
    String targetCategoryReference = '';
    for (final row in catRows) {
      final categoryReference = _categoryReferenceFromRow(row);
      final domainId = _domainIdFromReference(
        categoryReference,
        fallback: rowIdFromMap(row),
      );
      if (domainId == categoryId || rowIdFromMap(row) == categoryId) {
        target = row;
        targetCategoryReference = categoryReference;
        break;
      }
    }
    if (target == null) return;

    if (targetCategoryReference.isEmpty) {
      targetCategoryReference = categoryId.toString();
    }

    var grpRows = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': targetCategoryReference},
    );
    if (grpRows.isEmpty) {
      final legacyCategoryReference = categoryId.toString();
      if (legacyCategoryReference != targetCategoryReference) {
        grpRows = await _db.robleRead(
          RobleTables.groups,
          filters: {'category_id': legacyCategoryReference},
        );
      }
    }

    for (final grp in grpRows) {
      final groupReference = _groupReferenceFromRow(grp);
      final effectiveGroupReference = groupReference.isEmpty
          ? rowIdFromMap(grp).toString()
          : groupReference;
      final grpKey = grp['_id']?.toString();
      var memRows = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': effectiveGroupReference},
      );
      if (memRows.isEmpty) {
        final legacyGroupReference = rowIdFromMap(grp).toString();
        if (legacyGroupReference != effectiveGroupReference) {
          memRows = await _db.robleRead(
            RobleTables.userGroup,
            filters: {'group_id': legacyGroupReference},
          );
        }
      }
      for (final m in memRows) {
        final mk = m['_id']?.toString();
        if (mk != null && mk.isNotEmpty) {
          await _db.robleDelete(RobleTables.userGroup, mk);
        }
      }
      if (grpKey != null && grpKey.isNotEmpty) {
        await _db.robleDelete(RobleTables.groups, grpKey);
      }
    }

    final catKey = target['_id']?.toString();
    if (catKey != null && catKey.isNotEmpty) {
      await _db.robleDelete(RobleTables.category, catKey);
    }
  }
}
