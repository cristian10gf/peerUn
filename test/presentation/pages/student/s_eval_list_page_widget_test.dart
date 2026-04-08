import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_eval_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SEvalListPage shows Evaluar action for activePending status',
      (tester) async {
    final ctrl = SpyStudentController();
    final eval = Evaluation(
      id: 1,
      name: 'Eval 1',
      categoryId: 7,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    ctrl.evaluations.add(eval);
    ctrl.evalStatuses[1] = EvalStudentStatus.activePending;

    Get.put<StudentController>(ctrl);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const SEvalListPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/student/peers',
            page: () => const SizedBox.shrink(),
          ),
          GetPage<dynamic>(
            name: '/student/results',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(find.text('Evaluar'), findsOneWidget);
    expect(find.text('Ver resultados'), findsOneWidget);
  });
}
