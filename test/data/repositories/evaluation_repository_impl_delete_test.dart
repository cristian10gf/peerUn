import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake DB that can fail on evaluation delete and tracks all deletes.
class _FakeDb extends DatabaseService {
  bool failEvalDelete = false;
  final List<String> deletedKeys = [];

  final List<Map<String, dynamic>> _evals = [
    {'_id': 'eval-1', 'id': 10, 'title': 'Sprint 1'},
  ];

  final List<Map<String, dynamic>> _criteria = [
    {'_id': 'crit-1', 'eval_id': 10, 'criterion_id': 'c1', 'score': 4},
    {'_id': 'crit-2', 'eval_id': 10, 'criterion_id': 'c2', 'score': 3},
  ];

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final source = tableName == RobleTables.evaluation
        ? _evals
        : tableName == RobleTables.evaluationCriterium
            ? _criteria
            : const <Map<String, dynamic>>[];

    if (filters == null || filters.isEmpty) {
      return source.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    return source
        .where((r) => filters.entries.every(
              (e) => r[e.key].toString() == e.value.toString(),
            ))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> robleDelete(
    String tableName,
    dynamic id,
  ) async {
    if (failEvalDelete && tableName == RobleTables.evaluation) {
      throw Exception('Network error');
    }
    deletedKeys.add('$tableName:$id');
    return {};
  }
}

void main() {
  group('EvaluationRepositoryImpl.delete', () {
    test(
        'deletes evaluation BEFORE criteria so a failure leaves criteria intact',
        () async {
      final db = _FakeDb()..failEvalDelete = true;
      final repo = EvaluationRepositoryImpl(db);

      // Should throw because evaluation delete fails.
      await expectLater(repo.delete(10), throwsException);

      // Criteria must NOT have been deleted — nothing orphaned.
      expect(db.deletedKeys, isEmpty,
          reason: 'No criteria should be deleted when eval delete fails');
    });

    test('deletes evaluation then cleans up criteria on success', () async {
      final db = _FakeDb();
      final repo = EvaluationRepositoryImpl(db);

      await repo.delete(10);

      // Evaluation deleted first.
      expect(db.deletedKeys.first, '${RobleTables.evaluation}:eval-1');
      // Criteria cleaned up after.
      expect(db.deletedKeys, contains('${RobleTables.evaluationCriterium}:crit-1'));
      expect(db.deletedKeys, contains('${RobleTables.evaluationCriterium}:crit-2'));
    });
  });
}
