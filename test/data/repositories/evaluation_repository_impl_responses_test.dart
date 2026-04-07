// test/data/repositories/evaluation_repository_impl_responses_test.dart
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeResponseDb extends DatabaseService {
  final List<Map<String, dynamic>> _rows = [];
  final List<String> createCalls = [];
  final List<String> updateCalls = [];

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    if (tableName != RobleTables.evaluationCriterium) return const [];
    if (filters == null || filters.isEmpty) {
      return _rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    return _rows
        .where((r) => filters.entries.every(
              (e) => r[e.key].toString() == e.value.toString(),
            ))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final row = Map<String, dynamic>.from(data)
      ..['_id'] = 'row-${_rows.length + 1}';
    _rows.add(row);
    createCalls.add(data['criterion_id'].toString());
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
