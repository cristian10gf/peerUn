import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/services/i_cache_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

import 'fake_cache_service.dart';
import 'repository_fakes.dart';

class SpyStudentController extends StudentController {
  bool activateSessionCalled = false;
  bool clearSessionStateCalled = false;
  bool logoutCalled = false;
  int refreshMyResultsCalls = 0;

  SpyStudentController({
    IAuthRepository? authRepository,
    IEvaluationRepository? evaluationRepository,
    ICacheService? cacheService,
  }) : super(
          authRepository ?? FakeAuthRepository(),
          evaluationRepository ?? FakeEvaluationRepository(),
          cacheService ?? FakeCacheService(),
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
  Future<void> refreshMyResults() async {
    refreshMyResultsCalls++;
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
