import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  test('createEvaluation sets error when course is missing', () async {
    final evalRepo = FakeEvaluationRepository();
    final groupRepo = FakeGroupRepository();
    final courseRepo = FakeCourseRepository();
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '15',
        name: 'Doc',
        email: 'doc@uni.edu',
        initials: 'DO',
      ),
    );

    final importCtrl = TeacherCourseImportController(
      session,
      groupRepo,
      courseRepo,
      TeacherImportCsvUseCase(groupRepo),
    );

    final ctrl = TeacherEvaluationController(
      session,
      importCtrl,
      evalRepo,
      TeacherCreateEvaluationUseCase(evalRepo),
    );

    await ctrl.createEvaluation();

    expect(ctrl.evalError.value, 'Selecciona un curso');
  });
}
