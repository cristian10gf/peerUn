import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_course_repository.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final DatabaseService _db;
  CourseRepositoryImpl(this._db);

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? value.toString().hashCode.abs();
  }

  int _rowId(Map<String, dynamic> row) => _asInt(row['id'] ?? row['_id']);

  DateTime _asDate(dynamic value) {
    final millis = _asInt(value, fallback: DateTime.now().millisecondsSinceEpoch);
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<List<CourseModel>> getAll(int teacherId) async {
    final rows = await _db.robleRead('courses', filters: {'teacher_id': teacherId});
    final courses = rows
        .map(
          (r) => CourseModel(
            id: _rowId(r),
            teacherId: _asInt(r['teacher_id']),
            name: (r['name'] ?? '').toString(),
            code: (r['code'] ?? '').toString(),
            createdAt: _asDate(r['created_at']),
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await _db.robleCreate('courses', {
      'teacher_id': teacherId,
      'name': name,
      'code': code,
      'created_at': now,
    });

    return CourseModel(
      id: _rowId(row),
      teacherId: teacherId,
      name: (row['name'] ?? name).toString(),
      code: (row['code'] ?? code).toString(),
      createdAt: _asDate(row['created_at'] ?? now),
    );
  }

  @override
  Future<void> delete(int courseId) async {
    final rows = await _db.robleRead('courses');
    String? key;
    for (final row in rows) {
      if (_rowId(row) == courseId) {
        key = row['_id']?.toString();
        break;
      }
    }
    if (key == null || key.isEmpty) {
      throw Exception('No se encontro el curso a eliminar');
    }
    await _db.robleDelete('courses', key);
  }

  @override
  Future<List<GroupCategory>> getCategoriesForCourse(int courseId) async {
    final catRows = await _db.robleRead(
      'group_categories',
      filters: {'course_id': courseId},
    );

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final catId = _rowId(cat);
      final grpRows = await _db.robleRead('groups', filters: {'category_id': catId});

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId = _rowId(grp);
        final memRows = await _db.robleRead('group_members', filters: {'group_id': grpId});

        final members = memRows
            .map(
              (m) => GroupMember(
                id: _rowId(m),
                name: (m['name'] ?? '').toString(),
                username: (m['username'] ?? '').toString(),
              ),
            )
            .toList();

        groups.add(CourseGroup(
          id: grpId,
          name: (grp['name'] ?? '').toString(),
          members: members,
        ));
      }

      result.add(
        GroupCategory(
          id: catId,
          name: (cat['name'] ?? '').toString(),
          importedAt: _asDate(cat['imported_at']),
          groups: groups,
          courseId: _asInt(cat['course_id']),
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }
}
