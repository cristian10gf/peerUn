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

  // ── Reference extractors (always return the raw varchar ID string) ──────────

  String _courseReferenceFromRow(Map<String, dynamic> row) =>
      _firstNonEmptyField(row, const ['course_id', 'id', '_id']);

  String _categoryReferenceFromRow(Map<String, dynamic> row) =>
      _firstNonEmptyField(row, const ['category_id', 'id', '_id']);

  String _groupReferenceFromRow(Map<String, dynamic> row) =>
      _firstNonEmptyField(row, const ['group_id', 'id', '_id']);

  String _userReferenceFromRow(Map<String, dynamic> row) =>
      _firstNonEmptyField(row, const ['user_id', 'id', '_id']);

  // ── Domain-ID conversion (varchar ref → stable int for domain models) ───────
  //
  // All IDs in Roble are varchar (UUID). Never use asInt() on them — it returns
  // 0 for non-numeric strings.  stableNumericIdFromSeed produces a consistent
  // non-zero int from any string, making domain model IDs unique and stable.

  int _domainId(String reference, {int fallback = 0}) {
    if (reference.isEmpty) return fallback;
    return DatabaseService.stableNumericIdFromSeed(reference);
  }

  // ── Reverse lookup: find the varchar course ref for a given domain int ───────

  String _courseRefForDomainId(
    List<Map<String, dynamic>> courseRows,
    int courseId,
  ) {
    for (final row in courseRows) {
      final ref = _courseReferenceFromRow(row);
      if (ref.isNotEmpty && _domainId(ref) == courseId) return ref;
    }
    return '';
  }

  // ── Teacher user helpers ─────────────────────────────────────────────────────

  Future<Set<String>> _resolveCurrentTeacherUserReferences() async {
    final claims = await _db.readAuthTokenClaims();
    final email = (claims['email'] ?? '').toString().trim().toLowerCase();
    final authUserId = (claims['sub'] ?? '').toString().trim();
    if (email.isEmpty && authUserId.isEmpty) return const <String>{};

    List<Map<String, dynamic>> allUsers;
    try {
      allUsers = await _db.robleRead(RobleTables.users);
    } catch (_) {
      return const <String>{};
    }

    final refs = <String>{};
    for (final row in allUsers) {
      final rowEmail = _asString(row['email']).toLowerCase();
      final rowUserId = _asString(row['user_id']);
      final matchesEmail = email.isNotEmpty && rowEmail == email;
      final matchesAuthId = authUserId.isNotEmpty && rowUserId == authUserId;
      if (matchesEmail || matchesAuthId) {
        refs
          ..add(_asString(row['user_id']))
          ..add(_asString(row['id']))
          ..add(_asString(row['_id']));
      }
    }
    return refs..removeWhere((v) => v.isEmpty);
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

    // READ-FIRST: scan all users to find an existing row by authUserId or email.
    // Roble does not enforce unique email, so robleCreate would silently create a
    // duplicate row. We only create when no matching row exists at all.
    List<Map<String, dynamic>> allUsers;
    try {
      allUsers = await _db.robleRead(RobleTables.users);
    } catch (_) {
      allUsers = const [];
    }

    Map<String, dynamic>? existing;
    for (final row in allUsers) {
      if (_asString(row['user_id']) == authUserId) {
        existing = row;
        break;
      }
    }
    if (existing == null) {
      for (final row in allUsers) {
        if (_asString(row['email']).toLowerCase() == email) {
          existing = row;
          break;
        }
      }
    }

    if (existing != null) {
      final key = _asString(existing['_id']);
      if (key.isNotEmpty) {
        try {
          await _db.robleUpdate(RobleTables.users, key, payload);
        } catch (_) {
          // best-effort update; return merged row regardless
        }
      }
      return {...existing, ...payload};
    }

    try {
      return await _db.robleCreate(RobleTables.users, payload);
    } catch (_) {
      return null;
    }
  }

  // ── Repository methods ───────────────────────────────────────────────────────

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
      // All course_ids in user_course are varchar — compare as strings only.
      final allowedRefs = userCourse
          .map((r) => _asString(r['course_id']))
          .where((s) => s.isNotEmpty)
          .toSet();

      for (final row in rows) {
        final ref = _courseReferenceFromRow(row);
        if (allowedRefs.contains(ref)) filtered.add(row);
      }
    } else {
      // Legacy fallback: match by teacher_id / created_by.
      // These fields are also varchar in Roble, so compare as strings.
      final claims = await _db.readAuthTokenClaims();
      final authUserId = (claims['sub'] ?? '').toString().trim();
      for (final row in rows) {
        final legacyTeacher = _asString(row['teacher_id']);
        final createdBy = _asString(row['created_by']);
        if ((authUserId.isNotEmpty &&
                (legacyTeacher == authUserId || createdBy == authUserId)) ||
            teacherId == 0) {
          filtered.add(row);
        }
      }
    }

    final courses = filtered.map((r) {
      final ref = _courseReferenceFromRow(r);
      return CourseModel(
        id: _domainId(ref),
        teacherId: _domainId(_asString(r['created_by'] ?? r['teacher_id'])),
        name: (r['name'] ?? '').toString(),
        code: (r['code'] ?? r['description'] ?? '').toString(),
        createdAt: asDate(r['created_at']),
      );
    }).toList();

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
    // Read JWT claims first so we always have the canonical authUserId (JWT sub)
    // available for user_course — independent of which row _upsert finds.
    final claims = await _db.readAuthTokenClaims();
    final authUserId = (claims['sub'] ?? '').toString().trim();

    await _upsertCurrentTeacherUser();

    final row = await _db.robleCreate(RobleTables.course, {
      'name': name,
      'description': code,
      // Store the varchar auth ID directly; this is the canonical teacher ref.
      if (authUserId.isNotEmpty) 'created_by': authUserId,
    });

    final courseReference = _courseReferenceFromRow(row);

    if (courseReference.isNotEmpty &&
        await tableExists(_db, RobleTables.userCourse)) {
      final userReference = authUserId.isNotEmpty
          ? authUserId
          : _userReferenceFromRow(
              await _upsertCurrentTeacherUser() ?? const {},
            );

      if (userReference.isNotEmpty) {
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
      id: _domainId(courseReference),
      teacherId: _domainId(authUserId, fallback: teacherId),
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
      final ref = _courseReferenceFromRow(row);
      if (_domainId(ref) == courseId) {
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
    // Reverse-lookup: find the varchar course reference for this domain int.
    final allCourses = await _db.robleRead(RobleTables.course);
    final courseRef = _courseRefForDomainId(allCourses, courseId);

    List<Map<String, dynamic>> catRows = const [];

    if (courseRef.isNotEmpty) {
      // Filter by varchar course reference — correct for UUID-based schemas.
      catRows = await _db.robleRead(
        RobleTables.category,
        filters: {'course_id': courseRef},
      );
    }

    if (catRows.isEmpty) {
      // Fallback: scan all categories and match by string course reference.
      final allCategories = await _db.robleRead(RobleTables.category);
      catRows = allCategories.where((row) {
        final catCourseRef = _asString(row['course_id']);
        return courseRef.isNotEmpty && catCourseRef == courseRef;
      }).toList(growable: false);
    }

    final allUsers = await _db.robleRead(RobleTables.users);
    final usersByReference = <String, Map<String, dynamic>>{};
    for (final u in allUsers) {
      for (final ref in [
        _asString(u['user_id']),
        _asString(u['id']),
        _asString(u['_id']),
      ]) {
        if (ref.isNotEmpty) usersByReference.putIfAbsent(ref, () => u);
      }
    }

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final categoryReference = _categoryReferenceFromRow(cat);
      final catId = _domainId(categoryReference);

      var grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': categoryReference},
      );

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final groupReference = _groupReferenceFromRow(grp);
        final grpId = _domainId(groupReference);

        var membershipRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': groupReference},
        );

        final members = <GroupMember>[];
        for (final membership in membershipRows) {
          final userReference = _asString(membership['user_id']);
          if (userReference.isEmpty) continue;

          final user = usersByReference[userReference];
          if (user == null) continue;

          final userRef = _userReferenceFromRow(user);
          members.add(
            GroupMember(
              id: _domainId(userRef),
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
          courseId: _domainId(_asString(cat['course_id'])),
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }
}
