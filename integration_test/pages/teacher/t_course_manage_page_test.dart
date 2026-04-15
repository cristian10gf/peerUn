import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_course_manage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/fake_cache_service.dart';
import '../../helpers/getx_test_harness.dart';
import '../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/dash',    page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/import',  page: () => const SizedBox.shrink()),
];

TeacherCourseImportController _buildCtrl({List<CourseModel> courses = const []}) {
  final session = SpyTeacherSessionController();
  session.setTeacherSession(
    const Teacher(id: '1', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
  );
  final gr = FakeGroupRepository();
  final cr = FakeCourseRepository()..courses = [...courses];
  final ctrl = TeacherCourseImportController(
    session, gr, cr, TeacherImportCsvUseCase(gr), FakeCacheService(),
  );
  Get.put<TeacherSessionController>(session);
  Get.put<TeacherCourseImportController>(ctrl);
  return ctrl;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  testWidgets('TCourseManagePage shows empty state when no courses',
      (tester) async {
    _buildCtrl();
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TCourseManagePage(),
        extraRoutes: _extraRoutes,
      ),
    );

    expect(find.text('Sin cursos creados'), findsOneWidget);
  });

  testWidgets('TCourseManagePage shows course cards when courses present',
      (tester) async {
    final course = CourseModel(
      id: 1,
      teacherId: 1,
      name: 'Ingeniería de Software',
      code: 'IS101',
      createdAt: DateTime(2026, 1, 1),
    );
    final ctrl = _buildCtrl(courses: [course]);
    ctrl.courses.add(course);

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TCourseManagePage(),
        extraRoutes: _extraRoutes,
      ),
    );
    await tester.pump();

    expect(find.text('Ingeniería de Software'), findsOneWidget);
  });

  testWidgets('TCourseManagePage shows create course button', (tester) async {
    _buildCtrl();
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const TCourseManagePage(),
        extraRoutes: _extraRoutes,
      ),
    );

    expect(find.text('Nuevo'), findsOneWidget);
  });
}
