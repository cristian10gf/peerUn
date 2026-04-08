import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_import_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/courses', page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/dash',    page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/profile', page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/import',  page: () => const SizedBox.shrink()),
];

TeacherCourseImportController _buildCtrl({
  List<GroupCategory> categories = const [],
}) {
  final session = SpyTeacherSessionController();
  session.setTeacherSession(
    const Teacher(id: '10', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
  );
  final gr = FakeGroupRepository()..categories = [...categories];
  final ctrl = TeacherCourseImportController(
    session,
    gr,
    FakeCourseRepository(),
    TeacherImportCsvUseCase(gr),
  );
  Get.put<TeacherSessionController>(session);
  Get.put<TeacherCourseImportController>(ctrl);
  return ctrl;
}

void main() {
  setUp(resetGetxTestState);

  testWidgets('TImportPage shows empty state when no categories exist',
      (tester) async {
    _buildCtrl();
    await tester.pumpWidget(
      buildGetxTestApp(home: const TImportPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin categorías importadas'), findsOneWidget);
  });

  testWidgets('TImportPage shows category card when a category is present',
      (tester) async {
    final cat = GroupCategory(
      id: 1,
      name: 'Grupo IA 2026',
      importedAt: DateTime(2026, 3, 15),
      courseId: 1,
      groups: const [
        CourseGroup(id: 1, name: 'Equipo A', members: []),
        CourseGroup(id: 2, name: 'Equipo B', members: []),
      ],
    );
    final ctrl = _buildCtrl(categories: [cat]);
    // Simulate the category being loaded into the controller's observable.
    ctrl.categories.add(cat);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TImportPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();

    expect(find.text('Grupo IA 2026'), findsOneWidget);
  });

  testWidgets('TImportPage shows import CSV button', (tester) async {
    _buildCtrl();
    await tester.pumpWidget(
      buildGetxTestApp(home: const TImportPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Importar CSV'), findsOneWidget);
  });
}
