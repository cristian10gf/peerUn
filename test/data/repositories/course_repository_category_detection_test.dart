import 'package:example/data/repositories/course_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCourseDatabaseService extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;

  _FakeCourseDatabaseService(this._tables);

  @override
  Future<Map<String, dynamic>> readAuthTokenClaims() async {
    return const <String, dynamic>{'sub': '777'};
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final source = (_tables[tableName] ?? const <Map<String, dynamic>>[])
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    if (filters == null || filters.isEmpty) {
      return source;
    }

    return source.where((row) {
      for (final entry in filters.entries) {
        if ((row[entry.key] ?? '').toString() != entry.value.toString()) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }
}

void main() {
  test(
    'getCategoriesForCourse resolves categories when course/category use canonical course_id values',
    () async {
      final now = DateTime(2026, 3, 28, 12).millisecondsSinceEpoch;
      final db = _FakeCourseDatabaseService({
        RobleTables.course: [
          {
            '_id': 'row-course-1',
            'course_id': 'course-auth-1',
            'name': 'Arquitectura de Software',
            'description': 'ARSW',
            'created_by': 777,
            'created_at': now,
          },
        ],
        RobleTables.category: [
          {
            '_id': 'row-cat-1',
            'category_id': 'cat-auth-1',
            'name': 'Sprint 1',
            'course_id': 'course-auth-1',
            'created_at': now,
          },
        ],
        RobleTables.groups: const <Map<String, dynamic>>[],
        RobleTables.userGroup: const <Map<String, dynamic>>[],
        RobleTables.users: const <Map<String, dynamic>>[],
        RobleTables.userCourse: const <Map<String, dynamic>>[],
      });

      final repo = CourseRepositoryImpl(db);

      final courses = await repo.getAll(777);
      expect(courses.length, 1);

      final categories = await repo.getCategoriesForCourse(courses.first.id);
      expect(categories.length, 1);
      expect(categories.first.name, 'Sprint 1');
    },
  );
}
