import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/pages/teacher/t_data_insights_page.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/fake_cache_service.dart';
import '../../helpers/getx_test_harness.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  final extraRoutes = <GetPage<dynamic>>[
    GetPage(name: '/teacher/dash', page: () => const SizedBox.shrink()),
    GetPage(name: '/teacher/new-eval', page: () => const SizedBox.shrink()),
  ];

  SpyTeacherSessionController buildSession() {
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

  TeacherInsightsController registerController(FakeEvaluationRepository repo) {
    final ctrl = TeacherInsightsController(
      repo,
      const TeacherInsightsDomainService(),
      const TeacherInsightsViewMapper(),
      buildSession(),
      FakeCacheService(),
    );
    Get.put<TeacherInsightsController>(ctrl);
    return ctrl;
  }

  testWidgets('shows loading state first and then KPI sections', (
    tester,
  ) async {
    final repo = _DelayedInsightsRepository()
      ..teacherInsightsInput = _buildFullInput();

    registerController(repo);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TDataInsightsPage(),
        extraRoutes: extraRoutes,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();

    expect(find.text('CURSOS'), findsOneWidget);
    expect(find.text('CATEGORIAS'), findsOneWidget);
    expect(find.text('MEJOR GRUPO'), findsOneWidget);
    expect(find.text('TOP ESTUDIANTES'), findsOneWidget);
    expect(find.text('EN RIESGO'), findsOneWidget);
  });

  testWidgets('shows empty state when no evaluations are found', (
    tester,
  ) async {
    final repo = FakeEvaluationRepository()
      ..teacherInsightsInput = const TeacherInsightsInput(
        scorePoints: <TeacherInsightsScorePoint>[],
        evaluations: <TeacherInsightsEvaluationCoverage>[],
      );

    registerController(repo);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TDataInsightsPage(),
        extraRoutes: extraRoutes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aun no tienes evaluaciones'), findsOneWidget);
    expect(find.text('Crear evaluacion'), findsOneWidget);
  });

  testWidgets('shows error state with retry action', (tester) async {
    final repo = FakeEvaluationRepository()..nextError = Exception('fallo');

    registerController(repo);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TDataInsightsPage(),
        extraRoutes: extraRoutes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar los datos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('renders all KPI blocks with data', (tester) async {
    final repo = FakeEvaluationRepository()
      ..teacherInsightsInput = _buildFullInput();

    registerController(repo);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TDataInsightsPage(),
        extraRoutes: extraRoutes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingenieria de Software'), findsAtLeastNWidgets(1));
    expect(find.text('Sprint 1'), findsAtLeastNWidgets(1));
    expect(find.text('Equipo Alfa'), findsAtLeastNWidgets(1));
    expect(find.text('Ana Lopez'), findsAtLeastNWidgets(1));
    expect(find.text('Bob Ruiz'), findsAtLeastNWidgets(1));
    expect(find.text('EVALUACIONES CONSIDERADAS'), findsOneWidget);
  });
}

TeacherInsightsInput _buildFullInput() {
  return const TeacherInsightsInput(
    scorePoints: <TeacherInsightsScorePoint>[
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's1',
        studentName: 'Ana Lopez',
        score: 5,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's1',
        studentName: 'Ana Lopez',
        score: 4,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's1',
        studentName: 'Ana Lopez',
        score: 5,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's1',
        studentName: 'Ana Lopez',
        score: 4,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's2',
        studentName: 'Bob Ruiz',
        score: 2,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's2',
        studentName: 'Bob Ruiz',
        score: 3,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's2',
        studentName: 'Bob Ruiz',
        score: 2,
      ),
      TeacherInsightsScorePoint(
        evaluationId: 'e1',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
        groupId: 'g1',
        groupName: 'Equipo Alfa',
        studentId: 's2',
        studentName: 'Bob Ruiz',
        score: 3,
      ),
    ],
    evaluations: <TeacherInsightsEvaluationCoverage>[
      TeacherInsightsEvaluationCoverage(
        evaluationId: 'e1',
        evaluationName: 'Eval Sprint',
        courseId: 'c1',
        courseName: 'Ingenieria de Software',
        categoryId: 'cat1',
        categoryName: 'Sprint 1',
      ),
    ],
  );
}

class _DelayedInsightsRepository extends FakeEvaluationRepository {
  @override
  Future<TeacherInsightsInput> getTeacherInsightsInput(int teacherId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.getTeacherInsightsInput(teacherId);
  }
}
