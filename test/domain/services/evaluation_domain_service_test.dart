import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;

void main() {
  const service = EvaluationDomainService();

  final active = Evaluation(
    id: 1,
    name: 'Eval activa',
    categoryId: 10,
    categoryName: 'Sprint',
    hours: 24,
    visibility: 'private',
    createdAt: DateTime(2026, 4, 1),
    closesAt: DateTime(2099, 1, 1),
  );

  test('statusForEvaluation returns activePending when active and incomplete', () {
    final status = service.statusForEvaluation(
      evaluation: active,
      completed: false,
    );

    expect(status, EvalStudentStatus.activePending);
  });

  test('allEvaluated requires non-empty peers', () {
    expect(service.allEvaluated(const <Peer>[]), false);
  });
}
