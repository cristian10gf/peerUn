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

void main() {
  setUp(resetGetxTestState);

  testWidgets('RegisterPage validates local fields before submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final studentCtrl = SpyStudentController();
    final teacherCtrl = SpyTeacherSessionController();
    final connectivity = ConnectivityController(
      FakeConnectivityRepository(connected: true),
    );

    Get.put<StudentController>(studentCtrl);
    Get.put<TeacherSessionController>(teacherCtrl);
    Get.put<ConnectivityController>(connectivity);

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
}
