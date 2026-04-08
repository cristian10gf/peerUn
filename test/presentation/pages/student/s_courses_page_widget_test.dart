import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SCoursesPage renders student name and active evaluation section',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(
        id: '5',
        name: 'Ana Perez',
        email: 'ana@uni.edu',
        initials: 'AP',
      ),
    );
    ctrl.evaluations.add(
      Evaluation(
        id: 1,
        name: 'Sprint Review',
        categoryId: 10,
        categoryName: 'Sprint',
        hours: 24,
        visibility: 'private',
        createdAt: DateTime(2026, 4, 1),
        closesAt: DateTime(2099, 1, 1),
      ),
    );

    Get.put<StudentController>(ctrl);

    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));

    expect(find.text('Ana Perez'), findsOneWidget);
    expect(find.text('EVALUACIONES ACTIVAS'), findsOneWidget);
  });
}
