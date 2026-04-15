// test/data/repositories/evaluation_repository_impl_responses_test.dart
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeResponseDb extends DatabaseService {
  /// Rows written to the resultCriterium table (the scores table the test checks).
  final List<Map<String, dynamic>> _rows = [];

  /// Rows written to the resultEvaluation table.
  final List<Map<String, dynamic>> _resultEvalRows = [];

  /// Rows written to the criterium metadata table (tracked separately, not in createCalls).
  final List<Map<String, dynamic>> _criteriumMetaRows = [];

  /// criterium_id values passed to resultCriterium creates, in order.
  final List<String> createCalls = [];

  /// Row _ids passed to resultCriterium updates, in order.
  final List<String> updateCalls = [];

  List<Map<String, dynamic>> _filteredFrom(
    List<Map<String, dynamic>> source,
    Map<String, dynamic>? filters,
  ) {
    if (filters == null || filters.isEmpty) {
      return source.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    return source
        .where((r) => filters.entries.every(
              (e) => (r[e.key] ?? '').toString() == e.value.toString(),
            ))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    if (tableName == RobleTables.evaluation) {
      // id=1 → _rowId==1 → _findEvalById(rows, 1) finds it.
      return [
        {'id': 1, 'category_id': 0},
      ];
    }
    if (tableName == RobleTables.users) {
      // stableNumericIdFromSeed('2')==2, stableNumericIdFromSeed('3')==3.
      return [
        {'id': 2, '_id': 'user-2', 'user_id': 'uuid-user-2'},
        {'id': 3, '_id': 'user-3', 'user_id': 'uuid-user-3'},
      ];
    }
    if (tableName == RobleTables.resultEvaluation) {
      return _filteredFrom(_resultEvalRows, filters);
    }
    if (tableName == RobleTables.criterium) {
      return _filteredFrom(_criteriumMetaRows, filters);
    }
    if (tableName == RobleTables.resultCriterium) {
      return _filteredFrom(_rows, filters);
    }
    return const [];
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (tableName == RobleTables.resultEvaluation) {
      final idx = _resultEvalRows.length + 1;
      final row = Map<String, dynamic>.from(data)
        ..['_id'] = 'result-eval-$idx'
        ..['resultEvaluation_id'] = 'result-eval-uuid-$idx';
      _resultEvalRows.add(row);
      return row;
    }
    if (tableName == RobleTables.criterium) {
      // Return WITHOUT criterium_id so _getOrCreateCriteriaMap falls back to criterion.id.
      final row = Map<String, dynamic>.from(data)
        ..['_id'] = 'meta-${_criteriumMetaRows.length + 1}';
      _criteriumMetaRows.add(row);
      return row;
    }
    // resultCriterium — the actual scores table tracked by the test.
    final row = Map<String, dynamic>.from(data)
      ..['_id'] = 'row-${_rows.length + 1}';
    _rows.add(row);
    createCalls.add(data['criterium_id']?.toString() ?? '');
    return row;
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final idx = _rows.indexWhere((r) => r['_id'] == id);
    if (idx != -1) _rows[idx] = {..._rows[idx], ...updates};
    updateCalls.add(id.toString());
    return idx != -1 ? _rows[idx] : updates;
  }
}

void main() {
  group('EvaluationRepositoryImpl.saveResponses', () {
    test('first submission creates new criterium rows', () async {
      final db = _FakeResponseDb();
      final repo = EvaluationRepositoryImpl(db);

      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 4, 'c2': 5},
      );

      expect(db.createCalls, containsAll(['c1', 'c2']));
      expect(db.updateCalls, isEmpty);
    });

    test('second submission updates existing rows — no duplicates created',
        () async {
      final db = _FakeResponseDb();
      final repo = EvaluationRepositoryImpl(db);

      // First submission.
      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 4, 'c2': 5},
      );
      db.createCalls.clear();
      db.updateCalls.clear();

      // Second submission with changed scores.
      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 3, 'c2': 5},
      );

      // Must update, not create new duplicates.
      expect(db.createCalls, isEmpty,
          reason: 'No new rows should be created on re-submit');
      expect(db.updateCalls, containsAll(['row-1', 'row-2']));

      // Total rows must still be 2.
      expect(db._rows.length, 2);
    });
  });
}
