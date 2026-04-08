import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_course_manage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('TCourseManagePage shows empty state when no courses',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '1',
        name: 'Docente Uno',
        email: 'doc@uni.edu',
        initials: 'DU',
      ),
    );

    final groupRepo = FakeGroupRepository();

    Get.put<TeacherSessionController>(session);
    Get.put<TeacherCourseImportController>(
      TeacherCourseImportController(
        session,
        groupRepo,
        FakeCourseRepository(),
        TeacherImportCsvUseCase(groupRepo),
      ),
    );

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TCourseManagePage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/teacher/dash',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(find.text('Sin cursos creados'), findsOneWidget);
  });
}
