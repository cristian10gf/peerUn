/// Level-3 integration tests: teacher insights chain.
///
/// Test 1: real chain — EvaluationRepositoryImpl + FakeDatabaseServiceInsightsLevel3.
/// Tests 2–3: mockito mocks — verify cache-aside behaviour via verify().
library;

import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'helpers/controller_spies.dart';
import 'helpers/fake_cache_service.dart';
import 'helpers/fake_database_service_insights_level3.dart';
import 'helpers/getx_test_harness.dart';
import 'helpers/mocks.dart';

const _teacher = Teacher(
  id: '10',
  name: 'Prof Integration',
  email: 'teacher@uni.edu',
  initials: 'PI',
);

const _cacheKey = 'teacher_insights_v1_10';

SpyTeacherSessionController _buildSession() {
  final session = SpyTeacherSessionController();
  session.setTeacherSession(_teacher);
  return session;
}

TeacherInsightsController _buildCtrlWithFakeDb(
  FakeDatabaseServiceInsightsLevel3 db, [
  FakeCacheService? cache,
]) {
  return TeacherInsightsController(
    EvaluationRepositoryImpl(db),
    const TeacherInsightsDomainService(),
    const TeacherInsightsViewMapper(),
    _buildSession(),
    cache ?? FakeCacheService(),
  );
}

TeacherInsightsController _buildCtrlWithMock(
  MockIEvaluationRepository evalRepo,
  FakeCacheService cache,
) {
  when(evalRepo.getTeacherInsightsInput(10)).thenAnswer(
    (_) async => const TeacherInsightsInput(
      scorePoints: <TeacherInsightsScorePoint>[],
      evaluations: <TeacherInsightsEvaluationCoverage>[
        TeacherInsightsEvaluationCoverage(
          evaluationId: 'e1',
          evaluationName: 'Eval 1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
        ),
      ],
    ),
  );

  return TeacherInsightsController(
    evalRepo,
    const TeacherInsightsDomainService(),
    const TeacherInsightsViewMapper(),
    _buildSession(),
    cache,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetGetxTestState);

  test(
    'level3: loadInsights builds non-null view model via real repository chain',
    () async {
      final db = FakeDatabaseServiceInsightsLevel3();
      final ctrl = _buildCtrlWithFakeDb(db);

      await ctrl.loadInsights();

      expect(ctrl.isLoading.value, isFalse);
      expect(ctrl.loadError.value, isEmpty);
      expect(ctrl.overviewVm, isNotNull);
      expect(ctrl.overviewVm!.showNoEvaluationsState, isFalse);
      expect(ctrl.lastUpdatedAt.value, isNotNull);
      expect(db.readCallsByTable['evaluation'] ?? 0, greaterThan(0));
      expect(db.readCallsByTable.length, greaterThanOrEqualTo(7));
    },
  );

  test(
    'cache miss: loadInsights calls repository and writes insights to cache',
    () async {
      final evalRepo = MockIEvaluationRepository();
      final cache = FakeCacheService();
      final ctrl = _buildCtrlWithMock(evalRepo, cache);

      await ctrl.loadInsights();

      verify(evalRepo.getTeacherInsightsInput(10)).called(1);
      expect(cache.setCalls, contains(_cacheKey));
    },
  );

  test(
    'refreshInsights invalidates cache key and calls repository again',
    () async {
      final evalRepo = MockIEvaluationRepository();
      final cache = FakeCacheService();
      final ctrl = _buildCtrlWithMock(evalRepo, cache);

      await ctrl.loadInsights();
      await ctrl.refreshInsights();

      expect(cache.invalidateCalls, contains(_cacheKey));
      verify(evalRepo.getTeacherInsightsInput(10)).called(2);
      expect(ctrl.overviewVm, isNotNull);
    },
  );
}
