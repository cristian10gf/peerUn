import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

import '../../helpers/repository_fakes.dart';

void main() {
  test('selectPeer + savePeerScore marks peer as evaluated when all criteria scored',
      () {
    final ctrl = StudentController(FakeAuthRepository(), FakeEvaluationRepository());

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
    final evalRepo = FakeEvaluationRepository()..completedAllPeers = true;
    final ctrl = StudentController(FakeAuthRepository(), evalRepo);

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
  });
}
