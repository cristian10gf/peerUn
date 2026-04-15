import 'package:example/domain/models/evaluation.dart' as eval_model show Evaluation;
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/fake_cache_service.dart';
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
      FakeCacheService(),
    );

    final ctrl = TeacherEvaluationController(
      session,
      importCtrl,
      evalRepo,
      TeacherCreateEvaluationUseCase(evalRepo),
      FakeCacheService(),
    );

    await ctrl.createEvaluation();

    expect(ctrl.evalError.value, 'Selecciona un curso');
  });

  test('renameEvaluation sets evalError on repository failure', () async {
    final evalRepo = FakeEvaluationRepository();
    evalRepo.evaluations = [
      eval_model.Evaluation(
        id: 1,
        name: 'Sprint 1',
        categoryId: 10,
        categoryName: 'Grupo A',
        courseName: '',
        hours: 48,
        visibility: 'private',
        createdAt: DateTime(2026, 1, 1),
        closesAt: DateTime(2026, 1, 3),
      ),
    ];
    evalRepo.renameError = Exception('Network error');

    final groupRepo = FakeGroupRepository();
    final courseRepo = FakeCourseRepository();
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '15', name: 'Doc', email: 'doc@uni.edu', initials: 'DO'),
    );

    final importCtrl = TeacherCourseImportController(
      session,
      groupRepo,
      courseRepo,
      TeacherImportCsvUseCase(groupRepo),
      FakeCacheService(),
    );
    final ctrl = TeacherEvaluationController(
      session,
      importCtrl,
      evalRepo,
      TeacherCreateEvaluationUseCase(evalRepo),
      FakeCacheService(),
    );
    await ctrl.loadEvaluations();

    await ctrl.renameEvaluation(1, 'Sprint 1 v2');

    expect(ctrl.evalError.value, isNotEmpty,
        reason: 'evalError must be set when rename fails');
    expect(ctrl.evaluations.first.name, 'Sprint 1',
        reason: 'In-memory state must stay unchanged on failure');
  });

  test('deleteEvaluation sets evalError on repository failure', () async {
    final evalRepo = FakeEvaluationRepository();
    evalRepo.evaluations = [
      eval_model.Evaluation(
        id: 2,
        name: 'Sprint 2',
        categoryId: 10,
        categoryName: 'Grupo A',
        courseName: '',
        hours: 48,
        visibility: 'private',
        createdAt: DateTime(2026, 1, 1),
        closesAt: DateTime(2026, 1, 3),
      ),
    ];
    evalRepo.deleteError = Exception('DB locked');

    final groupRepo = FakeGroupRepository();
    final courseRepo = FakeCourseRepository();
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '15', name: 'Doc', email: 'doc@uni.edu', initials: 'DO'),
    );

    final importCtrl = TeacherCourseImportController(
      session,
      groupRepo,
      courseRepo,
      TeacherImportCsvUseCase(groupRepo),
      FakeCacheService(),
    );
    final ctrl = TeacherEvaluationController(
      session,
      importCtrl,
      evalRepo,
      TeacherCreateEvaluationUseCase(evalRepo),
      FakeCacheService(),
    );
    await ctrl.loadEvaluations();

    await ctrl.deleteEvaluation(2);

    expect(ctrl.evalError.value, isNotEmpty,
        reason: 'evalError must be set when delete fails');
    expect(ctrl.evaluations.length, 1,
        reason: 'In-memory list must stay unchanged on failure');
  });
}
