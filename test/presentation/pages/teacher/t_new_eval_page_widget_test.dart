import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_new_eval_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('TNewEvalPage renders launch button and section labels',
      (tester) async {
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

    final importCtrl = TeacherCourseImportController(
      session,
      groupRepo,
      courseRepo,
      TeacherImportCsvUseCase(groupRepo),
    );

    final evalCtrl = TeacherEvaluationController(
      session,
      importCtrl,
      evalRepo,
      TeacherCreateEvaluationUseCase(evalRepo),
    );

    Get.put<TeacherSessionController>(session);
    Get.put<TeacherCourseImportController>(importCtrl);
    Get.put<TeacherEvaluationController>(evalCtrl);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TNewEvalPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/teacher/dash',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva evaluación'), findsOneWidget);
    expect(find.text('Lanzar evaluación'), findsOneWidget);
  });
}
