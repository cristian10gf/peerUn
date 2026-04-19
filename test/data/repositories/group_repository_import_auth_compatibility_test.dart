import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGroupImportDatabaseService extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;
  final Map<String, int> _idsByTable = {};

  int loginCallCount = 0;
  int setTokensCallCount = 0;
  int findUserByEmailCallCount = 0;
  int userCourseNoFilterReadCount = 0;
  int userCourseFilteredReadCount = 0;
  int userGroupNoFilterReadCount = 0;
  int userGroupFilteredReadCount = 0;

  _FakeGroupImportDatabaseService(this._tables);

  @override
  String get studentDefaultPassword => 'Password123!';

  @override
  Future<Map<String, dynamic>?> readAuthTokens() async {
    return {
      'access_token': 'teacher-access',
      'refresh_token': 'teacher-refresh',
    };
  }

  @override
  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) async {
    throw Exception('409: usuario ya registrado');
  }

  @override
  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    loginCallCount++;
    throw Exception('HTTP 401: contrasena incorrecta');
  }

  @override
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    setTokensCallCount++;
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    findUserByEmailCallCount++;
    final normalized = email.trim().toLowerCase();
    final users = _tables[RobleTables.users] ?? const <Map<String, dynamic>>[];
    for (final user in users) {
      final rowEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      if (rowEmail == normalized) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    if (tableName == RobleTables.userCourse) {
      if (filters == null || filters.isEmpty) {
        userCourseNoFilterReadCount++;
      } else {
        userCourseFilteredReadCount++;
      }
    }
    if (tableName == RobleTables.userGroup) {
      if (filters == null || filters.isEmpty) {
        userGroupNoFilterReadCount++;
      } else {
        userGroupFilteredReadCount++;
      }
    }

    final rows = (_tables[tableName] ?? const <Map<String, dynamic>>[])
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    if (filters == null || filters.isEmpty) return rows;

    return rows
        .where((row) {
          for (final entry in filters.entries) {
            if ((row[entry.key] ?? '').toString() != entry.value.toString()) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final table = _tables.putIfAbsent(
      tableName,
      () => <Map<String, dynamic>>[],
    );

    if (tableName == RobleTables.users) {
      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      final duplicate = table.any(
        (row) => (row['email'] ?? '').toString().trim().toLowerCase() == email,
      );
      if (duplicate) {
        throw Exception('duplicate user email');
      }
    }

    final id = (_idsByTable[tableName] ?? 0) + 1;
    _idsByTable[tableName] = id;

    final payload = <String, dynamic>{...data};
    if (tableName == RobleTables.course && payload['course_id'] == null) {
      payload['course_id'] = 'course-$id';
    }
    if (tableName == RobleTables.category && payload['category_id'] == null) {
      payload['category_id'] = 'category-$id';
    }
    if (tableName == RobleTables.groups && payload['group_id'] == null) {
      payload['group_id'] = 'group-$id';
    }

    final row = <String, dynamic>{'_id': '$tableName-$id', 'id': id, ...payload};
    table.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final table = _tables[tableName];
    if (table == null) return const <String, dynamic>{};

    for (var i = 0; i < table.length; i++) {
      final row = table[i];
      final rowKey = (row['_id'] ?? '').toString();
      if (rowKey == id.toString()) {
        final updated = <String, dynamic>{...row, ...updates};
        table[i] = updated;
        return Map<String, dynamic>.from(updated);
      }
    }

    return const <String, dynamic>{};
  }
}

void main() {
  test(
    'importCsv does not require student login for already-registered users',
    () async {
      final db = _FakeGroupImportDatabaseService({
        RobleTables.course: [
          {'_id': 'course-77', 'course_id': '77', 'name': 'Test Course'},
        ],
        RobleTables.users: [
          {
            '_id': 'users-100',
            'id': 100,
            'user_id': 'auth-existing-100',
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
            'role': 'student',
          },
        ],
        RobleTables.userGroup: <Map<String, dynamic>>[],
        RobleTables.userCourse: <Map<String, dynamic>>[],
      });

      final repo = GroupRepositoryImpl(db);

      const csv =
          'nrc,group,unused,username,unused,first,last\n'
          '12345,Grupo 1,x,alice@uninorte.edu.co,x,Alice,Lopez\n';

      final imported = await repo.importCsv(csv, 'Sprint 1', 999, 77);

      expect(imported.name, 'Sprint 1');
      expect(imported.groups.length, 1);
      expect(imported.groups.first.members.length, 1);
      expect(
        imported.groups.first.members.first.username,
        'alice@uninorte.edu.co',
      );
      expect(db.loginCallCount, 0);
      expect(db.setTokensCallCount, 0);
    },
  );

  test(
    'importCsv avoids per-member relation reads after warm-up',
    () async {
      final db = _FakeGroupImportDatabaseService({
        RobleTables.course: [
          {'_id': 'course-77', 'course_id': '77', 'name': 'Test Course'},
        ],
        RobleTables.users: [
          {
            '_id': 'users-201',
            'id': 201,
            'user_id': 'auth-existing-201',
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
            'role': 'student',
          },
          {
            '_id': 'users-202',
            'id': 202,
            'user_id': 'auth-existing-202',
            'email': 'bob@uninorte.edu.co',
            'name': 'Bob',
            'role': 'student',
          },
        ],
        RobleTables.userGroup: <Map<String, dynamic>>[],
        RobleTables.userCourse: <Map<String, dynamic>>[],
      });

      final repo = GroupRepositoryImpl(db);

      const csv =
          'nrc,group,unused,username,unused,first,last\n'
          '12345,Grupo 1,x,alice@uninorte.edu.co,x,Alice,Lopez\n'
          '12345,Grupo 1,x,bob@uninorte.edu.co,x,Bob,Ruiz\n';

      await repo.importCsv(csv, 'Sprint 2', 999, 77);

      // tableExists() causes one extra unfiltered read per table; total ≤ 2
      // (tableExists check + actual warm-up read), never per-member.
      expect(db.userCourseNoFilterReadCount, lessThanOrEqualTo(2));
      expect(db.userGroupNoFilterReadCount, lessThanOrEqualTo(2));
      expect(db.userCourseFilteredReadCount, 0);
      expect(db.userGroupFilteredReadCount, 0);
    },
  );

  test(
    'importCsv caches user lookup per unique email in same import',
    () async {
      final db = _FakeGroupImportDatabaseService({
        RobleTables.course: [
          {'_id': 'course-77', 'course_id': '77', 'name': 'Test Course'},
        ],
        RobleTables.users: [
          {
            '_id': 'users-301',
            'id': 301,
            'user_id': 'auth-existing-301',
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
            'role': 'student',
          },
          {
            '_id': 'users-302',
            'id': 302,
            'user_id': 'auth-existing-302',
            'email': 'bob@uninorte.edu.co',
            'name': 'Bob',
            'role': 'student',
          },
        ],
        RobleTables.userGroup: <Map<String, dynamic>>[],
        RobleTables.userCourse: <Map<String, dynamic>>[],
      });

      final repo = GroupRepositoryImpl(db);

      const csv =
          'nrc,group,unused,username,unused,first,last\n'
          '12345,Grupo 1,x,alice@uninorte.edu.co,x,Alice,Lopez\n'
          '12345,Grupo 1,x,bob@uninorte.edu.co,x,Bob,Ruiz\n'
          '12345,Grupo 2,x,alice@uninorte.edu.co,x,Alice,Lopez\n'
          '12345,Grupo 2,x,bob@uninorte.edu.co,x,Bob,Ruiz\n';

      await repo.importCsv(csv, 'Sprint 3', 999, 77);

      expect(db.findUserByEmailCallCount, lessThanOrEqualTo(2));
    },
  );

  test(
    'importCsv persists canonical references in category, group and relation tables',
    () async {
      final db = _FakeGroupImportDatabaseService({
        RobleTables.course: [
          {
            '_id': 'course-row-77',
            'id': 77,
            'course_id': '77',
            'name': 'Arquitectura de Software',
          },
        ],
        RobleTables.users: [
          {
            '_id': 'users-500',
            'id': 500,
            'user_id': 'auth-existing-500',
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
            'role': 'student',
          },
        ],
        RobleTables.userGroup: <Map<String, dynamic>>[],
        RobleTables.userCourse: <Map<String, dynamic>>[],
      });

      final repo = GroupRepositoryImpl(db);

      const csv =
          'nrc,group,unused,username,unused,first,last\n'
          '12345,Grupo Canonico,x,alice@uninorte.edu.co,x,Alice,Lopez\n';

      await repo.importCsv(csv, 'Sprint Canonico', 999, 77);

      final categories = db._tables[RobleTables.category] ?? const [];
      final groups = db._tables[RobleTables.groups] ?? const [];
      final userCourse = db._tables[RobleTables.userCourse] ?? const [];
      final userGroup = db._tables[RobleTables.userGroup] ?? const [];

      expect(categories, isNotEmpty);
      expect(groups, isNotEmpty);
      expect(userCourse, isNotEmpty);
      expect(userGroup, isNotEmpty);

      final category = categories.first;
      final group = groups.first;
      final courseRel = userCourse.first;
      final groupRel = userGroup.first;

      expect(category['course_id'], '77');
      expect(group['category_id'], category['category_id']);
      expect(courseRel['course_id'], '77');
      expect(courseRel['user_id'], 'auth-existing-500');
      expect(groupRel['group_id'], group['group_id']);
      expect(groupRel['user_id'], 'auth-existing-500');
    },
  );
}
