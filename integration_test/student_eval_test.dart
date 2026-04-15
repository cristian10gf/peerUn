/// Level-3 integration test: student evaluation submission chain.
///
/// Chain under test:
///   SPeersPage widget
///     → real StudentController
///     → real EvaluationRepositoryImpl
///     → FakeDatabaseServiceEvalLevel3  (in-memory fixture tables)
library;

import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/services/i_cache_service.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_cache_service.dart';
import '../test/helpers/fake_database_service_eval_level3.dart';
import '../test/helpers/getx_test_harness.dart';
import '../test/helpers/repository_fakes.dart';

class _RealStudentCtrl extends StudentController {
  _RealStudentCtrl(
    AuthRepositoryImpl authRepo,
    EvaluationRepositoryImpl evalRepo, [
    ICacheService? cache,
  ]) : super(authRepo, evalRepo, cache ?? FakeCacheService());

  void injectSession(Student s) => student.value = s;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetGetxTestState);

  ({_RealStudentCtrl ctrl, FakeDatabaseServiceEvalLevel3 db}) _buildChain([
    ICacheService? cache,
  ]) {
    final db = FakeDatabaseServiceEvalLevel3();
    final ctrl = _RealStudentCtrl(
      AuthRepositoryImpl(db),
      EvaluationRepositoryImpl(db),
      cache,
    );
    Get.put<StudentController>(ctrl);
    Get.put<ConnectivityController>(
      ConnectivityController(FakeConnectivityRepository(connected: true)),
    );
    return (ctrl: ctrl, db: db);
  }

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

      ctrl.injectSession(
        const Student(
          id: '300',
          name: 'Ana López',
          email: 'student@uni.edu',
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(ctrl.peers.length, 2);
      expect(find.text('Bob Ruiz'), findsOneWidget);
      expect(find.text('Carlos Vega'), findsOneWidget);
      expect(find.textContaining('Equipo A'), findsOneWidget);
    },
  );

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

      const scores = {'punct': 4, 'contrib': 5, 'commit': 4, 'attitude': 5};
      for (final peer in ctrl.peers) {
        peer.scores = Map<String, int>.from(scores);
        peer.evaluated = true;
      }
      ctrl.peers.refresh();
      await tester.pump();

      expect(find.text('Enviar evaluación completa'), findsOneWidget);

      await tester.tap(find.text('Enviar evaluación completa'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(db.createdResultEvals.length, 2);
      expect(db.createdResultCriteria.length, 8);

      for (final re in db.createdResultEvals) {
        expect(re['evaluation_id'], '100');
        expect(re['evaluator_id'], '300');
      }

      final evaluatedIds =
          db.createdResultEvals.map((r) => r['evaluated_id']).toSet();
      expect(evaluatedIds, containsAll(<String>['301', '302']));
      expect(evaluatedIds, isNot(contains('300')));
    },
  );

  testWidgets(
    'level3: peers are marked evaluated on reload when prior scores exist '
    'in resultEvaluation (partial-progress restore)',
    (tester) async {
      final db = FakeDatabaseServiceEvalLevel3();
      final ctrl = _RealStudentCtrl(AuthRepositoryImpl(db), EvaluationRepositoryImpl(db));
      Get.put<StudentController>(ctrl);
      Get.put<ConnectivityController>(
        ConnectivityController(FakeConnectivityRepository(connected: true)),
      );

      db.createdResultEvals.add({
        'resultEvaluation_id': 're-pre',
        '_id': 're-pre',
        'evaluation_id': '100',
        'evaluator_id': '300',
        'evaluated_id': '301',
        'group_id': '400',
      });
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

      final bob = ctrl.peers.firstWhere((p) => p.id == '301');
      final carlos = ctrl.peers.firstWhere((p) => p.id == '302');

      expect(bob.evaluated, isTrue);
      expect(bob.scores.isNotEmpty, isTrue);
      expect(carlos.evaluated, isFalse);
    },
  );
}
