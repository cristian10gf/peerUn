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
import '../../../helpers/fake_cache_service.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/dash', page: () => const SizedBox.shrink()),
];

({
  SpyTeacherSessionController session,
  FakeEvaluationRepository evalRepo,
  TeacherEvaluationController evalCtrl,
}) _setup() {
  final session = SpyTeacherSessionController();
  session.setTeacherSession(
    const Teacher(id: '10', name: 'Docente', email: 'doc@uni.edu', initials: 'D'),
  );
  final er = FakeEvaluationRepository();
  final gr = FakeGroupRepository();
  final cr = FakeCourseRepository();

  final importCtrl = TeacherCourseImportController(
    session, gr, cr, TeacherImportCsvUseCase(gr), FakeCacheService(),
  );
  final evalCtrl = TeacherEvaluationController(
    session, importCtrl, er, TeacherCreateEvaluationUseCase(er), FakeCacheService(),
  );

  Get.put<TeacherSessionController>(session);
  Get.put<TeacherCourseImportController>(importCtrl);
  Get.put<TeacherEvaluationController>(evalCtrl);

  return (session: session, evalRepo: er, evalCtrl: evalCtrl);
}

void main() {
  setUp(resetGetxTestState);

  testWidgets('TNewEvalPage renders section labels and launch button',
      (tester) async {
    _setup();
    await tester.pumpWidget(
      buildGetxTestApp(home: const TNewEvalPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva evaluación'), findsOneWidget);
    expect(find.text('Lanzar evaluación'), findsOneWidget);
  });

  testWidgets('TNewEvalPage shows error message when evalError is set',
      (tester) async {
    final (:evalCtrl, :session, :evalRepo) = _setup();

    await tester.pumpWidget(
      buildGetxTestApp(home: const TNewEvalPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    evalCtrl.evalError.value = 'Ya existe una evaluación con ese nombre';
    await tester.pump();

    expect(find.text('Ya existe una evaluación con ese nombre'), findsOneWidget);
  });

  testWidgets('TNewEvalPage shows no-courses placeholder when courses list is empty',
      (tester) async {
    _setup();
    await tester.pumpWidget(
      buildGetxTestApp(home: const TNewEvalPage(), extraRoutes: _extraRoutes),
    );
    await tester.pumpAndSettle();

    // When no courses exist the picker shows a disabled placeholder.
    expect(find.textContaining('Sin cursos'), findsOneWidget);
  });
}
