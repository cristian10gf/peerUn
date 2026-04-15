/// Integration tests for StudentController cache behaviour.
library;

import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../test/helpers/fake_cache_service.dart';
import '../test/helpers/getx_test_harness.dart';
import 'helpers/mocks.dart';

const _student = Student(
  id: '300',
  name: 'Ana López',
  email: 'student@uni.edu',
  initials: 'AL',
);

const _homeKey = 'student_home_v1_student@uni.edu';
const _evalsKey = 'student_evals_v1_student@uni.edu';

StudentController _buildCtrl(
  MockIEvaluationRepository evalRepo,
  MockIAuthRepository authRepo,
  FakeCacheService cache,
) {
  when(authRepo.getCurrentSession()).thenAnswer((_) async => null);
  when(authRepo.logout()).thenAnswer((_) async {});
  when(evalRepo.getStudentHomeCourses(any))
      .thenAnswer((_) async => const <StudentHomeCourse>[]);
  when(evalRepo.getEvaluationsForStudent(any))
      .thenAnswer((_) async => const <Evaluation>[]);

  return StudentController(authRepo, evalRepo, cache);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetGetxTestState);

  test(
    'cache miss: loadEvalData calls repo and writes both cache keys',
    () async {
      final evalRepo = MockIEvaluationRepository();
      final authRepo = MockIAuthRepository();
      final cache = FakeCacheService();
      final ctrl = _buildCtrl(evalRepo, authRepo, cache);

      // Controller is not registered with Get, so onInit (and its ever listener)
      // is never called — setting student.value does not trigger loadEvalData.
      ctrl.student.value = _student;
      await ctrl.loadEvalData();

      verify(evalRepo.getStudentHomeCourses('student@uni.edu')).called(1);
      verify(evalRepo.getEvaluationsForStudent('student@uni.edu')).called(1);
      expect(cache.setCalls, contains(_homeKey));
      expect(cache.setCalls, contains(_evalsKey));
    },
  );

  test(
    'cache hit: second loadEvalData skips repository calls',
    () async {
      final evalRepo = MockIEvaluationRepository();
      final authRepo = MockIAuthRepository();
      final cache = FakeCacheService();
      final ctrl = _buildCtrl(evalRepo, authRepo, cache);

      // Controller is not registered with Get, so onInit (and its ever listener)
      // is never called — setting student.value does not trigger loadEvalData.
      ctrl.student.value = _student;
      await ctrl.loadEvalData(); // cache miss
      verify(evalRepo.getStudentHomeCourses('student@uni.edu')).called(1);
      verify(evalRepo.getEvaluationsForStudent('student@uni.edu')).called(1);

      await ctrl.loadEvalData(); // cache hit
      verifyNever(evalRepo.getStudentHomeCourses('student@uni.edu'));
      verifyNever(evalRepo.getEvaluationsForStudent('student@uni.edu'));
    },
  );

  test(
    'refreshData invalidates both cache keys and calls repo again',
    () async {
      final evalRepo = MockIEvaluationRepository();
      final authRepo = MockIAuthRepository();
      final cache = FakeCacheService();
      final ctrl = _buildCtrl(evalRepo, authRepo, cache);

      // Controller is not registered with Get, so onInit (and its ever listener)
      // is never called — setting student.value does not trigger loadEvalData.
      ctrl.student.value = _student;
      await ctrl.loadEvalData(); // miss

      await ctrl.refreshData(); // invalidate + reload

      expect(cache.invalidateCalls, contains(_homeKey));
      expect(cache.invalidateCalls, contains(_evalsKey));
      verify(evalRepo.getStudentHomeCourses('student@uni.edu')).called(2);
      verify(evalRepo.getEvaluationsForStudent('student@uni.edu')).called(2);
    },
  );
}
