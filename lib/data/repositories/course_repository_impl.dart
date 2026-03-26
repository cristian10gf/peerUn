import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/repository_db_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_course_repository.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final DatabaseService _db;
  CourseRepositoryImpl(this._db);

  Future<int?> _resolveCurrentTeacherUserId() async {
    final claims = await _db.readAuthTokenClaims();
    final email = (claims['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) return null;
    Map<String, dynamic>? row;
    try {
      row = await _db.robleFindUserByEmail(email);
    } catch (_) {
      return null;
    }
    if (row == null) return null;
    return asInt(row['id'] ?? row['_id']);
  }

  Future<Map<String, dynamic>?> _upsertCurrentTeacherUser() async {
    final claims = await _db.readAuthTokenClaims();
    final authUserId = claims['sub']?.toString() ?? '';
    final email = (claims['email'] ?? '').toString().trim().toLowerCase();
    final name = (claims['name'] ?? '').toString().trim();

    if (authUserId.isEmpty || email.isEmpty) return null;

    final payload = {
      'user_id': authUserId,
      'email': email,
      'name': name.isEmpty ? email.split('@').first : name,
      'role': 'teacher',
    };

    try {
      return await _db.robleCreate(RobleTables.users, payload);
    } catch (_) {
      Map<String, dynamic>? existing;
      try {
        existing = await _db.robleFindUserByEmail(email);
      } catch (_) {
        return null;
      }
      if (existing == null) return null;

      final key = existing['_id']?.toString() ?? '';
      if (key.isEmpty) return existing;

      try {
        await _db.robleUpdate(RobleTables.users, key, payload);
        return await _db.robleFindUserByEmail(email) ?? existing;
      } catch (_) {
        return existing;
      }
    }
  }

  @override
  Future<List<CourseModel>> getAll(int teacherId) async {
    final rows = await _db.robleRead(RobleTables.course);

    final filtered = <Map<String, dynamic>>[];
    final teacherUserId = await _resolveCurrentTeacherUserId();
    if (teacherUserId != null &&
        await tableExists(_db, RobleTables.userCourse)) {
      final userCourse = await _db.robleRead(
        RobleTables.userCourse,
        filters: {'user_id': teacherUserId, 'role': 'teacher'},
      );
      final allowedIds = userCourse.map((r) => asInt(r['course_id'])).toSet();

      for (final row in rows) {
        if (allowedIds.contains(rowIdFromMap(row))) filtered.add(row);
      }
    } else {
      for (final row in rows) {
        final teacherFromLegacy = asInt(row['teacher_id'], fallback: -1);
        final teacherFromSchema = asInt(row['created_by'], fallback: -1);
        if (teacherFromLegacy == teacherId || teacherFromSchema == teacherId) {
          filtered.add(row);
        }
      }
    }

    final courses = filtered
        .map(
          (r) => CourseModel(
            id: rowIdFromMap(r),
            teacherId: asInt(r['created_by'] ?? r['teacher_id']),
            name: (r['name'] ?? '').toString(),
            code: (r['code'] ?? r['description'] ?? '').toString(),
            createdAt: asDate(r['created_at']),
          ),
        )
        .toList();

    courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return courses;
  }

  @override
  Future<CourseModel> create({
    required String name,
    required String code,
    required int teacherId,
  }) async {
    final now = DateTime.now();
    final teacherUserRow = await _upsertCurrentTeacherUser();
    final createdBy = asInt(
      teacherUserRow?['id'] ?? teacherUserRow?['_id'],
      fallback: teacherId,
    );

    final row = await _db.robleCreate(RobleTables.course, {
      'name': name,
      'description': code,
      'created_by': createdBy,
    });

    if (await tableExists(_db, RobleTables.userCourse)) {
      if (teacherUserRow != null) {
        final userId = asInt(teacherUserRow['id'] ?? teacherUserRow['_id']);
        final courseId = rowIdFromMap(row);

        final existing = await _db.robleRead(
          RobleTables.userCourse,
          filters: {'course_id': courseId, 'user_id': userId},
        );

        if (existing.isEmpty) {
          await _db.robleCreate(RobleTables.userCourse, {
            'course_id': courseId,
            'user_id': userId,
            'role': 'teacher',
          });
        }
      }
    }

    return CourseModel(
      id: rowIdFromMap(row),
      teacherId: asInt(row['created_by'] ?? createdBy),
      name: (row['name'] ?? name).toString(),
      code: (row['code'] ?? row['description'] ?? code).toString(),
      createdAt: asDate(row['created_at'] ?? now.toIso8601String()),
    );
  }

  @override
  Future<void> delete(int courseId) async {
    final rows = await _db.robleRead(RobleTables.course);
    String? key;
    for (final row in rows) {
      if (rowIdFromMap(row) == courseId) {
        key = row['_id']?.toString();
        break;
      }
    }
    if (key == null || key.isEmpty) {
      throw Exception('No se encontro el curso a eliminar');
    }
    await _db.robleDelete(RobleTables.course, key);
  }

  @override
  Future<List<GroupCategory>> getCategoriesForCourse(int courseId) async {
    final catRows = await _db.robleRead(
      RobleTables.category,
      filters: {'course_id': courseId},
    );

    final allUsers = await _db.robleRead(RobleTables.users);
    final usersById = <int, Map<String, dynamic>>{};
    for (final u in allUsers) {
      usersById[asInt(u['id'] ?? u['_id'])] = u;
    }

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final catId = rowIdFromMap(cat);
      final grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': catId},
      );

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId = rowIdFromMap(grp);
        final membershipRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': grpId},
        );

        final members = <GroupMember>[];
        for (final membership in membershipRows) {
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
          courseId: asInt(cat['course_id']),
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }
}
