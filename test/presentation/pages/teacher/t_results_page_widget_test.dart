import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/pages/teacher/t_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/dash', page: () => const SizedBox.shrink()),
];

void main() {
  setUp(resetGetxTestState);

  testWidgets('TResultsPage shows empty overview state', (tester) async {
    Get.put<TeacherResultsController>(
      TeacherResultsController(FakeEvaluationRepository()),
    );

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Sin respuestas aún'), findsOneWidget);
  });

  testWidgets('TResultsPage shows group names when results are loaded',
      (tester) async {
    final er = FakeEvaluationRepository();
    er.groupResults = const [
      GroupResult(
        name: 'Equipo Alfa',
        average: 4.2,
        criteria: [4.0, 4.5, 4.0, 4.3],
        students: [],
      ),
      GroupResult(
        name: 'Equipo Beta',
        average: 3.8,
        criteria: [3.5, 4.0, 3.8, 3.9],
        students: [],
      ),
    ];

    final ctrl = TeacherResultsController(er);
    Get.put<TeacherResultsController>(ctrl);

    // Simulate results already loaded (bypass the real async load).
    ctrl.groupResults.assignAll(er.groupResults);
    ctrl.selectedEval.value = Evaluation(
      id: 1,
      name: 'Sprint Review',
      categoryId: 1,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.text('Equipo Alfa'), findsOneWidget);
    expect(find.text('Equipo Beta'), findsOneWidget);
  });

  testWidgets('TResultsPage opens detail panel when tapping a group card',
      (tester) async {
    final er = FakeEvaluationRepository();
    er.groupResults = const [
      GroupResult(
        name: 'Equipo Alfa',
        average: 4.2,
        criteria: [4.0, 4.5, 4.0, 4.3],
        students: [],
      ),
      GroupResult(
        name: 'Equipo Beta',
        average: 3.8,
        criteria: [3.5, 4.0, 3.8, 3.9],
        students: [],
      ),
    ];

    final ctrl = TeacherResultsController(er);
    Get.put<TeacherResultsController>(ctrl);

    ctrl.groupResults.assignAll(er.groupResults);
    ctrl.selectedEval.value = Evaluation(
      id: 1,
      name: 'Sprint Review',
      categoryId: 1,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.byKey(const Key('results-overview-panel')), findsOneWidget);
    expect(find.byKey(const Key('results-detail-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('results-group-card-0')));
    await tester.pump();

    expect(find.byKey(const Key('results-detail-panel')), findsOneWidget);
    expect(find.text('ESTUDIANTES'), findsOneWidget);
  });

  testWidgets('TResultsPage back button closes detail and returns to overview',
      (tester) async {
    final er = FakeEvaluationRepository();
    er.groupResults = const [
      GroupResult(
        name: 'Equipo Alfa',
        average: 4.2,
        criteria: [4.0, 4.5, 4.0, 4.3],
        students: [],
      ),
      GroupResult(
        name: 'Equipo Beta',
        average: 3.8,
        criteria: [3.5, 4.0, 3.8, 3.9],
        students: [],
      ),
    ];

    final ctrl = TeacherResultsController(er);
    Get.put<TeacherResultsController>(ctrl);

    ctrl.groupResults.assignAll(er.groupResults);
    ctrl.selectedEval.value = Evaluation(
      id: 1,
      name: 'Sprint Review',
      categoryId: 1,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('results-group-card-0')));
    await tester.pump();

    expect(find.byKey(const Key('results-detail-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('results-back-button')));
    await tester.pump();

    expect(find.byKey(const Key('results-overview-panel')), findsOneWidget);
    expect(find.byKey(const Key('results-detail-panel')), findsNothing);
  });

  testWidgets('TResultsPage header shows Resultados when not drilling',
      (tester) async {
    Get.put<TeacherResultsController>(
      TeacherResultsController(FakeEvaluationRepository()),
    );

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Resultados'), findsOneWidget);
  });

  testWidgets('TResultsPage shows loading indicator while loading', (tester) async {
    final ctrl = TeacherResultsController(FakeEvaluationRepository());
    Get.put<TeacherResultsController>(ctrl);
    ctrl.resultsLoading.value = true;

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TResultsPage shows error card when resultsError is set',
      (tester) async {
    final er = FakeEvaluationRepository();
    er.groupResults = const [
      GroupResult(
        name: 'Equipo Alfa',
        average: 4.2,
        criteria: [4.0, 4.5, 4.0, 4.3],
        students: [],
      ),
    ];

    final ctrl = TeacherResultsController(er);
    Get.put<TeacherResultsController>(ctrl);

    ctrl.groupResults.assignAll(er.groupResults);
    ctrl.resultsError.value = 'Fallo de red';

    await tester.pumpWidget(
      buildGetxTestApp(home: const TResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.text('No se pudieron cargar los resultados'), findsOneWidget);
    expect(find.text('Fallo de red'), findsOneWidget);
    expect(find.text('Equipo Alfa'), findsNothing);
  });
}
