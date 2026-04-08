import 'package:example/domain/models/student.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_profile_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SProfilePage shows student data and logout action', (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(
        id: '9',
        name: 'Ana Perez',
        email: 'ana@uni.edu',
        initials: 'AP',
      ),
    );

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SProfilePage()));

    expect(find.text('Ana Perez'), findsOneWidget);

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(ctrl.logoutCalled, true);
  });
}
