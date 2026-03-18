import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';

abstract class IEvaluationRepository {
  /// Returns all evaluations ordered by creation date desc.
  Future<List<Evaluation>> getAll();

  /// Returns per-group results (real data) for a given evaluation.
  Future<List<GroupResult>> getGroupResults(int evalId);

  /// Create and persist a new evaluation.
  Future<Evaluation> create({
    required String name,
    required int categoryId,
    required int hours,
    required String visibility,
  });

  /// Returns the most recent evaluation the student is linked to
  /// (active or recently closed), via their group membership.
  Future<Evaluation?> getLatestForStudent(String email);

  /// Returns the group name for [email] within [evalId]'s category.
  Future<String?> getGroupNameForStudent(int evalId, String email);

  /// Returns peers (excluding [email]) in the same group under [evalId]'s category.
  Future<List<Peer>> getPeersForStudent(int evalId, String email);

  /// Returns the groups/categories the student belongs to as Course objects.
  Future<List<Course>> getCoursesForStudent(String email);

  /// Saves one set of criterion scores from evaluator → evaluated member.
  Future<void> saveResponses({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
    required Map<String, int> scores,
  });

  /// Returns true if the evaluator has already scored this evaluated member.
  Future<bool> hasEvaluated({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
  });

  /// Returns the average scores per criterion received by [email] in [evalId].
  Future<List<CriterionResult>> getMyResults(int evalId, String email);
}
