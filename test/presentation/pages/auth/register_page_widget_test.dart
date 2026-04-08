import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';
import '../../../helpers/repository_fakes.dart';

void _setup({bool online = true}) {
  Get.put<StudentController>(SpyStudentController());
  Get.put<TeacherSessionController>(SpyTeacherSessionController());
  Get.put<ConnectivityController>(
    ConnectivityController(FakeConnectivityRepository(connected: online)),
  );
}

const _smallSurface = Size(900, 1200);

void main() {
  setUp(resetGetxTestState);

  testWidgets('RegisterPage validates local fields before submit',
      (tester) async {
    await tester.binding.setSurfaceSize(_smallSurface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    _setup();
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(0.9)),
          child: RegisterPage(),
        ),
      ),
    );

    await tester.tap(find.text('Crear cuenta de estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Completa todos los campos'), findsOneWidget);
  });

  testWidgets('RegisterPage calls register when all fields filled',
      (tester) async {
    await tester.binding.setSurfaceSize(_smallSurface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final studentCtrl = SpyStudentController();
    Get.put<StudentController>(studentCtrl);
    Get.put<TeacherSessionController>(SpyTeacherSessionController());
    Get.put<ConnectivityController>(
      ConnectivityController(FakeConnectivityRepository(connected: true)),
    );

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(0.9)),
          child: RegisterPage(),
        ),
        extraRoutes: [
          GetPage(
            name: '/student/courses',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    // Fill name, email, password, confirm fields.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Pérez');
    await tester.enterText(fields.at(1), 'ana@uni.edu');
    await tester.enterText(fields.at(2), 'Password123');
    await tester.enterText(fields.at(3), 'Password123');

    await tester.tap(find.text('Crear cuenta de estudiante'));
    await tester.pumpAndSettle();

    // The fake register result navigates to /student/courses.
    expect(find.text('Completa todos los campos'), findsNothing);
  });

  testWidgets('RegisterPage shows offline banner when disconnected',
      (tester) async {
    await tester.binding.setSurfaceSize(_smallSurface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    _setup(online: false);
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(0.9)),
          child: RegisterPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Sin internet'), findsOneWidget);
  });
}
