import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

import '../../helpers/fake_cache_service.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  test('overallAverage ignores zero-score groups', () async {
    final repo = FakeEvaluationRepository()
      ..groupResults = const <GroupResult>[
        GroupResult(
          name: 'G1',
          average: 0,
          criteria: <double>[0, 0, 0, 0],
          students: <StudentResult>[],
        ),
        GroupResult(
          name: 'G2',
          average: 4.2,
          criteria: <double>[4, 4, 4, 4],
          students: <StudentResult>[],
        ),
      ];

    final ctrl = TeacherResultsController(repo, FakeCacheService());
    await ctrl.loadGroupResults(
      Evaluation(
        id: 1,
        name: 'Eval',
        categoryId: 1,
        categoryName: 'Cat',
        hours: 24,
        visibility: 'private',
        createdAt: DateTime(2026, 4, 1),
        closesAt: DateTime(2099, 1, 1),
      ),
    );

    expect(ctrl.overallAverage, 4.2);
  });
}
