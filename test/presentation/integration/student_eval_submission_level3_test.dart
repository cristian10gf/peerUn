/// Level-3 integration test: student evaluation submission chain.
///
/// Chain under test:
///   SPeersPage widget
///     → real StudentController
///     → real EvaluationRepositoryImpl
///     → FakeDatabaseServiceEvalLevel3  (in-memory fixture tables)
///
/// The HTTP/network layer is never reached — the fake DB intercepts every
/// robleRead / robleCreate call and returns deterministic fixture data.
///
/// Why this test matters:
///   saveResponses → resultEvaluation → result_criterium was a previously
///   broken flow (data went to the wrong table).  This test verifies the
///   full chain end-to-end without mocking the repository or controller.
library;

import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/fake_cache_service.dart';
import '../../helpers/fake_database_service_eval_level3.dart';
import '../../helpers/getx_test_harness.dart';
import '../../helpers/repository_fakes.dart';

// Minimal StudentController that uses real EvaluationRepositoryImpl but
// skips the connectivity-gated session check (we set the session directly).
class _RealStudentCtrl extends StudentController {
  _RealStudentCtrl(
    AuthRepositoryImpl authRepo,
    EvaluationRepositoryImpl evalRepo,
  ) : super(authRepo, evalRepo, FakeCacheService());

  // Expose a direct setter so the test can inject the student session without
  // going through the full auth flow (which would need a real login).
  void injectSession(Student s) => student.value = s;
}

void main() {
  setUp(resetGetxTestState);

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Wires up the full real chain and returns the live controller + FakeDb.
  ({_RealStudentCtrl ctrl, FakeDatabaseServiceEvalLevel3 db}) _buildChain() {
    final db = FakeDatabaseServiceEvalLevel3();
    final ctrl = _RealStudentCtrl(AuthRepositoryImpl(db), EvaluationRepositoryImpl(db));
    Get.put<StudentController>(ctrl);
    Get.put<ConnectivityController>(
      ConnectivityController(FakeConnectivityRepository(connected: true)),
    );
    return (ctrl: ctrl, db: db);
  }

  // ── test 1: peers loaded from FakeDb via real chain ───────────────────────

  testWidgets(
    'level3: getPeersForStudent populates peers via real repository chain',
    (tester) async {
      final (:ctrl, db: _) = _buildChain();

      await tester.pumpWidget(
        buildGetxTestApp(
          home: const SPeersPage(),
          extraRoutes: [
            GetPage(name: '/student/peer-score', page: () => const SizedBox.shrink()),
            GetPage(name: '/student/courses', page: () => const SizedBox.shrink()),
          ],
        ),
      );

      // Injecting the student triggers ever(student, loadEvalData).
      ctrl.injectSession(
        const Student(
          id: '300',
          name: 'Ana López',
          email: 'student@uni.edu',
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The real EvaluationRepositoryImpl read fixture tables and resolved
      // the two peers that share the group with the student.
      expect(ctrl.peers.length, 2);
      expect(find.text('Bob Ruiz'), findsOneWidget);
      expect(find.text('Carlos Vega'), findsOneWidget);

      // Header subtitle shows group name from real getGroupNameForStudent.
      expect(find.textContaining('Equipo A'), findsOneWidget);
    },
  );

  // ── test 2: submitEvaluation persists resultEvaluation records ─────────────

  testWidgets(
    'level3: submitEvaluation creates resultEvaluation + result_criterium '
    'records through real chain',
    (tester) async {
      final (:ctrl, :db) = _buildChain();

      await tester.pumpWidget(
        buildGetxTestApp(
          home: const SPeersPage(),
          extraRoutes: [
            GetPage(name: '/student/peer-score', page: () => const SizedBox.shrink()),
            GetPage(name: '/student/courses', page: () => const SizedBox.shrink()),
          ],
        ),
      );

      ctrl.injectSession(
        const Student(
          id: '300',
          name: 'Ana López',
          email: 'student@uni.edu',
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simulate the student scoring every peer — bypass UI taps for the
      // 4×2 criterion cards; the key chain under test is submitEvaluation.
      const scores = {'punct': 4, 'contrib': 5, 'commit': 4, 'attitude': 5};
      for (final peer in ctrl.peers) {
        peer.scores = Map<String, int>.from(scores);
        peer.evaluated = true;
      }
      ctrl.peers.refresh();
      await tester.pump();

      // The submit button becomes visible once allEvaluated is true.
      expect(find.text('Enviar evaluación completa'), findsOneWidget);

      await tester.tap(find.text('Enviar evaluación completa'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Real EvaluationRepositoryImpl.saveResponses was called for each peer
      // → 2 resultEvaluation rows (one per peer).
      expect(db.createdResultEvals.length, 2);

      // 4 criteria × 2 peers = 8 result_criterium rows.
      expect(db.createdResultCriteria.length, 8);

      // Each resultEvaluation references the correct evaluation UUID and
      // evaluator UUID (both come from the real repository logic).
      for (final re in db.createdResultEvals) {
        expect(re['evaluation_id'], '100');
        expect(re['evaluator_id'], '300');
      }

      // The two evaluated UUIDs must be the peer UUIDs, not the student's.
      final evaluatedIds =
          db.createdResultEvals.map((r) => r['evaluated_id']).toSet();
      expect(evaluatedIds, containsAll(<String>['301', '302']));
      expect(evaluatedIds, isNot(contains('300')));
    },
  );

  // ── test 3: getSavedPeerScores restores partial progress ──────────────────

  testWidgets(
    'level3: peers are marked evaluated on reload when prior scores exist '
    'in resultEvaluation (partial-progress restore)',
    (tester) async {
      final db = FakeDatabaseServiceEvalLevel3();
      final ctrl = _RealStudentCtrl(
        AuthRepositoryImpl(db),
        EvaluationRepositoryImpl(db),
      );
      Get.put<StudentController>(ctrl);
      Get.put<ConnectivityController>(
        ConnectivityController(FakeConnectivityRepository(connected: true)),
      );

      // Pre-populate FakeDb with a prior submission for peer 301 only.
      db.createdResultEvals.add({
        'resultEvaluation_id': 're-pre',
        '_id': 're-pre',
        'evaluation_id': '100',
        'evaluator_id': '300',
        'evaluated_id': '301',
        'group_id': '400',
      });
      // 4 criterion rows for peer 301
      for (final crit in ['crit-1', 'crit-2', 'crit-3', 'crit-4']) {
        db.createdResultCriteria.add({
          '_id': 'pre-$crit',
          'result_id': 're-pre',
          'criterium_id': crit,
          'score': '4',
        });
      }

      await tester.pumpWidget(
        buildGetxTestApp(
          home: const SPeersPage(),
          extraRoutes: [
            GetPage(name: '/student/peer-score', page: () => const SizedBox.shrink()),
            GetPage(name: '/student/courses', page: () => const SizedBox.shrink()),
          ],
        ),
      );

      ctrl.injectSession(
        const Student(
          id: '300',
          name: 'Ana López',
          email: 'student@uni.edu',
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Peer 301 (Bob Ruiz) should be restored as evaluated; peer 302 not.
      final bob = ctrl.peers.firstWhere((p) => p.id == '301');
      final carlos = ctrl.peers.firstWhere((p) => p.id == '302');

      expect(bob.evaluated, isTrue);
      expect(bob.scores.isNotEmpty, isTrue);
      expect(carlos.evaluated, isFalse);
    },
  );
}
