import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';

enum EvalStudentStatus {
  activePending,
  activeCompleted,
  closedNotDone,
  closedCompleted,
}

class EvaluationDomainService {
  const EvaluationDomainService();

  EvalStudentStatus statusForEvaluation({
    required Evaluation evaluation,
    required bool completed,
  }) {
    if (evaluation.isActive) {
      return completed
          ? EvalStudentStatus.activeCompleted
          : EvalStudentStatus.activePending;
    }

    return completed
        ? EvalStudentStatus.closedCompleted
        : EvalStudentStatus.closedNotDone;
  }

  Evaluation? selectDefaultEvaluation(
    List<Evaluation> evaluations,
    Map<int, EvalStudentStatus> statuses,
  ) {
    for (final evaluation in evaluations) {
      if (statuses[evaluation.id] == EvalStudentStatus.activePending) {
        return evaluation;
      }
    }

    for (final evaluation in evaluations) {
      if (evaluation.isActive) return evaluation;
    }

    return evaluations.isNotEmpty ? evaluations.first : null;
  }

  int donePeers(Iterable<Peer> peers) {
    return peers.where((peer) => peer.evaluated).length;
  }

  int totalPeers(Iterable<Peer> peers) {
    return peers.length;
  }

  double evalProgress(Iterable<Peer> peers) {
    final total = totalPeers(peers);
    if (total == 0) return 0;
    return donePeers(peers) / total;
  }

  bool allEvaluated(Iterable<Peer> peers) {
    final total = totalPeers(peers);
    return total > 0 && donePeers(peers) == total;
  }

  double averageFromCriterionResults(List<CriterionResult> myResults) {
    if (myResults.isEmpty) return 0;
    final sum = myResults.map((result) => result.value).reduce((a, b) => a + b);
    return sum / myResults.length;
  }

  String performanceBadge(double average) {
    if (average >= 4.5) return 'Excelente desempeno';
    if (average >= 3.5) return 'Buen desempeno';
    if (average >= 2.5) return 'Desempeno adecuado';
    return 'Necesita mejorar';
  }
}
