import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/email_utils.dart';
import 'package:example/data/utils/repository_db_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/services/csv_import_domain_service.dart';

/// Maximum number of concurrent signup-direct calls during CSV import.
const _kSignupConcurrency = 5;

class GroupRepositoryImpl implements IGroupRepository {
  final DatabaseService _db;
  final CsvImportDomainService _csvImportDomainService;

  GroupRepositoryImpl(
    this._db, {
    CsvImportDomainService? csvImportDomainService,
  }) : _csvImportDomainService =
           csvImportDomainService ?? const CsvImportDomainService();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool _looksLikeAlreadyRegistered(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('409') ||
        msg.contains('registrado') ||
        msg.contains('already') ||
        msg.contains('duplicate');
  }

  String _asString(dynamic value) => value?.toString().trim() ?? '';

  String _firstNonEmpty(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final v = _asString(row[key]);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _courseRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['course_id', 'id', '_id']);

  String _categoryRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['category_id', 'id', '_id']);

  String _groupRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['group_id', 'id', '_id']);

  int _domainId(String reference, {required int fallback}) {
    if (reference.isEmpty) return fallback;
    return DatabaseService.stableNumericIdFromSeed(reference);
  }

  /// Extracts the auth user-id (sub) from a [signupResponse].
  ///
  /// Roble's signup-direct does not always return the UID in the body, but it
  /// always issues a JWT whose `sub` claim IS the UID. We try three sources
  /// in order of reliability:
  ///   1. `accessToken` JWT `sub` claim
  ///   2. Top-level `user_id` / `uid` / `sub` fields
  ///   3. Nested `user.id` object
  String _extractAuthUserId(Map<String, dynamic> payload) {
    // 1. Decode JWT sub if accessToken is present (most reliable).
    final accessToken = _asString(
      payload['accessToken'] ?? payload['access_token'],
    );
    if (accessToken.isNotEmpty) {
      final claims = _db.decodeJwtClaims(accessToken);
      final sub = _asString(claims['sub']);
      if (sub.isNotEmpty) return sub;
    }

    // 2. Top-level fields.
    for (final key in const [
      'user_id',
      'userId',
      'uid',
      'sub',
      '_id',
      'id',
    ]) {
      final v = _asString(payload[key]);
      if (v.isNotEmpty) return v;
    }

    // 3. Nested user object.
    final user = payload['user'];
    if (user is Map) {
      for (final key in const ['user_id', 'userId', 'uid', 'sub', '_id', 'id']) {
        final v = _asString(user[key]);
        if (v.isNotEmpty) return v;
      }
    }

    return '';
  }

  /// Runs [tasks] with at most [maxConcurrent] running simultaneously.
  Future<List<T>> _runConcurrent<T>(
    List<Future<T> Function()> tasks, {
    int maxConcurrent = _kSignupConcurrency,
  }) async {
    final results = <T>[];
    for (var i = 0; i < tasks.length; i += maxConcurrent) {
      final chunk = tasks.skip(i).take(maxConcurrent).toList();
      final chunkResults = await Future.wait(chunk.map((t) => t()));
      results.addAll(chunkResults);
    }
    return results;
  }

  // ─── Public interface ────────────────────────────────────────────────────

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async {
    final catRows = await _db.robleRead(RobleTables.category);
    final courseRows = await _db.robleRead(RobleTables.course);
    final usersRows = await _db.robleRead(RobleTables.users);

    final usersByRef = <String, Map<String, dynamic>>{};
    for (final u in usersRows) {
      for (final key in const ['user_id', 'id', '_id']) {
        final v = _asString(u[key]);
        if (v.isNotEmpty) usersByRef.putIfAbsent(v, () => u);
      }
    }

    final teacherCourseIds = <int>{};
    if (await tableExists(_db, RobleTables.userCourse)) {
      final claims = await _db.readAuthTokenClaims();
      final email = (claims['email'] ?? '').toString().trim().toLowerCase();
      if (email.isNotEmpty) {
        final teacherUser = await _db.robleFindUserByEmail(email);
        final candidates = <String>{
          _asString(teacherUser?['user_id']),
          _asString(teacherUser?['id']),
          _asString(teacherUser?['_id']),
        }..removeWhere((v) => v.isEmpty);

        for (final candidate in candidates) {
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

    if (teacherCourseIds.isEmpty) {
      for (final c in courseRows) {
        final createdBy = asInt(c['created_by'] ?? c['teacher_id']);
        if (createdBy != teacherId) continue;
        final ref = _courseRef(c);
        teacherCourseIds.add(
          _domainId(ref, fallback: rowIdFromMap(c)),
        );
      }
    }

    if (teacherCourseIds.isEmpty) return const <GroupCategory>[];

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final courseId = asInt(cat['course_id']);
      if (!teacherCourseIds.contains(courseId)) continue;

      final catReference = _categoryRef(cat);
      final catId = _domainId(catReference, fallback: rowIdFromMap(cat));

      var grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': catReference},
      );
      if (grpRows.isEmpty) {
        grpRows = await _db.robleRead(
          RobleTables.groups,
          filters: {'category_id': catId.toString()},
        );
      }

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final groupReference = _groupRef(grp);
        final grpId = _domainId(groupReference, fallback: rowIdFromMap(grp));

        var memberRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': groupReference},
        );
        if (memberRows.isEmpty) {
          memberRows = await _db.robleRead(
            RobleTables.userGroup,
            filters: {'group_id': grpId.toString()},
          );
        }

        final members = <GroupMember>[];
        for (final membership in memberRows) {
          final userReference = _asString(membership['user_id']);
          if (userReference.isEmpty) continue;
          final user = usersByRef[userReference];
          if (user == null) continue;
          final userId = _domainId(
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

  // ─── importCsv ────────────────────────────────────────────────────────────
  //
  // OPTIMISED STRATEGY (from ~165 sequential calls → ~15-20 total):
  //
  //  Pre-load  : 1 read(users) + 1 read(user_group) + 1 read(user_course)
  //              + 1 read(course) = 4 reads
  //  Phase 1   : N parallel signup-direct (only NEW students, concurrency 5)
  //  Phase 2   : 1 bulk insert → user table
  //  Phase 3   : 1 create → category
  //  Phase 4   : G creates → groups (G = number of groups, typically ≤15)
  //  Phase 5   : 1 bulk insert → user_group relations
  //  Phase 6   : 1 bulk insert → user_course relations
  //
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  ) async {
    // ── Guard: need a valid teacher token to make auth calls ────────────────
    final teacherTokens = await _db.readAuthTokens();
    final teacherAccessToken = teacherTokens?['access_token']?.toString() ?? '';
    final teacherRefreshToken =
        teacherTokens?['refresh_token']?.toString() ?? '';
    if (teacherAccessToken.isEmpty || teacherRefreshToken.isEmpty) {
      throw Exception('Sesión de profesor no válida para aprovisionar datos');
    }

    // ── Parse CSV ────────────────────────────────────────────────────────────
    final parsed = _csvImportDomainService.parse(csvContent);

    // ── PRE-LOAD: fetch tables we need in one pass ───────────────────────────
    final allUsers = await _db.robleRead(RobleTables.users);
    final allCourses = await _db.robleRead(RobleTables.course);

    final hasUserCourseTable = await tableExists(_db, RobleTables.userCourse);
    final hasUserGroupTable = await tableExists(_db, RobleTables.userGroup);

    // Read existing relations once (warm-up cache).
    final existingUserCourseKeys = <String>{};
    final existingUserGroupKeys = <String>{};
    if (hasUserCourseTable) {
      final rows = await _db.robleRead(RobleTables.userCourse);
      for (final r in rows) {
        final cid = _asString(r['course_id']);
        final uid = _asString(r['user_id']);
        if (cid.isNotEmpty && uid.isNotEmpty) {
          existingUserCourseKeys.add('$cid::$uid');
        }
      }
    }
    if (hasUserGroupTable) {
      final rows = await _db.robleRead(RobleTables.userGroup);
      for (final r in rows) {
        final gid = _asString(r['group_id']);
        final uid = _asString(r['user_id']);
        if (gid.isNotEmpty && uid.isNotEmpty) {
          existingUserGroupKeys.add('$gid::$uid');
        }
      }
    }

    // Build per-email lookups from the pre-loaded users.
    final usersByEmail = <String, Map<String, dynamic>>{};
    final authIdByEmail = <String, String>{};
    for (final row in allUsers) {
      final email = normalizeEmail((row['email'] ?? '').toString());
      if (email.isEmpty) continue;
      usersByEmail[email] = row;
      final authId = _asString(row['user_id']);
      if (authId.isNotEmpty) authIdByEmail[email] = authId;
    }

    // Resolve the course's canonical reference (used for user_course FK).
    final courseReference = _resolveCourseRef(allCourses, courseId);

    // ── Collect unique emails from CSV ───────────────────────────────────────
    final uniqueEmails = <String>{};
    for (final group in parsed.groups) {
      for (final member in group.members) {
        uniqueEmails.add(normalizeEmail(member.username));
      }
    }
    final newEmails =
        uniqueEmails.where((e) => !authIdByEmail.containsKey(e)).toList();

    // ── PHASE 1: Parallel signup-direct for new students ─────────────────────
    if (newEmails.isNotEmpty) {
      final signupTasks = newEmails.map((email) => () async {
        // Find name from CSV (use first occurrence).
        String name = email.split('@').first;
        outer:
        for (final group in parsed.groups) {
          for (final member in group.members) {
            if (normalizeEmail(member.username) == email) {
              name = member.name;
              break outer;
            }
          }
        }

        try {
          final signupResponse = await _db.robleSignupDirect(
            email: email,
            password: _db.studentDefaultPassword,
            name: name,
          );
          final authId = _extractAuthUserId(signupResponse);
          if (authId.isNotEmpty) authIdByEmail[email] = authId;
        } catch (e) {
          if (!_looksLikeAlreadyRegistered(e)) rethrow;
          // Already registered — authId may already be in the map or will be
          // resolved from the users table pre-load above.
        }

        // Restore teacher token context after each signup attempt.
        _db.setSessionTokens(
          accessToken: teacherAccessToken,
          refreshToken: teacherRefreshToken,
        );
      }).toList();

      await _runConcurrent(signupTasks);

      // Ensure teacher token is active for subsequent DB writes.
      _db.setSessionTokens(
        accessToken: teacherAccessToken,
        refreshToken: teacherRefreshToken,
      );
    }

    // ── PHASE 2: Bulk upsert users table ─────────────────────────────────────
    final userRecordsToInsert = <Map<String, dynamic>>[];
    for (final email in uniqueEmails) {
      if (usersByEmail.containsKey(email)) continue; // Already in DB.

      String name = email.split('@').first;
      outer:
      for (final group in parsed.groups) {
        for (final member in group.members) {
          if (normalizeEmail(member.username) == email) {
            name = member.name;
            break outer;
          }
        }
      }

      userRecordsToInsert.add({
        'user_id': authIdByEmail[email] ?? email,
        'email': email,
        'name': name,
        'role': 'student',
      });
    }

    if (userRecordsToInsert.isNotEmpty) {
      try {
        final inserted = await _db.robleBulkInsert(
          RobleTables.users,
          userRecordsToInsert,
        );
        for (final row in inserted) {
          final email = normalizeEmail(_asString(row['email']));
          if (email.isNotEmpty) {
            usersByEmail[email] = row;
            final authId = _asString(row['user_id']);
            if (authId.isNotEmpty) authIdByEmail.putIfAbsent(email, () => authId);
          }
        }
      } catch (_) {
        // Fallback to individual creates if bulk fails.
        for (final record in userRecordsToInsert) {
          try {
            final row = await _db.robleCreate(RobleTables.users, record);
            final email = normalizeEmail(_asString(row['email']));
            if (email.isNotEmpty) {
              usersByEmail[email] = row;
              final authId = _asString(row['user_id']);
              if (authId.isNotEmpty) {
                authIdByEmail.putIfAbsent(email, () => authId);
              }
            }
          } catch (_) {}
        }
      }
    }

    // ── PHASE 3: Create category ─────────────────────────────────────────────
    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseReference,
    });
    final categoryReference = _categoryRef(catRow);
    final catId = _domainId(categoryReference, fallback: rowIdFromMap(catRow));

    // ── PHASE 4: Create groups + collect relation records ────────────────────
    final groups = <CourseGroup>[];
    final userGroupRecords = <Map<String, dynamic>>[];
    final userCourseRecords = <Map<String, dynamic>>[];

    for (final group in parsed.groups) {
      final grpRow = await _db.robleCreate(RobleTables.groups, {
        'category_id': categoryReference,
        'name': group.name,
      });
      final groupReference = _groupRef(grpRow);
      final grpId = _domainId(groupReference, fallback: rowIdFromMap(grpRow));

      final members = <GroupMember>[];
      for (final member in group.members) {
        final studentEmail = normalizeEmail(member.username);
        final userRow = usersByEmail[studentEmail];
        final userReference = _asString(userRow?['user_id']).isNotEmpty
            ? _asString(userRow!['user_id'])
            : (authIdByEmail[studentEmail] ?? studentEmail);
        final userId = _domainId(
          userReference,
          fallback: asInt(userRow?['id'] ?? userRow?['_id']),
        );

        if (hasUserGroupTable) {
          final ugKey = '$groupReference::$userReference';
          if (!existingUserGroupKeys.contains(ugKey)) {
            userGroupRecords.add({
              'group_id': groupReference,
              'user_id': userReference,
            });
            existingUserGroupKeys.add(ugKey);
          }
        }

        if (hasUserCourseTable) {
          final ucKey = '$courseReference::$userReference';
          if (!existingUserCourseKeys.contains(ucKey)) {
            userCourseRecords.add({
              'course_id': courseReference,
              'user_id': userReference,
              'role': 'student',
            });
            existingUserCourseKeys.add(ucKey);
          }
        }

        members.add(
          GroupMember(id: userId, name: member.name, username: studentEmail),
        );
      }

      groups.add(CourseGroup(id: grpId, name: group.name, members: members));
    }

    // ── PHASE 5: Bulk insert user_group ──────────────────────────────────────
    if (userGroupRecords.isNotEmpty) {
      try {
        await _db.robleBulkInsert(RobleTables.userGroup, userGroupRecords);
      } catch (_) {
        for (final record in userGroupRecords) {
          try {
            await _db.robleCreate(RobleTables.userGroup, record);
          } catch (_) {}
        }
      }
    }

    // ── PHASE 6: Bulk insert user_course ─────────────────────────────────────
    if (userCourseRecords.isNotEmpty) {
      try {
        await _db.robleBulkInsert(RobleTables.userCourse, userCourseRecords);
      } catch (_) {
        for (final record in userCourseRecords) {
          try {
            await _db.robleCreate(RobleTables.userCourse, record);
          } catch (_) {}
        }
      }
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
    String targetCatRef = '';
    for (final row in catRows) {
      final ref = _categoryRef(row);
      final domainId = _domainId(ref, fallback: rowIdFromMap(row));
      if (domainId == categoryId || rowIdFromMap(row) == categoryId) {
        target = row;
        targetCatRef = ref;
        break;
      }
    }
    if (target == null) return;
    if (targetCatRef.isEmpty) targetCatRef = categoryId.toString();

    var grpRows = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': targetCatRef},
    );
    if (grpRows.isEmpty) {
      grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': categoryId.toString()},
      );
    }

    for (final grp in grpRows) {
      final groupRef = _groupRef(grp);
      final effectiveRef =
          groupRef.isNotEmpty ? groupRef : rowIdFromMap(grp).toString();
      final grpKey = grp['_id']?.toString();

      var memRows = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': effectiveRef},
      );
      if (memRows.isEmpty) {
        memRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': rowIdFromMap(grp).toString()},
        );
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

  // ─── Private: course ref resolution ─────────────────────────────────────

  String _resolveCourseRef(
    List<Map<String, dynamic>> courseRows,
    int courseId,
  ) {
    for (final row in courseRows) {
      final ref = _courseRef(row);
      if (ref.isEmpty) continue;
      final candidateIds = <int>{
        asInt(row['course_id'], fallback: -1),
        asInt(row['id'], fallback: -1),
        asInt(row['_id'], fallback: -1),
      };
      if (candidateIds.contains(courseId)) return ref;
    }
    return courseId.toString();
  }
}
