import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/fake_cache_service.dart';
import '../helpers/mocks.dart';

GroupResult _buildGroup({
  required String name,
  required double average,
  List<double>? criteria,
  List<StudentResult>? students,
}) =>
    GroupResult(
      name: name,
      average: average,
      criteria: criteria ?? List<double>.filled(4, average),
      students: students ?? const <StudentResult>[],
    );

Evaluation _buildEval() => Evaluation(
      id: 1,
      name: 'Eval',
      categoryId: 1,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('overallAverage ignores zero-score groups', () async {
    final mockRepo = MockIEvaluationRepository();

    when(mockRepo.getGroupResults(1)).thenAnswer((_) async => <GroupResult>[
          _buildGroup(name: 'G1', average: 0, criteria: <double>[0, 0, 0, 0]),
          _buildGroup(name: 'G2', average: 4.2, criteria: <double>[4, 4, 4, 4]),
        ]);

    final ctrl = TeacherResultsController(mockRepo, FakeCacheService());
    await ctrl.loadGroupResults(_buildEval());

    expect(ctrl.overallAverage, 4.2);
  });

  test('overviewVm exposes formatted values after loadGroupResults', () async {
    final mockRepo = MockIEvaluationRepository();

    when(mockRepo.getGroupResults(1)).thenAnswer((_) async => <GroupResult>[
          _buildGroup(name: 'Equipo A', average: 4.0),
          _buildGroup(name: 'Equipo B', average: 0.0),
        ]);

    final ctrl = TeacherResultsController(mockRepo, FakeCacheService());
    await ctrl.loadGroupResults(_buildEval());

    expect(ctrl.overviewVm.overallAverageLabel, '4.0');
    expect(ctrl.overviewVm.groupCountLabel, '2');
    expect(ctrl.overviewVm.hasGroups, isTrue);
    expect(ctrl.overviewVm.groups, hasLength(2));
    expect(ctrl.overviewVm.groups.first.name, 'Equipo A');
    expect(ctrl.overviewVm.groups.first.averageLabel, '4.0');
    expect(ctrl.overviewVm.groups.first.progress, closeTo(0.6666666667, 1e-9));
  });

  test('openGroupDetail and closeGroupDetail manage selected group state',
      () async {
    final mockRepo = MockIEvaluationRepository();

    when(mockRepo.getGroupResults(1)).thenAnswer((_) async => <GroupResult>[
          _buildGroup(name: 'Equipo A', average: 4.0),
          _buildGroup(name: 'Equipo B', average: 3.0),
        ]);

    final ctrl = TeacherResultsController(mockRepo, FakeCacheService());
    await ctrl.loadGroupResults(_buildEval());

    expect(ctrl.selectedGroupIndex, isNull);
    expect(ctrl.selectedDetailVm, isNull);

    ctrl.openGroupDetail(1);
    expect(ctrl.selectedGroupIndex, 1);
    expect(ctrl.selectedDetailVm, isNotNull);
    expect(ctrl.selectedDetailVm!.groupName, 'Equipo B');

    ctrl.openGroupDetail(999);
    expect(ctrl.selectedGroupIndex, 1);

    ctrl.openGroupDetail(-1);
    expect(ctrl.selectedGroupIndex, 1);

    ctrl.closeGroupDetail();
    expect(ctrl.selectedGroupIndex, isNull);
    expect(ctrl.selectedDetailVm, isNull);
  });

  test('loadGroupResults sets user-friendly error and clears data on failure',
      () async {
    final mockRepo = MockIEvaluationRepository();

    when(mockRepo.getGroupResults(1)).thenThrow(_BlankError());

    final ctrl = TeacherResultsController(mockRepo, FakeCacheService())
      ..groupResults.add(_buildGroup(name: 'Stale data', average: 4.0))
      ..resultsError.value = 'Old error';
    ctrl.openGroupDetail(0);

    await ctrl.loadGroupResults(_buildEval());

    expect(ctrl.selectedEval.value, isNotNull);
    expect(ctrl.selectedEval.value!.id, 1);
    expect(ctrl.resultsLoading.value, isFalse);
    expect(ctrl.selectedGroupIndex, isNull);
    expect(ctrl.groupResults, isEmpty);
    expect(ctrl.resultsError.value, 'Error al cargar resultados');
  });
}

class _BlankError {
  @override
  String toString() => '';
}
