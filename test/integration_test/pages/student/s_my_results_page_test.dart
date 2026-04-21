import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_my_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/getx_test_harness.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/student/courses', page: () => const SizedBox.shrink()),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  testWidgets('SMyResultsPage shows average card and criterion breakdown',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.myResults.addAll(const <CriterionResult>[
      CriterionResult(label: 'Puntualidad',    value: 4.5),
      CriterionResult(label: 'Contribuciones', value: 4.0),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Mis resultados'),       findsOneWidget);
    expect(find.text('DESGLOSE POR CRITERIO'), findsOneWidget);
  });

  testWidgets('SMyResultsPage shows criterion labels when results are present',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.myResults.addAll(const <CriterionResult>[
      CriterionResult(label: 'Puntualidad',    value: 4.2),
      CriterionResult(label: 'Contribuciones', value: 3.8),
      CriterionResult(label: 'Compromiso',     value: 4.5),
      CriterionResult(label: 'Actitud',        value: 5.0),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Puntualidad'),    findsOneWidget);
    expect(find.text('Contribuciones'), findsOneWidget);
    expect(find.text('Compromiso'),     findsOneWidget);
    expect(find.text('Actitud'),        findsOneWidget);
  });

  testWidgets('SMyResultsPage shows eval name and visibility in subtitle',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.activeEvalDb.value = Evaluation(
      id: 3,
      name: 'Entrega Final',
      categoryId: 1,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'public',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.textContaining('Entrega Final'),      findsOneWidget);
    expect(find.textContaining('Visibilidad pública'), findsOneWidget);
  });

  testWidgets('SMyResultsPage shows "Sin evaluación" subtitle when no eval',
      (tester) async {
    final ctrl = SpyStudentController();
    // activeEvalDb.value is null by default in SpyStudentController.

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Sin evaluación'), findsOneWidget);
  });

  testWidgets('SMyResultsPage shows loading indicator while loading results',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.isLoadingMyResults.value = true;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SMyResultsPage shows error state when loading fails',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.myResultsError.value = 'Fallo de red';

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.text('No se pudieron cargar tus resultados'), findsOneWidget);
    expect(find.text('Fallo de red'), findsOneWidget);
  });

  testWidgets('SMyResultsPage pull-to-refresh triggers refreshMyResults',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.myResults.addAll(const <CriterionResult>[
      CriterionResult(label: 'Puntualidad', value: 4.2),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SMyResultsPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(ctrl.refreshMyResultsCalls, 1);
  });
}
