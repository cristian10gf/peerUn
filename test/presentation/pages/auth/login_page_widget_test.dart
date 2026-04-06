import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/login_controller.dart';
import 'package:example/presentation/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('LoginPage sends credentials when online', (tester) async {
    final unified = FakeUnifiedAuthRepository();
    final loginCtrl = LoginController(
      unified,
      SpyStudentController(),
      SpyTeacherSessionController(),
    );
    final connectivity = ConnectivityController(
      FakeConnectivityRepository(connected: true),
    );

    Get.put<LoginController>(loginCtrl);
    Get.put<ConnectivityController>(connectivity);

    await tester.pumpWidget(buildGetxTestApp(home: const LoginPage()));

    final emailField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Correo institucional',
    );
    final passwordField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Contraseña',
    );

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);

    await tester.enterText(emailField, 'user@uni.edu');
    await tester.enterText(passwordField, 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(unified.lastEmail, 'user@uni.edu');
    expect(unified.lastPassword, 'Password123');
  });
}
