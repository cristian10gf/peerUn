import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('execute trims name and creates evaluation', () async {
    final mockRepo = MockIEvaluationRepository();

    when(
      mockRepo.create(
        name: anyNamed('name'),
        categoryId: anyNamed('categoryId'),
        hours: anyNamed('hours'),
        visibility: anyNamed('visibility'),
        teacherId: anyNamed('teacherId'),
      ),
    ).thenAnswer(
      (_) async => Evaluation(
        id: 1,
        name: 'Sprint Demo',
        categoryId: 10,
        categoryName: 'Cat',
        hours: 24,
        visibility: 'private',
        createdAt: DateTime(2026, 4, 1),
        closesAt: DateTime(2026, 4, 2),
      ),
    );

    final useCase = TeacherCreateEvaluationUseCase(mockRepo);

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
    verify(
      mockRepo.create(
        name: 'Sprint Demo',
        categoryId: 10,
        hours: 24,
        visibility: 'private',
        teacherId: 7,
      ),
    ).called(1);
  });
}
