import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/pages/teacher/t_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('TResultsPage shows empty overview state', (tester) async {
    Get.put<TeacherResultsController>(
      TeacherResultsController(FakeEvaluationRepository()),
    );

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TResultsPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/teacher/dash',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(find.text('Sin respuestas aún'), findsOneWidget);
  });
}
