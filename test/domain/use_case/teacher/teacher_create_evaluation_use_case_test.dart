import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/repository_fakes.dart';

void main() {
  test('execute trims name and creates evaluation', () async {
    final repo = FakeEvaluationRepository();
    final useCase = TeacherCreateEvaluationUseCase(repo);

    final eval = await useCase.execute(
      const TeacherCreateEvaluationInput(
        name: '  Sprint Demo  ',
        categoryId: 10,
        hours: 24,
        visibility: 'private',
        teacherId: 7,
      ),
    );

    expect(eval.name, 'Sprint Demo');
    expect(repo.evaluations.first.name, 'Sprint Demo');
  });
}
