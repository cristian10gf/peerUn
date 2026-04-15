import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_dash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/fake_cache_service.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/new-eval', page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/results',  page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/courses',  page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/profile',  page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/import',   page: () => const SizedBox.shrink()),
];

void _registerControllers({
  required SpyTeacherSessionController session,
  FakeEvaluationRepository? evalRepo,
}) {
  final er = evalRepo ?? FakeEvaluationRepository();
  final gr = FakeGroupRepository();
  final cr = FakeCourseRepository();

  Get.put<TeacherSessionController>(session);
  final importCtrl = TeacherCourseImportController(
    session, gr, cr, TeacherImportCsvUseCase(gr), FakeCacheService(),
  );
  Get.put<TeacherCourseImportController>(importCtrl);
  Get.put<TeacherEvaluationController>(
    TeacherEvaluationController(
      session, importCtrl, er, TeacherCreateEvaluationUseCase(er), FakeCacheService(),
    ),
  );
  Get.put<TeacherResultsController>(TeacherResultsController(er, FakeCacheService()));
}

void main() {
  setUp(resetGetxTestState);

  testWidgets('TDashPage shows teacher name and evaluations section label',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '10', name: 'Docente Uno', email: 'doc@uni.edu', initials: 'DU'),
    );
    _registerControllers(session: session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TDashPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Docente Uno'),     findsOneWidget);
    expect(find.text('MIS EVALUACIONES'), findsOneWidget);
  });

  testWidgets('TDashPage shows empty-evaluations text when list is empty',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '10', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
    );
    _registerControllers(session: session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TDashPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin evaluaciones aún'), findsOneWidget);
  });

  testWidgets('TDashPage shows evaluation cards when evaluations are present',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '10', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
    );
    final er = FakeEvaluationRepository();
    er.evaluations = [
      Evaluation(
        id: 1,
        name: 'Parcial I',
        categoryId: 1,
        categoryName: 'Grupo A',
        hours: 48,
        visibility: 'private',
        createdAt: DateTime(2026, 4, 1),
        closesAt: DateTime(2099, 1, 1),
      ),
    ];
    _registerControllers(session: session, evalRepo: er);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TDashPage(), extraRoutes: _extraRoutes),
    );
    // Use pump instead of pumpAndSettle to avoid timeout from animated cards.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Parcial I'), findsAtLeastNWidgets(1));
  });

  testWidgets('TDashPage Nueva button navigates to /teacher/new-eval',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '10', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
    );
    _registerControllers(session: session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TDashPage(), extraRoutes: _extraRoutes),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The FAB-style button for creating evaluations shows 'Nueva'.
    await tester.tap(find.text('Nueva').first);
    await tester.pumpAndSettle();

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
