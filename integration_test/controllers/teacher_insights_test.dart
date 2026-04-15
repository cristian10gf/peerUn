import 'dart:convert';

import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/controller_spies.dart';
import '../helpers/fake_cache_service.dart';
import '../helpers/mocks.dart';

SpyTeacherSessionController _buildSession() {
  final session = SpyTeacherSessionController();
  session.setTeacherSession(const Teacher(
    id: '10',
    name: 'Docente',
    email: 'docente@uninorte.edu.co',
    initials: 'DO',
  ));
  return session;
}

const _emptyInput = TeacherInsightsInput(
  scorePoints: <TeacherInsightsScorePoint>[],
  evaluations: <TeacherInsightsEvaluationCoverage>[],
);

const _inputWithCoverage = TeacherInsightsInput(
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
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('loadInsights maps repository input into page vm', () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10)).thenAnswer(
      (_) async => const TeacherInsightsInput(
        scorePoints: <TeacherInsightsScorePoint>[
          TeacherInsightsScorePoint(
            evaluationId: 'e1',
            courseId: 'c1',
            courseName: 'IS',
            categoryId: 'cat1',
            categoryName: 'Sprint',
            groupId: 'g1',
            groupName: 'Alfa',
            studentId: 's1',
            studentName: 'Ana',
            score: 5,
          ),
          TeacherInsightsScorePoint(
            evaluationId: 'e1',
            courseId: 'c1',
            courseName: 'IS',
            categoryId: 'cat1',
            categoryName: 'Sprint',
            groupId: 'g1',
            groupName: 'Alfa',
            studentId: 's2',
            studentName: 'Bob',
            score: 4,
          ),
          TeacherInsightsScorePoint(
            evaluationId: 'e1',
            courseId: 'c1',
            courseName: 'IS',
            categoryId: 'cat1',
            categoryName: 'Sprint',
            groupId: 'g1',
            groupName: 'Alfa',
            studentId: 's1',
            studentName: 'Ana',
            score: 5,
          ),
          TeacherInsightsScorePoint(
            evaluationId: 'e1',
            courseId: 'c1',
            courseName: 'IS',
            categoryId: 'cat1',
            categoryName: 'Sprint',
            groupId: 'g1',
            groupName: 'Alfa',
            studentId: 's2',
            studentName: 'Bob',
            score: 4,
          ),
        ],
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

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      FakeCacheService(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.loadError.value, isEmpty);
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.overviewVm!.showNoEvaluationsState, isFalse);
    expect(ctrl.lastUpdatedAt.value, isNotNull);
  });

  test('loadInsights produces empty view model when no evaluations exist',
      () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10))
        .thenAnswer((_) async => _emptyInput);

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      FakeCacheService(),
    );

    await ctrl.loadInsights();

    expect(ctrl.loadError.value, isEmpty);
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.overviewVm!.showNoEvaluationsState, isTrue);
    expect(ctrl.overviewVm!.showNoResponsesState, isFalse);
  });

  test('loadInsights sets user-safe message on error', () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10)).thenThrow(_BlankError());

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      FakeCacheService(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.overviewVm, isNull);
    expect(ctrl.loadError.value, 'Error al cargar datos');
  });

  test('refreshInsights triggers another load and keeps latest vm', () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10))
        .thenAnswer((_) async => _inputWithCoverage);

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      FakeCacheService(),
    );

    await ctrl.loadInsights();
    final firstUpdate = ctrl.lastUpdatedAt.value;

    await Future<void>.delayed(const Duration(milliseconds: 1));
    await ctrl.refreshInsights();

    verify(mockRepo.getTeacherInsightsInput(10)).called(2);
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.lastUpdatedAt.value, isNotNull);
    expect(ctrl.lastUpdatedAt.value!.isAfter(firstUpdate!), isTrue);
  });

  test('loadInsights resets and sets error when no teacher session', () async {
    final session = SpyTeacherSessionController();
    final mockRepo = MockIEvaluationRepository();

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      session,
      FakeCacheService(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.overviewVm, isNull);
    expect(ctrl.loadError.value, 'Sesion docente no disponible');
    expect(ctrl.lastUpdatedAt.value, isNull);
  });

  test('loadInsights resets and sets error when teacher id is not an integer',
      () async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(const Teacher(
      id: 'not-a-number',
      name: 'Docente',
      email: 'docente@uninorte.edu.co',
      initials: 'DO',
    ));
    final mockRepo = MockIEvaluationRepository();

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      session,
      FakeCacheService(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.overviewVm, isNull);
    expect(ctrl.loadError.value, 'Sesion docente invalida');
  });

  test('resetState clears all observable state', () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10))
        .thenAnswer((_) async => _inputWithCoverage);

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      FakeCacheService(),
    );

    await ctrl.loadInsights();
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.lastUpdatedAt.value, isNotNull);

    ctrl.resetState();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.loadError.value, isEmpty);
    expect(ctrl.overviewVm, isNull);
    expect(ctrl.lastUpdatedAt.value, isNull);
  });

  test('loadInsights skips repository on cache hit', () async {
    final mockRepo = MockIEvaluationRepository();
    final cache = FakeCacheService();
    final primed = const TeacherInsightsInput(
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
    );
    cache.seed('teacher_insights_v1_10', jsonEncode(primed.toJson()));

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      cache,
    );

    await ctrl.loadInsights();

    verifyNever(mockRepo.getTeacherInsightsInput(any));
    expect(ctrl.overviewVm, isNotNull);
  });

  test('loadInsights writes to cache on cache miss', () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10))
        .thenAnswer((_) async => _inputWithCoverage);
    final cache = FakeCacheService();

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      cache,
    );

    await ctrl.loadInsights();

    expect(cache.setCalls, hasLength(1));
    expect(await cache.get('teacher_insights_v1_10'), isNotNull);
  });

  test('refreshInsights invalidates cache then reloads from repository',
      () async {
    final mockRepo = MockIEvaluationRepository();
    when(mockRepo.getTeacherInsightsInput(10))
        .thenAnswer((_) async => _emptyInput);
    final cache = FakeCacheService();
    cache.seed('teacher_insights_v1_10', '{"scorePoints":[],"evaluations":[]}');

    final ctrl = TeacherInsightsController(
      mockRepo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      _buildSession(),
      cache,
    );

    await ctrl.loadInsights(); // cache hit — repo not called
    verifyNever(mockRepo.getTeacherInsightsInput(any));

    await ctrl.refreshInsights(); // invalidates cache → repo called
    verify(mockRepo.getTeacherInsightsInput(10)).called(1);
    expect(cache.invalidateCalls, hasLength(1));
  });
}

class _BlankError {
  @override
  String toString() => '';
}
