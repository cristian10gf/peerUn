import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  SpyTeacherSessionController buildLoggedTeacherSession() {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '10',
        name: 'Docente',
        email: 'docente@uninorte.edu.co',
        initials: 'DO',
      ),
    );
    return session;
  }

  test('loadInsights maps repository input into page vm', () async {
    final repo = FakeEvaluationRepository()
      ..teacherInsightsInput = const TeacherInsightsInput(
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
      );

    final ctrl = TeacherInsightsController(
      repo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      buildLoggedTeacherSession(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.loadError.value, isEmpty);
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.overviewVm!.showNoEvaluationsState, isFalse);
    expect(ctrl.lastUpdatedAt.value, isNotNull);
  });

  test(
    'loadInsights produces empty view model when no evaluations exist',
    () async {
      final repo = FakeEvaluationRepository()
        ..teacherInsightsInput = const TeacherInsightsInput(
          scorePoints: <TeacherInsightsScorePoint>[],
          evaluations: <TeacherInsightsEvaluationCoverage>[],
        );

      final ctrl = TeacherInsightsController(
        repo,
        const TeacherInsightsDomainService(),
        const TeacherInsightsViewMapper(),
        buildLoggedTeacherSession(),
      );

      await ctrl.loadInsights();

      expect(ctrl.loadError.value, isEmpty);
      expect(ctrl.overviewVm, isNotNull);
      expect(ctrl.overviewVm!.showNoEvaluationsState, isTrue);
      expect(ctrl.overviewVm!.showNoResponsesState, isFalse);
    },
  );

  test('loadInsights sets user-safe message on error', () async {
    final repo = FakeEvaluationRepository()..nextError = _BlankError();

    final ctrl = TeacherInsightsController(
      repo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      buildLoggedTeacherSession(),
    );

    await ctrl.loadInsights();

    expect(ctrl.isLoading.value, isFalse);
    expect(ctrl.overviewVm, isNull);
    expect(ctrl.loadError.value, 'Error al cargar datos');
  });

  test('refreshInsights triggers another load and keeps latest vm', () async {
    final repo = _CountingInsightsRepository()
      ..teacherInsightsInput = const TeacherInsightsInput(
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

    final ctrl = TeacherInsightsController(
      repo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      buildLoggedTeacherSession(),
    );

    await ctrl.loadInsights();
    final firstUpdate = ctrl.lastUpdatedAt.value;

    await ctrl.refreshInsights();

    expect(repo.readCalls, 2);
    expect(ctrl.overviewVm, isNotNull);
    expect(ctrl.lastUpdatedAt.value, isNotNull);
    expect(ctrl.lastUpdatedAt.value!.isAfter(firstUpdate!), isTrue);
  });
}

class _CountingInsightsRepository extends FakeEvaluationRepository {
  int readCalls = 0;

  @override
  Future<TeacherInsightsInput> getTeacherInsightsInput(int teacherId) async {
    readCalls++;
    return super.getTeacherInsightsInput(teacherId);
  }
}

class _BlankError {
  @override
  String toString() => '';
}
