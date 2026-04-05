import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/controllers/login_controller.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  test('login controller can be instantiated with shared doubles', () {
    final unified = FakeUnifiedAuthRepository();
    final student = SpyStudentController();
    final teacher = SpyTeacherSessionController();

    final ctrl = LoginController(unified, student, teacher);

    expect(ctrl.authError.value, '');
    expect(ctrl.isLoading.value, false);
  });
}
