import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_cache_service.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  test('checkSession hydrates student and toggles loading', () async {
    final auth = FakeAuthRepository()
      ..session = const Student(
        id: '99',
        name: 'Ana Perez',
        email: 'ana@uni.edu',
        initials: 'AP',
      );

    final ctrl = StudentController(auth, FakeEvaluationRepository(), FakeCacheService());
    await ctrl.checkSession();

    expect(ctrl.isLoading.value, false);
    expect(ctrl.student.value?.email, 'ana@uni.edu');
    expect(ctrl.isLoggedIn, true);
  });

  test('clearSessionStateForRoleSwitch resets auth + evaluation state', () {
    final ctrl = StudentController(FakeAuthRepository(), FakeEvaluationRepository(), FakeCacheService());

    ctrl.authError.value = 'x';
    ctrl.evalLoadError.value = 'y';
    ctrl.homeCourses.add(
      const StudentHomeCourse(
        id: 1,
        name: 'Arquitectura',
        hasGroupAssignment: true,
        categories: <StudentHomeCategory>[],
      ),
    );

    ctrl.clearSessionStateForRoleSwitch();

    expect(ctrl.authError.value, '');
    expect(ctrl.evalLoadError.value, '');
    expect(ctrl.homeCourses, isEmpty);
    expect(ctrl.student.value, isNull);
  });
}
