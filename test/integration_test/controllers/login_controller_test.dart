import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/presentation/controllers/login_controller.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/controller_spies.dart';
import '../helpers/repository_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  test('login controller can be instantiated with shared doubles', () {
    final unified = FakeUnifiedAuthRepository();
    final student = SpyStudentController();
    final teacher = SpyTeacherSessionController();

    final ctrl = LoginController(unified, student, teacher);

    expect(ctrl.authError.value, '');
    expect(ctrl.isLoading.value, false);
  });

  test('login with teacher role clears student and activates teacher session',
      () async {
    final unified = FakeUnifiedAuthRepository()
      ..nextResult = const AuthLoginResult(role: AppUserRole.teacher);
    final student = SpyStudentController();
    final teacher = SpyTeacherSessionController();

    final ctrl = LoginController(unified, student, teacher);
    await ctrl.login('docente@uni.edu', 'Password123');

    expect(student.clearSessionStateCalled, true);
    expect(teacher.activateSessionCalled, true);
    expect(ctrl.authError.value, '');
  });

  test('empty email or password sets authError and skips repository call',
      () async {
    final unified = FakeUnifiedAuthRepository();
    final ctrl = LoginController(
      unified,
      SpyStudentController(),
      SpyTeacherSessionController(),
    );

    await ctrl.login('', '');

    expect(ctrl.authError.value, 'Completa todos los campos');
    expect(unified.lastEmail, isNull);
  });
}
