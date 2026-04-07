import 'package:example/data/repositories/course_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCourseLookupDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;

  _FakeCourseLookupDb(this._tables);

  @override
  Future<Map<String, dynamic>> readAuthTokenClaims() async {
    return const {
      'sub': 'auth-teacher-uid',
      'email': 'teacher@uninorte.edu.co',
      'name': 'Teacher Session',
    };
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = _tables[RobleTables.users] ?? const <Map<String, dynamic>>[];
    for (final row in users) {
      final rowEmail = (row['email'] ?? '').toString().trim().toLowerCase();
      if (rowEmail == normalized) return Map<String, dynamic>.from(row);
    }
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

    if (filters == null || filters.isEmpty) return source;

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
    'getAll keeps showing courses after relogin when teacher has duplicated user rows',
    () async {
      final now = DateTime(2026, 4, 7, 9).millisecondsSinceEpoch;
      final db = _FakeCourseLookupDb({
        RobleTables.users: [
          {
            '_id': 'users-legacy',
            'id': 10,
            'user_id': 'legacy-teacher-uid',
            'email': 'teacher@uninorte.edu.co',
            'name': 'Teacher Legacy',
            'role': 'teacher',
          },
          {
            '_id': 'users-auth',
            'id': 11,
            'user_id': 'auth-teacher-uid',
            'email': 'teacher@uninorte.edu.co',
            'name': 'Teacher Auth',
            'role': 'teacher',
          },
        ],
        RobleTables.userCourse: [
          {
            '_id': 'uc-1',
            'course_id': 'course-auth-1',
            'user_id': 'auth-teacher-uid',
            'role': 'teacher',
          },
        ],
        RobleTables.course: [
          {
            '_id': 'course-row-1',
            'id': 77,
            'course_id': 'course-auth-1',
            'name': 'Arquitectura de Software',
            'description': 'ARSW',
            'created_by': 11,
            'created_at': now,
          },
          {
            '_id': 'course-row-2',
            'id': 88,
            'course_id': 'course-other-2',
            'name': 'Base de Datos',
            'description': 'DB',
            'created_by': 42,
            'created_at': now,
          },
        ],
      });

      final repo = CourseRepositoryImpl(db);
      final courses = await repo.getAll(999);

      expect(courses.length, 1);
      expect(courses.first.name, 'Arquitectura de Software');
      expect(courses.any((c) => c.name == 'Base de Datos'), isFalse);
    },
  );
}
