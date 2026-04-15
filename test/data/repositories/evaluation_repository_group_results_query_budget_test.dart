import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGroupResultsDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;
  final Map<String, int> readCounts = <String, int>{};

  _FakeGroupResultsDb(this._tables);

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    readCounts[tableName] = (readCounts[tableName] ?? 0) + 1;

    final rows = (_tables[tableName] ?? const <Map<String, dynamic>>[])
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

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) {
    throw Exception('Unexpected write for read-only test: $tableName');
  }
}

({EvaluationRepositoryImpl repo, _FakeGroupResultsDb db, int evalId})
_buildFixture() {
  const evaluationUuid = '11111111-1111-4111-8111-111111111111';
  const categoryUuid = '22222222-2222-4222-8222-222222222222';
  const groupUuid = '33333333-3333-4333-8333-333333333333';

  const anaUserUuid = '44444444-4444-4444-8444-444444444444';
  const bobUserUuid = '55555555-5555-4555-8555-555555555555';

  const resultEvalAnaUuid = '66666666-6666-4666-8666-666666666666';
  const resultEvalBobUuid = '77777777-7777-4777-8777-777777777777';

  const punctUuid = '88888888-8888-4888-8888-888888888888';
  const contribUuid = '99999999-9999-4999-8999-999999999999';
  const commitUuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const attitudeUuid = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  final categoryDomainId =
      DatabaseService.stableNumericIdFromSeed(categoryUuid);
  final evalId = DatabaseService.stableNumericIdFromSeed(evaluationUuid);

  final tables = <String, List<Map<String, dynamic>>>{
    RobleTables.evaluation: <Map<String, dynamic>>[
      {
        '_id': 'eval-row-1',
        'evaluation_id': evaluationUuid,
        'category_id': categoryDomainId,
        'title': 'Parcial 1',
      },
    ],
    RobleTables.groups: <Map<String, dynamic>>[
      {
        '_id': 'group-row-1',
        'group_id': groupUuid,
        'category_id': categoryUuid,
        'name': 'Equipo A',
      },
    ],
    RobleTables.userGroup: <Map<String, dynamic>>[
      {
        '_id': 'member-row-1',
        'group_id': groupUuid,
        'user_id': anaUserUuid,
      },
      {
        '_id': 'member-row-2',
        'group_id': groupUuid,
        'user_id': bobUserUuid,
      },
    ],
    RobleTables.users: <Map<String, dynamic>>[
      {
        '_id': 'user-row-1',
        'user_id': anaUserUuid,
        'name': 'Ana Lopez',
        'email': 'ana@uninorte.edu.co',
      },
      {
        '_id': 'user-row-2',
        'user_id': bobUserUuid,
        'name': 'Bob Ruiz',
        'email': 'bob@uninorte.edu.co',
      },
    ],
    RobleTables.criterium: <Map<String, dynamic>>[
      {
        '_id': 'criterium-row-1',
        'criterium_id': punctUuid,
        'name': 'Puntualidad',
      },
      {
        '_id': 'criterium-row-2',
        'criterium_id': contribUuid,
        'name': 'Contribuciones',
      },
      {
        '_id': 'criterium-row-3',
        'criterium_id': commitUuid,
        'name': 'Compromiso',
      },
      {
        '_id': 'criterium-row-4',
        'criterium_id': attitudeUuid,
        'name': 'Actitud',
      },
    ],
    RobleTables.resultEvaluation: <Map<String, dynamic>>[
      {
        '_id': 'result-eval-row-1',
        'resultEvaluation_id': resultEvalAnaUuid,
        'evaluation_id': evaluationUuid,
        'evaluated_id': anaUserUuid,
      },
      {
        '_id': 'result-eval-row-2',
        'resultEvaluation_id': resultEvalBobUuid,
        'evaluation_id': evaluationUuid,
        'evaluated_id': bobUserUuid,
      },
    ],
    RobleTables.resultCriterium: <Map<String, dynamic>>[
      {
        '_id': 'score-row-1',
        'result_id': resultEvalAnaUuid,
        'criterium_id': punctUuid,
        'score': 5,
      },
      {
        '_id': 'score-row-2',
        'result_id': resultEvalAnaUuid,
        'criterium_id': contribUuid,
        'score': 4,
      },
      {
        '_id': 'score-row-3',
        'result_id': resultEvalAnaUuid,
        'criterium_id': commitUuid,
        'score': 4,
      },
      {
        '_id': 'score-row-4',
        'result_id': resultEvalAnaUuid,
        'criterium_id': attitudeUuid,
        'score': 3,
      },
      {
        '_id': 'score-row-5',
        'result_id': resultEvalBobUuid,
        'criterium_id': punctUuid,
        'score': 3,
      },
      {
        '_id': 'score-row-6',
        'result_id': resultEvalBobUuid,
        'criterium_id': contribUuid,
        'score': 2,
      },
      {
        '_id': 'score-row-7',
        'result_id': resultEvalBobUuid,
        'criterium_id': commitUuid,
        'score': 5,
      },
      {
        '_id': 'score-row-8',
        'result_id': resultEvalBobUuid,
        'criterium_id': attitudeUuid,
        'score': 4,
      },
    ],
  };

  final db = _FakeGroupResultsDb(tables);
  final repo = EvaluationRepositoryImpl(db);
  return (repo: repo, db: db, evalId: evalId);
}

void main() {
  test('getGroupResults maps Roble-like rows into deterministic group output',
      () async {
    final fixture = _buildFixture();

    final results = await fixture.repo.getGroupResults(fixture.evalId);

    expect(results, hasLength(1));

    final group = results.single;
    expect(group.name, 'Equipo A');
    expect(group.average, 3.8);
    expect(group.criteria, <double>[4.0, 3.0, 4.5, 3.5]);

    final scoreByStudent = <String, double>{
      for (final student in group.students) student.name: student.score,
    };
    expect(scoreByStudent['Ana Lopez'], 4.0);
    expect(scoreByStudent['Bob Ruiz'], 3.5);

    final initialByStudent = <String, String>{
      for (final student in group.students) student.name: student.initial,
    };
    expect(initialByStudent['Ana Lopez'], 'A');
    expect(initialByStudent['Bob Ruiz'], 'B');
  });

  test('getGroupResults keeps robleRead roundtrips inside expected budget',
      () async {
    final fixture = _buildFixture();

    final results = await fixture.repo.getGroupResults(fixture.evalId);

    expect(results, hasLength(1));

    final reads = fixture.db.readCounts;
    expect(reads[RobleTables.evaluation] ?? 0, 1);
    expect(reads[RobleTables.groups] ?? 0, 1);
    expect(reads[RobleTables.userGroup] ?? 0, 1);
    expect(reads[RobleTables.users] ?? 0, 1);
    expect(reads[RobleTables.criterium] ?? 0, 1);
    expect(reads[RobleTables.resultEvaluation] ?? 0, 1);
    expect(reads[RobleTables.resultCriterium] ?? 0, 2);

    final totalReads = reads.values.fold<int>(0, (sum, value) => sum + value);
    expect(totalReads, 8);
  });
}
