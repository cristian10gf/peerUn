import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_dash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('TDashPage shows teacher name and evaluations section', (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '10',
        name: 'Docente Uno',
        email: 'doc@uni.edu',
        initials: 'DU',
      ),
    );

    final evalRepo = FakeEvaluationRepository();
    final groupRepo = FakeGroupRepository();
    final courseRepo = FakeCourseRepository();

    Get.put<TeacherSessionController>(session);
    Get.put<TeacherCourseImportController>(
      TeacherCourseImportController(
        session,
        groupRepo,
        courseRepo,
        TeacherImportCsvUseCase(groupRepo),
      ),
    );
    Get.put<TeacherEvaluationController>(
      TeacherEvaluationController(
        session,
        Get.find<TeacherCourseImportController>(),
        evalRepo,
        TeacherCreateEvaluationUseCase(evalRepo),
      ),
    );
    Get.put<TeacherResultsController>(TeacherResultsController(evalRepo));

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TDashPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/teacher/new-eval',
            page: () => const SizedBox.shrink(),
          ),
          GetPage<dynamic>(
            name: '/teacher/results',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Docente Uno'), findsOneWidget);
    expect(find.text('MIS EVALUACIONES'), findsOneWidget);
  });
}
