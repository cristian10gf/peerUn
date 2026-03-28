import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGroupImportDatabaseService extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;
  final Map<String, int> _idsByTable = {};

  int loginCallCount = 0;
  int setTokensCallCount = 0;

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

    final row = <String, dynamic>{'_id': '$tableName-$id', 'id': id, ...data};
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
}
