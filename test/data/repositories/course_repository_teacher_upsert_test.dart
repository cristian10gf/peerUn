import 'package:example/data/repositories/course_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCourseUpsertDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;

  _FakeCourseUpsertDb(this._tables);

  List<Map<String, dynamic>> rows(String tableName) {
    return (_tables[tableName] ?? const <Map<String, dynamic>>[])
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  int _nextId(String tableName) {
    final table = _tables[tableName] ?? const <Map<String, dynamic>>[];
    var maxId = 0;
    for (final row in table) {
      final id = int.tryParse((row['id'] ?? '').toString()) ?? 0;
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  @override
  Future<Map<String, dynamic>> readAuthTokenClaims() async {
    return const {
      'sub': 'auth-teacher-uid',
      'email': 'teacher@uninorte.edu.co',
      'name': 'Teacher Original',
    };
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = _tables[RobleTables.users] ?? const <Map<String, dynamic>>[];
    for (final user in users) {
      final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      if (userEmail == normalized) return Map<String, dynamic>.from(user);
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final source = rows(tableName);
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

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final id = _nextId(tableName);
    final table = _tables.putIfAbsent(tableName, () => <Map<String, dynamic>>[]);
    final row = <String, dynamic>{
      '_id': '$tableName-$id',
      'id': id,
      if (tableName == RobleTables.course && !data.containsKey('course_id'))
        'course_id': 'course-$id',
      ...data,
    };
    table.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final table = _tables[tableName] ?? <Map<String, dynamic>>[];
    for (var i = 0; i < table.length; i++) {
      if ((table[i]['_id'] ?? '').toString() != id.toString()) continue;
      final updated = <String, dynamic>{...table[i], ...updates};
      table[i] = updated;
      return Map<String, dynamic>.from(updated);
    }
    return const <String, dynamic>{};
  }
}

void main() {
  test(
    'create reuses existing teacher user row and avoids duplicate user records',
    () async {
      final db = _FakeCourseUpsertDb({
        RobleTables.users: [
          {
            '_id': 'users-10',
            'id': 10,
            'user_id': 'legacy-teacher-uid',
            'email': 'teacher@uninorte.edu.co',
            'name': 'Teacher Original',
            'role': 'teacher',
          },
        ],
        RobleTables.userCourse: <Map<String, dynamic>>[],
        RobleTables.course: <Map<String, dynamic>>[],
      });

      final repo = CourseRepositoryImpl(db);

      final created = await repo.create(
        name: 'Arquitectura de Software',
        code: 'ARSW',
        teacherId: 999,
      );

      final users = db.rows(RobleTables.users);
      final courses = db.rows(RobleTables.course);
      final userCourse = db.rows(RobleTables.userCourse);

      expect(created.teacherId, 10);
      expect(users.length, 1);
      expect(users.first['_id'], 'users-10');
      expect(users.first['user_id'], 'auth-teacher-uid');

      expect(courses.length, 1);
      expect(courses.first['created_by'], 10);

      expect(userCourse.length, 1);
      expect(userCourse.first['role'], 'teacher');
      expect(userCourse.first['user_id'], 'auth-teacher-uid');
    },
  );
}
