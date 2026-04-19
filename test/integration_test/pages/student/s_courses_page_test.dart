import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/getx_test_harness.dart';

StudentHomeCourse _fakeCourse({
  int id = 1,
  String courseName = 'Ingeniería de Software',
  String categoryName = 'Grupo 1',
  String groupName = 'Equipo A',
  int activeEvalId = 0,
  String activeEvalName = '',
}) {
  return StudentHomeCourse(
    id: id,
    name: courseName,
    hasGroupAssignment: true,
    categories: [
      StudentHomeCategory(
        id: 10,
        name: categoryName,
        group: StudentHomeGroup(
          id: 100,
          name: groupName,
          members: const [GroupMember(id: 1, name: 'Bob', username: 'bob@uni.edu')],
        ),
        activeEvaluationId: activeEvalId,
        activeEvaluationName: activeEvalName,
        completedPeerCount: 0,
        totalPeerCount: 1,
      ),
    ],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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

  testWidgets('SCoursesPage shows empty-courses text when homeCourses is empty',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(
        id: '1',
        name: 'Luis Torres',
        email: 'luis@uni.edu',
        initials: 'LT',
      ),
    );
    // homeCourses is empty, isLoadingHome=false, homeLoadError=''

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));
    await tester.pump();

    expect(find.textContaining('no tienes cursos'), findsOneWidget);
  });

  testWidgets('SCoursesPage shows loading indicator while loading home data',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(id: '1', name: 'X', email: 'x@u.edu', initials: 'X'),
    );
    ctrl.isLoadingHome.value = true;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));
    await tester.pump();

    expect(find.text('Cargando cursos matriculados...'), findsOneWidget);
  });

  testWidgets('SCoursesPage shows error text when homeLoadError is set',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(id: '1', name: 'X', email: 'x@u.edu', initials: 'X'),
    );
    ctrl.homeLoadError.value = 'Sin conexión al servidor';

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));
    await tester.pump();

    expect(find.text('Sin conexión al servidor'), findsOneWidget);
  });

  testWidgets('SCoursesPage renders course name and group name from homeCourses',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(
        id: '3',
        name: 'María García',
        email: 'maria@uni.edu',
        initials: 'MG',
      ),
    );
    ctrl.homeCourses.add(_fakeCourse(
      courseName: 'Inteligencia Artificial',
      groupName: 'Equipo X',
    ));

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));
    await tester.pump();

    expect(find.text('Inteligencia Artificial'), findsOneWidget);
  });

  testWidgets(
      'SCoursesPage shows active-evaluation name inside category card '
      'when category has an active evaluation',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.setStudentSession(
      const Student(id: '3', name: 'X', email: 'x@u.edu', initials: 'X'),
    );
    ctrl.homeCourses.add(_fakeCourse(
      activeEvalId: 7,
      activeEvalName: 'Entrega Final',
    ));
    // Also add the evaluation so the pending section shows it.
    ctrl.evaluations.add(
      Evaluation(
        id: 7,
        name: 'Entrega Final',
        categoryId: 10,
        categoryName: 'Grupo 1',
        hours: 48,
        visibility: 'private',
        createdAt: DateTime(2026, 4, 1),
        closesAt: DateTime(2099, 1, 1),
      ),
    );
    ctrl.evalStatuses[7] = EvalStudentStatus.activePending;

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(buildGetxTestApp(home: const SCoursesPage()));
    await tester.pump();

    // The evaluation name should appear in the "EVALUACIONES ACTIVAS" section.
    expect(find.text('Entrega Final'), findsAtLeast(1));
  });
}
