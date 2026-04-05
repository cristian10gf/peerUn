import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_my_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SMyResultsPage shows average card and criterion breakdown',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.myResults.addAll(
      const <CriterionResult>[
        CriterionResult(label: 'Puntualidad', value: 4.5),
        CriterionResult(label: 'Contribuciones', value: 4.0),
      ],
    );

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const SMyResultsPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/student/courses',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(find.text('Mis resultados'), findsOneWidget);
    expect(find.text('DESGLOSE POR CRITERIO'), findsOneWidget);
  });
}
