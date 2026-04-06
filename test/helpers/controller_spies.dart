import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

import 'repository_fakes.dart';

class SpyStudentController extends StudentController {
  bool activateSessionCalled = false;
  bool clearSessionStateCalled = false;
  bool logoutCalled = false;

  SpyStudentController({
    IAuthRepository? authRepository,
    IEvaluationRepository? evaluationRepository,
  }) : super(
          authRepository ?? FakeAuthRepository(),
          evaluationRepository ?? FakeEvaluationRepository(),
        );

  @override
  Future<void> activateSessionFromLogin() async {
    activateSessionCalled = true;
  }

  @override
  void clearSessionStateForRoleSwitch() {
    clearSessionStateCalled = true;
    super.clearSessionStateForRoleSwitch();
  }

  @override
  Future<void> loadEvalData() async {
    // No-op for deterministic tests.
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    student.value = null;
  }

  void setStudentSession(Student value) {
    student.value = value;
  }
}

class SpyTeacherSessionController extends TeacherSessionController {
  bool activateSessionCalled = false;
  bool clearSessionStateCalled = false;
  bool logoutCalled = false;

  SpyTeacherSessionController({ITeacherAuthRepository? authRepository})
      : super(authRepository ?? FakeTeacherAuthRepository());

  @override
  Future<void> activateSessionFromLogin() async {
    activateSessionCalled = true;
  }

  @override
  void clearSessionStateForRoleSwitch() {
    clearSessionStateCalled = true;
    super.clearSessionStateForRoleSwitch();
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    teacher.value = null;
  }

  void setTeacherSession(Teacher value) {
    teacher.value = value;
  }
}
