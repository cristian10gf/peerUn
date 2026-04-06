import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/repositories/teacher_auth_repository_impl.dart';
import 'package:example/data/repositories/unified_auth_repository_impl.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/login_controller.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/fake_database_service_level3.dart';
import '../../helpers/getx_test_harness.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('level3: login navigates using real controller + repository chain',
      (tester) async {
    final db = FakeDatabaseServiceLevel3();

    final studentCtrl = StudentController(
      AuthRepositoryImpl(db),
      EvaluationRepositoryImpl(db),
    );
    final teacherCtrl = TeacherSessionController(TeacherAuthRepositoryImpl(db));

    final loginCtrl = LoginController(
      UnifiedAuthRepositoryImpl(db),
      studentCtrl,
      teacherCtrl,
    );

    Get.put<StudentController>(studentCtrl);
    Get.put<TeacherSessionController>(teacherCtrl);
    Get.put<LoginController>(loginCtrl);
    Get.put<ConnectivityController>(
      ConnectivityController(FakeConnectivityRepository(connected: true)),
    );

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const LoginPage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/teacher/dash',
            page: () => const Scaffold(body: Text('Teacher Home Stub')),
          ),
        ],
      ),
    );

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'teacher@uni.edu');
    await tester.enterText(textFields.at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Teacher Home Stub'), findsOneWidget);
    expect(db.savedTeacherSession, isNotNull);
  });
}
