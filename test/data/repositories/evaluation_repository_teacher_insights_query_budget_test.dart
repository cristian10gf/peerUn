import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightsBudgetDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, int> readCounts = <String, int>{};

  _FakeInsightsBudgetDb(this.tables);

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    readCounts[tableName] = (readCounts[tableName] ?? 0) + 1;

    final rows = (tables[tableName] ?? const <Map<String, dynamic>>[])
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    if (filters == null || filters.isEmpty) {
      return rows;
    }

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
}

void main() {
  test(
    'getTeacherInsightsInput keeps read budget <= 10 and avoids nested reads',
    () async {
      final db = _FakeInsightsBudgetDb(<String, List<Map<String, dynamic>>>{
        RobleTables.evaluation: <Map<String, dynamic>>[],
        RobleTables.category: <Map<String, dynamic>>[],
        RobleTables.course: <Map<String, dynamic>>[],
        RobleTables.groups: <Map<String, dynamic>>[],
        RobleTables.userGroup: <Map<String, dynamic>>[],
        RobleTables.users: <Map<String, dynamic>>[],
        RobleTables.resultEvaluation: <Map<String, dynamic>>[],
        RobleTables.resultCriterium: <Map<String, dynamic>>[],
      });

      final repo = EvaluationRepositoryImpl(db);

      await repo.getTeacherInsightsInput(10);

      final totalReads = db.readCounts.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      expect(totalReads <= 10, isTrue);

      expect(db.readCounts[RobleTables.evaluation] ?? 0, lessThanOrEqualTo(1));
      expect(db.readCounts[RobleTables.category] ?? 0, lessThanOrEqualTo(1));
      expect(db.readCounts[RobleTables.course] ?? 0, lessThanOrEqualTo(1));
      expect(db.readCounts[RobleTables.groups] ?? 0, lessThanOrEqualTo(1));
      expect(db.readCounts[RobleTables.userGroup] ?? 0, lessThanOrEqualTo(1));
      expect(db.readCounts[RobleTables.users] ?? 0, lessThanOrEqualTo(1));
      expect(
        db.readCounts[RobleTables.resultEvaluation] ?? 0,
        lessThanOrEqualTo(1),
      );
      expect(
        db.readCounts[RobleTables.resultCriterium] ?? 0,
        lessThanOrEqualTo(1),
      );
    },
  );
}
