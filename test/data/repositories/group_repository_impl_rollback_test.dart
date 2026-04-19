// test/data/repositories/group_repository_impl_rollback_test.dart
import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal Brightspace CSV with 2 groups (Group A and Group B).
const _kCsv = 'Group Category Name,Group Name,Group Code,Username,OrgDefinedId,'
    'First Name,Last Name,Email Address,Group Enrollment Date\n'
    'Parcial 1,Group A,,user1,1,Ana,Perez,ana@uni.edu,2026-01-01\n'
    'Parcial 1,Group B,,user2,2,Bob,Smith,bob@uni.edu,2026-01-01\n';

class _FakeRollbackDb extends DatabaseService {
  /// When true, the second group creation throws.
  bool failOnSecondGroup = false;
  int _groupCreateCount = 0;

  final List<String> deletedKeys = [];

  @override
  Future<Map<String, dynamic>?> readAuthTokens() async => {
        'access_token': 'teacher-token',
        'refresh_token': 'teacher-refresh',
      };

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    if (tableName == RobleTables.course) {
      // courseId=1 → stableNumericIdFromSeed('1')==1 ✓
      return [
        {'_id': 'course-1', 'course_id': '1', 'name': 'Test Course'},
      ];
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (tableName == RobleTables.category) {
      return {'_id': 'cat-ref-1', 'category_id': 'cat-ref-1', 'name': data['name']};
    }
    if (tableName == RobleTables.groups) {
      _groupCreateCount++;
      if (failOnSecondGroup && _groupCreateCount == 2) {
        throw Exception('Network failure creating Group B');
      }
      final ref = 'grp-ref-$_groupCreateCount';
      return {'_id': ref, 'group_id': ref, 'name': data['name']};
    }
    return {'_id': 'row-${DateTime.now().millisecondsSinceEpoch}'};
  }

  @override
  Future<Map<String, dynamic>> robleDelete(
    String tableName,
    dynamic id,
  ) async {
    deletedKeys.add('$tableName:$id');
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> robleBulkInsert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async =>
      const [];

  @override
  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) async =>
      {'accessToken': 'student-token-$email'};

  @override
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {}

  @override
  Map<String, dynamic> decodeJwtClaims(String token) =>
      {'sub': 'uid-${token.hashCode}'};
}

void main() {
  group('GroupRepositoryImpl.importCsv rollback', () {
    test(
        'rolls back category and first group when second group creation fails',
        () async {
      final db = _FakeRollbackDb()..failOnSecondGroup = true;
      final repo = GroupRepositoryImpl(db);

      await expectLater(
        repo.importCsv(_kCsv, 'Parcial 1', 1, 1),
        throwsException,
      );

      // Category must be deleted.
      expect(
        db.deletedKeys,
        contains('${RobleTables.category}:cat-ref-1'),
        reason: 'Category must be rolled back when group creation fails',
      );

      // The successfully created first group must also be deleted.
      expect(
        db.deletedKeys,
        contains('${RobleTables.groups}:grp-ref-1'),
        reason: 'Already-created groups must be rolled back',
      );
    });

    test('does NOT rollback on success — all data persists', () async {
      final db = _FakeRollbackDb();
      final repo = GroupRepositoryImpl(db);

      final result = await repo.importCsv(_kCsv, 'Parcial 1', 1, 1);

      expect(db.deletedKeys, isEmpty,
          reason: 'No rollback should happen on success');
      expect(result.groups.length, 2);
    });
  });
}
