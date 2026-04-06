import 'package:example/domain/models/teacher.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/repository_fakes.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  test('register success stores teacher session and clears loading', () async {
    final repo = FakeTeacherAuthRepository()
      ..registerResult = const Teacher(
        id: '10',
        name: 'Doc',
        email: 'doc@uni.edu',
        initials: 'DO',
      );
    final ctrl = TeacherSessionController(repo);

    await ctrl.register('Doc', 'doc@uni.edu', 'Password123');

    expect(ctrl.teacher.value?.email, 'doc@uni.edu');
    expect(ctrl.isLoading.value, false);
    expect(ctrl.authError.value, '');
  });
}
