import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/fake_cache_service.dart';
import '../helpers/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Auth tests ─────────────────────────────────────────────────────────────

  test('checkSession hydrates student and toggles loading', () async {
    final mockAuth = MockIAuthRepository();
    final mockEval = MockIEvaluationRepository();

    when(mockAuth.getCurrentSession()).thenAnswer((_) async => const Student(
          id: '99',
          name: 'Ana Perez',
          email: 'ana@uni.edu',
          initials: 'AP',
        ));

    final ctrl = StudentController(mockAuth, mockEval, FakeCacheService());
    await ctrl.checkSession();

    expect(ctrl.isLoading.value, false);
    expect(ctrl.student.value?.email, 'ana@uni.edu');
    expect(ctrl.isLoggedIn, true);
    verify(mockAuth.getCurrentSession()).called(1);
  });

  test('clearSessionStateForRoleSwitch resets auth + evaluation state', () {
    final mockAuth = MockIAuthRepository();
    final mockEval = MockIEvaluationRepository();

    when(mockAuth.getCurrentSession()).thenAnswer((_) async => null);

    final ctrl = StudentController(mockAuth, mockEval, FakeCacheService());

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

  // ── Evaluation flow tests ──────────────────────────────────────────────────

  test(
      'selectPeer + savePeerScore marks peer as evaluated when all criteria scored',
      () {
    final mockAuth = MockIAuthRepository();
    final mockEval = MockIEvaluationRepository();

    final ctrl = StudentController(mockAuth, mockEval, FakeCacheService());

    final peer = Peer(id: '7', name: 'Luis', initials: 'LR');
    ctrl.peers.add(peer);

    ctrl.selectPeer(peer);
    for (final criterion in EvalCriterion.defaults) {
      ctrl.setScore(criterion.id, 5);
    }
    ctrl.savePeerScore();

    expect(ctrl.peers.single.evaluated, true);
    expect(ctrl.allCriteriaScored, true);
  });

  test('submitEvaluation refreshes status map for active evaluation', () async {
    final mockAuth = MockIAuthRepository();
    final mockEval = MockIEvaluationRepository();

    when(mockEval.saveResponses(
      evalId: anyNamed('evalId'),
      evaluatorStudentId: anyNamed('evaluatorStudentId'),
      evaluatedMemberId: anyNamed('evaluatedMemberId'),
      scores: anyNamed('scores'),
    )).thenAnswer((_) async {});

    when(mockEval.getMyResults(any, any)).thenAnswer((_) async => []);

    when(mockEval.hasCompletedAllPeers(
      evalId: anyNamed('evalId'),
      email: anyNamed('email'),
      studentId: anyNamed('studentId'),
    )).thenAnswer((_) async => true);

    final ctrl = StudentController(mockAuth, mockEval, FakeCacheService());

    ctrl.student.value = const Student(
      id: '77',
      name: 'Ana',
      email: 'ana@uni.edu',
      initials: 'AP',
    );

    final eval = Evaluation(
      id: 11,
      name: 'Sprint 3',
      categoryId: 9,
      categoryName: 'Cat',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime(2026, 4, 1),
      closesAt: DateTime(2099, 1, 1),
    );

    ctrl.activeEvalDb.value = eval;
    ctrl.peers.addAll(<Peer>[
      Peer(
        id: '8',
        name: 'Bob',
        initials: 'BR',
        evaluated: true,
        scores: <String, int>{
          'punct': 4,
          'contrib': 4,
          'commit': 5,
          'attitude': 5,
        },
      ),
    ]);

    await ctrl.submitEvaluation();

    expect(ctrl.evalStatuses[11], EvalStudentStatus.activeCompleted);
    verify(mockEval.saveResponses(
      evalId: 11,
      evaluatorStudentId: anyNamed('evaluatorStudentId'),
      evaluatedMemberId: anyNamed('evaluatedMemberId'),
      scores: anyNamed('scores'),
    )).called(1);
  });
}
