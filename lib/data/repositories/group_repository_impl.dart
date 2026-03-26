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

  Future<Map<String, dynamic>> _upsertUserProfile({
    required String authUserId,
    required String email,
    required String name,
    required String role,
  }) async {
    final payload = {
      'user_id': authUserId,
      'email': email,
      'name': name,
      'role': role,
    };

    try {
      return await _db.robleCreate(RobleTables.users, payload);
    } catch (_) {
      final existing = await _db.robleFindUserByEmail(email);
      if (existing == null) rethrow;

      final key = existing['_id']?.toString() ?? '';
      if (key.isEmpty) rethrow;

      await _db.robleUpdate(RobleTables.users, key, payload);
      final refreshed = await _db.robleFindUserByEmail(email);
      return refreshed ?? existing;
    }
  }

  Future<void> _ensureUserCourseRelation({
    required int courseId,
    required int userId,
    required String role,
  }) async {
    if (!await tableExists(_db, RobleTables.userCourse)) return;

    final existing = await _db.robleRead(
      RobleTables.userCourse,
      filters: {'course_id': courseId, 'user_id': userId},
    );
    if (existing.isNotEmpty) return;

    await _db.robleCreate(RobleTables.userCourse, {
      'course_id': courseId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> _ensureUserGroupRelation({
    required int groupId,
    required int userId,
  }) async {
    if (!await tableExists(_db, RobleTables.userGroup)) return;

    final existing = await _db.robleRead(
      RobleTables.userGroup,
      filters: {'group_id': groupId, 'user_id': userId},
    );
    if (existing.isNotEmpty) return;

    await _db.robleCreate(RobleTables.userGroup, {
      'group_id': groupId,
      'user_id': userId,
    });
  }

  Future<String> _resolveStudentAuthId({
    required String email,
    required String name,
    required String sharedPassword,
    required String teacherAccessToken,
    required String teacherRefreshToken,
  }) async {
    try {
      await _db.robleSignupDirect(
        email: email,
        password: sharedPassword,
        name: name,
      );
    } catch (e) {
      if (!_looksLikeAlreadyRegistered(e)) rethrow;
    }

    final login = await _db.robleLogin(email: email, password: sharedPassword);
    final accessToken = (login['accessToken'] ?? '').toString();
    if (accessToken.isEmpty) {
      throw Exception('No se pudo autenticar estudiante: $email');
    }

    final claims = _db.decodeJwtClaims(accessToken);
    final authUserId = claims['sub']?.toString() ?? '';
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

    final usersById = <int, Map<String, dynamic>>{};
    for (final u in usersRows) {
      usersById[asInt(u['id'] ?? u['_id'])] = u;
    }

    final teacherCourseIds = <int>{};
    if (await tableExists(_db, RobleTables.userCourse)) {
      final claims = await _db.readAuthTokenClaims();
      final email = (claims['email'] ?? '').toString().trim().toLowerCase();
      if (email.isNotEmpty) {
        final teacherUser = await _db.robleFindUserByEmail(email);
        final teacherUserId = asInt(teacherUser?['id'] ?? teacherUser?['_id']);
        if (teacherUserId > 0) {
          final relations = await _db.robleRead(
            RobleTables.userCourse,
            filters: {'user_id': teacherUserId, 'role': 'teacher'},
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
        if (createdBy == teacherId) teacherCourseIds.add(rowIdFromMap(c));
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

      final catId = rowIdFromMap(cat);
      final grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': catId},
      );

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId = rowIdFromMap(grp);
        final memberRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': grpId},
        );

        final members = <GroupMember>[];
        for (final membership in memberRows) {
          final userId = asInt(membership['user_id']);
          final user = usersById[userId];
          if (user == null) continue;

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

    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseId,
    });

    final catId = rowIdFromMap(catRow);
    final groups = <CourseGroup>[];

    for (final group in parsed.groups) {
      final grpRow = await _db.robleCreate(RobleTables.groups, {
        'category_id': catId,
        'name': group.name,
      });

      final grpId = rowIdFromMap(grpRow);
      final members = <GroupMember>[];
      for (final member in group.members) {
        final studentEmail = normalizeEmail(member.username);
        final studentAuthId = await _resolveStudentAuthId(
          email: studentEmail,
          name: member.name,
          sharedPassword: _db.studentDefaultPassword,
          teacherAccessToken: teacherAccessToken,
          teacherRefreshToken: teacherRefreshToken,
        );

        final userRow = await _upsertUserProfile(
          authUserId: studentAuthId,
          email: studentEmail,
          name: member.name,
          role: 'student',
        );
        final userId = asInt(userRow['id'] ?? userRow['_id']);

        await _ensureUserGroupRelation(groupId: grpId, userId: userId);
        await _ensureUserCourseRelation(
          courseId: courseId,
          userId: userId,
          role: 'student',
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
    for (final row in catRows) {
      if (rowIdFromMap(row) == categoryId) {
        target = row;
        break;
      }
    }
    if (target == null) return;

    final grpRows = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );
    for (final grp in grpRows) {
      final grpId = rowIdFromMap(grp);
      final grpKey = grp['_id']?.toString();
      final memRows = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': grpId},
      );
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
