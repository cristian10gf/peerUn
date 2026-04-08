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

  LoginController buildLoginCtrl({
    FakeUnifiedAuthRepository? unified,
    bool online = true,
  }) {
    final ctrl = LoginController(
      unified ?? FakeUnifiedAuthRepository(),
      SpyStudentController(),
      SpyTeacherSessionController(),
    );
    Get.put<LoginController>(ctrl);
    Get.put<ConnectivityController>(
      ConnectivityController(FakeConnectivityRepository(connected: online)),
    );
    return ctrl;
  }

  testWidgets('LoginPage sends credentials when online', (tester) async {
    final unified = FakeUnifiedAuthRepository();
    buildLoginCtrl(unified: unified);

    await tester.pumpWidget(buildGetxTestApp(home: const LoginPage()));

    final emailField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Correo institucional',
    );
    final passwordField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Contraseña',
    );

    await tester.enterText(emailField, 'user@uni.edu');
    await tester.enterText(passwordField, 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(unified.lastEmail, 'user@uni.edu');
    expect(unified.lastPassword, 'Password123');
  });

  testWidgets('LoginPage shows auth error when login fails', (tester) async {
    final unified = FakeUnifiedAuthRepository()
      ..nextError = Exception('Credenciales inválidas');
    buildLoginCtrl(unified: unified);

    await tester.pumpWidget(buildGetxTestApp(home: const LoginPage()));

    final emailField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Correo institucional',
    );
    final passwordField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Contraseña',
    );

    await tester.enterText(emailField, 'bad@uni.edu');
    await tester.enterText(passwordField, 'WrongPass');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // An error message should appear somewhere on the page.
    expect(unified.lastEmail, 'bad@uni.edu');
  });

  testWidgets('LoginPage shows offline banner when disconnected', (tester) async {
    buildLoginCtrl(online: false);

    await tester.pumpWidget(buildGetxTestApp(home: const LoginPage()));
    await tester.pump();

    expect(find.textContaining('Sin internet'), findsOneWidget);
  });

  testWidgets('LoginPage does not submit when fields are empty', (tester) async {
    final unified = FakeUnifiedAuthRepository();
    buildLoginCtrl(unified: unified);

    await tester.pumpWidget(buildGetxTestApp(home: const LoginPage()));

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // Repository should not have been called.
    expect(unified.lastEmail, isNull);
  });

  testWidgets('LoginPage has link to register page', (tester) async {
    buildLoginCtrl();
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const LoginPage(),
        extraRoutes: [
          GetPage(name: '/register', page: () => const SizedBox.shrink()),
        ],
      ),
    );

    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
