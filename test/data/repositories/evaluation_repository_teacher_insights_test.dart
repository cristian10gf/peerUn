import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightsDb extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> tables;

  _FakeInsightsDb(this.tables);

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
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
    'getTeacherInsightsInput returns only teacher-owned evaluations',
    () async {
      const teacherId = 10;

      const evalAUuid = 'eval-a-uuid';
      const evalBUuid = 'eval-b-uuid';

      const categoryAUuid = 'category-a-uuid';
      const categoryBUuid = 'category-b-uuid';

      const courseAUuid = 'course-a-uuid';
      const courseBUuid = 'course-b-uuid';

      const groupAUuid = 'group-a-uuid';
      const groupBUuid = 'group-b-uuid';

      const userAnaUuid = 'user-ana-uuid';
      const userBobUuid = 'user-bob-uuid';
      const userMalloryUuid = 'user-mallory-uuid';

      const resultAnaUuid = 'result-ana-uuid';
      const resultBobUuid = 'result-bob-uuid';
      const resultMalloryUuid = 'result-mallory-uuid';

      final categoryADomain = DatabaseService.stableNumericIdFromSeed(
        categoryAUuid,
      );
      final categoryBDomain = DatabaseService.stableNumericIdFromSeed(
        categoryBUuid,
      );

      final db = _FakeInsightsDb(<String, List<Map<String, dynamic>>>{
        RobleTables.evaluation: <Map<String, dynamic>>[
          {
            '_id': 'eval-row-a',
            'evaluation_id': evalAUuid,
            'created_by': teacherId,
            'category_id': categoryADomain,
            'title': 'Eval A',
          },
          {
            '_id': 'eval-row-b',
            'evaluation_id': evalBUuid,
            'created_by': 11,
            'category_id': categoryBDomain,
            'title': 'Eval B',
          },
        ],
        RobleTables.category: <Map<String, dynamic>>[
          {
            '_id': 'cat-row-a',
            'category_id': categoryAUuid,
            'name': 'Sprint A',
            'course_id': courseAUuid,
          },
          {
            '_id': 'cat-row-b',
            'category_id': categoryBUuid,
            'name': 'Sprint B',
            'course_id': courseBUuid,
          },
        ],
        RobleTables.course: <Map<String, dynamic>>[
          {
            '_id': 'course-row-a',
            'course_id': courseAUuid,
            'name': 'Arquitectura de Software',
          },
          {'_id': 'course-row-b', 'course_id': courseBUuid, 'name': 'Redes'},
        ],
        RobleTables.groups: <Map<String, dynamic>>[
          {
            '_id': 'group-row-a',
            'group_id': groupAUuid,
            'category_id': categoryAUuid,
            'name': 'Equipo Alfa',
          },
          {
            '_id': 'group-row-b',
            'group_id': groupBUuid,
            'category_id': categoryBUuid,
            'name': 'Equipo Beta',
          },
        ],
        RobleTables.userGroup: <Map<String, dynamic>>[
          {
            '_id': 'member-row-a1',
            'group_id': groupAUuid,
            'user_id': userAnaUuid,
          },
          {
            '_id': 'member-row-a2',
            'group_id': groupAUuid,
            'user_id': userBobUuid,
          },
          {
            '_id': 'member-row-b1',
            'group_id': groupBUuid,
            'user_id': userMalloryUuid,
          },
        ],
        RobleTables.users: <Map<String, dynamic>>[
          {
            '_id': 'user-row-a',
            'user_id': userAnaUuid,
            'name': 'Ana Lopez',
            'email': 'ana@uninorte.edu.co',
          },
          {
            '_id': 'user-row-b',
            'user_id': userBobUuid,
            'name': 'Bob Ruiz',
            'email': 'bob@uninorte.edu.co',
          },
          {
            '_id': 'user-row-c',
            'user_id': userMalloryUuid,
            'name': 'Mallory',
            'email': 'mallory@uninorte.edu.co',
          },
        ],
        RobleTables.resultEvaluation: <Map<String, dynamic>>[
          {
            '_id': 'res-eval-row-a1',
            'resultEvaluation_id': resultAnaUuid,
            'evaluation_id': evalAUuid,
            'evaluated_id': userAnaUuid,
          },
          {
            '_id': 'res-eval-row-a2',
            'resultEvaluation_id': resultBobUuid,
            'evaluation_id': evalAUuid,
            'evaluated_id': userBobUuid,
          },
          {
            '_id': 'res-eval-row-b1',
            'resultEvaluation_id': resultMalloryUuid,
            'evaluation_id': evalBUuid,
            'evaluated_id': userMalloryUuid,
          },
        ],
        RobleTables.resultCriterium: <Map<String, dynamic>>[
          {'_id': 'res-crit-row-a1', 'result_id': resultAnaUuid, 'score': 5},
          {'_id': 'res-crit-row-a2', 'result_id': resultBobUuid, 'score': 4},
          {
            '_id': 'res-crit-row-b1',
            'result_id': resultMalloryUuid,
            'score': 2,
          },
        ],
      });

      final repo = EvaluationRepositoryImpl(db);

      final input = await repo.getTeacherInsightsInput(teacherId);

      expect(input.evaluations, hasLength(1));
      expect(input.evaluations.single.evaluationId, evalAUuid);
      expect(input.evaluations.single.evaluationName, 'Eval A');
      expect(input.evaluations.single.categoryName, 'Sprint A');
      expect(input.evaluations.single.courseName, 'Arquitectura de Software');

      expect(input.scorePoints, hasLength(2));
      expect(
        input.scorePoints.map((point) => point.evaluationId).toSet(),
        equals(<String>{evalAUuid}),
      );
      expect(
        input.scorePoints.map((point) => point.studentName).toSet(),
        equals(<String>{'Ana Lopez', 'Bob Ruiz'}),
      );
      expect(
        input.scorePoints.map((point) => point.groupName).toSet(),
        equals(<String>{'Equipo Alfa'}),
      );
      expect(
        input.scorePoints.map((point) => point.courseName).toSet(),
        equals(<String>{'Arquitectura de Software'}),
      );
      expect(
        input.scorePoints.map((point) => point.score).toSet(),
        equals(<int>{4, 5}),
      );
    },
  );
}
