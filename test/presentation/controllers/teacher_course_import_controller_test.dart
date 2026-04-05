import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/repository_fakes.dart';

void main() {
  test('createCourse inserts new course at top and returns true', () async {
    final courseRepo = FakeCourseRepository();
    final groupRepo = FakeGroupRepository();
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '10',
        name: 'Doc',
        email: 'doc@uni.edu',
        initials: 'DO',
      ),
    );

    final ctrl = TeacherCourseImportController(
      session,
      groupRepo,
      courseRepo,
      TeacherImportCsvUseCase(groupRepo),
    );

    final ok = await ctrl.createCourse('Arquitectura', 'ARQ-01');

    expect(ok, true);
    expect(ctrl.courses.first.name, 'Arquitectura');
  });
}
