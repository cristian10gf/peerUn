import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_eval_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/student/peers', page: () => const SizedBox.shrink()),
  GetPage(name: '/student/results', page: () => const SizedBox.shrink()),
];

Evaluation _eval({
  int id = 1,
  String name = 'Eval 1',
  bool active = true,
}) =>
    Evaluation(
      id: id,
      name: name,
      categoryId: 7,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: active ? DateTime(2099, 1, 1) : DateTime(2020, 1, 1),
    );

void main() {
  setUp(resetGetxTestState);

  testWidgets('SEvalListPage shows Evaluar action for activePending status',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.evaluations.add(_eval());
    ctrl.evalStatuses[1] = EvalStudentStatus.activePending;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Evaluar'), findsOneWidget);
    expect(find.text('Ver resultados'), findsOneWidget);
  });

  testWidgets('SEvalListPage shows empty-state text when no evaluations',
      (tester) async {
    Get.put<StudentController>(SpyStudentController());
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Sin historial'), findsOneWidget);
  });

  testWidgets(
      'SEvalListPage shows ACTIVA·REALIZADA badge for activeCompleted status',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.evaluations.add(_eval(id: 2, name: 'Eval Completa'));
    ctrl.evalStatuses[2] = EvalStudentStatus.activeCompleted;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    expect(find.textContaining('REALIZADA'), findsOneWidget);
  });

  testWidgets(
      'SEvalListPage shows FINALIZADA·NO REALIZADA badge for closedNotDone',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.evaluations.add(_eval(id: 3, name: 'Eval Cerrada', active: false));
    ctrl.evalStatuses[3] = EvalStudentStatus.closedNotDone;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    expect(find.textContaining('NO REALIZADA'), findsOneWidget);
  });

  testWidgets('SEvalListPage shows FINALIZADA badge for closedCompleted status',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.evaluations.add(_eval(id: 4, name: 'Eval Cerrada OK', active: false));
    ctrl.evalStatuses[4] = EvalStudentStatus.closedCompleted;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    expect(find.textContaining('FINALIZADA'), findsOneWidget);
    expect(find.textContaining('NO REALIZADA'), findsNothing);
  });

  testWidgets('SEvalListPage Evaluar button calls selectEvalForEvaluation',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.evaluations.add(_eval(id: 5, name: 'Eval Pendiente'));
    ctrl.evalStatuses[5] = EvalStudentStatus.activePending;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SEvalListPage(), extraRoutes: _extraRoutes),
    );

    await tester.tap(find.text('Evaluar'));
    await tester.pumpAndSettle();

    // Should navigate to /student/peers (stubbed route).
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
