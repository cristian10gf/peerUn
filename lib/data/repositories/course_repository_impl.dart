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

  String _asString(dynamic value) => value?.toString().trim() ?? '';

  String _firstNonEmptyField(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _asString(row[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
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

  String _userReferenceFromRow(Map<String, dynamic> row) {
    return _firstNonEmptyField(row, const ['user_id', 'id', '_id']);
  }

  int _domainIdFromReference(String reference, {required int fallback}) {
    if (reference.isEmpty) return fallback;
    return DatabaseService.stableNumericIdFromSeed(reference);
  }

  int _courseIdentityFromRow(Map<String, dynamic> row) {
    return asInt(row['course_id'] ?? row['id'] ?? row['_id']);
  }

  Set<int> _resolveEquivalentCourseIds(
    List<Map<String, dynamic>> rows,
    int courseId,
  ) {
    final ids = <int>{courseId};
    for (final row in rows) {
      final canonicalId = _courseIdentityFromRow(row);
      final legacyId = rowIdFromMap(row);
      if (canonicalId == courseId || legacyId == courseId) {
        ids
          ..add(canonicalId)
          ..add(legacyId);
      }
    }
    return ids;
  }

  Future<Set<String>> _resolveCurrentTeacherUserReferences() async {
    final claims = await _db.readAuthTokenClaims();
    final email = (claims['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) return const <String>{};
    Map<String, dynamic>? row;
    try {
      row = await _db.robleFindUserByEmail(email);
    } catch (_) {
      return const <String>{};
    }
    if (row == null) return const <String>{};

    return <String>{
      _asString(row['user_id']),
      _asString(row['id']),
      _asString(row['_id']),
    }..removeWhere((value) => value.isEmpty);
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
    final teacherUserReferences = await _resolveCurrentTeacherUserReferences();
    if (teacherUserReferences.isNotEmpty &&
        await tableExists(_db, RobleTables.userCourse)) {
      final userCourse = <Map<String, dynamic>>[];
      for (final teacherUserReference in teacherUserReferences) {
        final relations = await _db.robleRead(
          RobleTables.userCourse,
          filters: {'user_id': teacherUserReference, 'role': 'teacher'},
        );
        userCourse.addAll(relations);
      }
      final allowedIds = userCourse.map((r) => asInt(r['course_id'])).toSet();

      for (final row in rows) {
        final canonicalId = _courseIdentityFromRow(row);
        final legacyId = rowIdFromMap(row);
        if (allowedIds.contains(canonicalId) || allowedIds.contains(legacyId)) {
          filtered.add(row);
        }
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
            id: _courseIdentityFromRow(r),
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
        final userReference = _userReferenceFromRow(teacherUserRow);
        final courseReference = _courseReferenceFromRow(row);

        final existing = await _db.robleRead(
          RobleTables.userCourse,
          filters: {'course_id': courseReference, 'user_id': userReference},
        );

        if (existing.isEmpty) {
          await _db.robleCreate(RobleTables.userCourse, {
            'course_id': courseReference,
            'user_id': userReference,
            'role': 'teacher',
          });
        }
      }
    }

    return CourseModel(
      id: _courseIdentityFromRow(row),
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
      final canonicalId = _courseIdentityFromRow(row);
      final legacyId = rowIdFromMap(row);
      if (canonicalId == courseId || legacyId == courseId) {
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
    var catRows = await _db.robleRead(
      RobleTables.category,
      filters: {'course_id': courseId},
    );

    if (catRows.isEmpty) {
      final allCourses = await _db.robleRead(RobleTables.course);
      final equivalentIds = _resolveEquivalentCourseIds(allCourses, courseId);

      final allCategories = await _db.robleRead(RobleTables.category);
      catRows = allCategories
          .where((categoryRow) {
            final relationId = asInt(categoryRow['course_id']);
            return equivalentIds.contains(relationId);
          })
          .toList(growable: false);
    }

    final allUsers = await _db.robleRead(RobleTables.users);
    final usersByReference = <String, Map<String, dynamic>>{};
    for (final u in allUsers) {
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

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final categoryReference = _categoryReferenceFromRow(cat);
      final catId = _domainIdFromReference(
        categoryReference,
        fallback: rowIdFromMap(cat),
      );
      var grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': categoryReference},
      );
      if (grpRows.isEmpty) {
        final legacyCategoryRef = catId.toString();
        if (legacyCategoryRef != categoryReference) {
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
        var membershipRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': groupReference},
        );
        if (membershipRows.isEmpty) {
          final legacyGroupRef = grpId.toString();
          if (legacyGroupRef != groupReference) {
            membershipRows = await _db.robleRead(
              RobleTables.userGroup,
              filters: {'group_id': legacyGroupRef},
            );
          }
        }

        final members = <GroupMember>[];
        for (final membership in membershipRows) {
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
          courseId: asInt(cat['course_id']),
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }
}
