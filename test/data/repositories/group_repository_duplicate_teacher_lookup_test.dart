import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGroupLookupDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;

  _FakeGroupLookupDb(this._tables);

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
    'getAll keeps showing categories after relogin when teacher has duplicated user rows',
    () async {
      final now = DateTime(2026, 4, 7, 9).millisecondsSinceEpoch;
      final db = _FakeGroupLookupDb({
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
          {
            '_id': 'users-student',
            'id': 21,
            'user_id': 'student-auth-1',
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
            'role': 'student',
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
        ],
        RobleTables.category: [
          {
            '_id': 'cat-row-1',
            'id': 301,
            'category_id': 'cat-auth-1',
            'name': 'Sprint 1',
            'course_id': 'course-auth-1',
            'created_at': now,
          },
          {
            '_id': 'cat-row-2',
            'id': 302,
            'category_id': 'cat-other-2',
            'name': 'Sprint Ajeno',
            'course_id': 'course-other-2',
            'created_at': now,
          },
        ],
        RobleTables.groups: [
          {
            '_id': 'group-row-1',
            'id': 401,
            'group_id': 'group-auth-1',
            'name': 'Grupo 1',
            'category_id': 'cat-auth-1',
          },
          {
            '_id': 'group-row-2',
            'id': 402,
            'group_id': 'group-other-2',
            'name': 'Grupo Ajeno',
            'category_id': 'cat-other-2',
          },
        ],
        RobleTables.userGroup: [
          {
            '_id': 'ug-1',
            'group_id': 'group-auth-1',
            'user_id': 'student-auth-1',
          },
          {
            '_id': 'ug-2',
            'group_id': 'group-other-2',
            'user_id': 'student-auth-1',
          },
        ],
      });

      final repo = GroupRepositoryImpl(db);
      final categories = await repo.getAll(999);

      expect(categories.length, 1);
      expect(categories.first.name, 'Sprint 1');
      expect(categories.first.groupCount, 1);
      expect(categories.first.studentCount, 1);
      expect(categories.any((c) => c.name == 'Sprint Ajeno'), isFalse);
    },
  );
}
