import 'package:example/domain/models/teacher_data.dart';

class GroupResultsInputGroup {
  final int id;
  final String name;

  const GroupResultsInputGroup({
    required this.id,
    required this.name,
  });
}

class GroupResultsInputMember {
  final int groupId;
  final int memberId;
  final String name;

  const GroupResultsInputMember({
    required this.groupId,
    required this.memberId,
    required this.name,
  });
}

class GroupResultsInputResponse {
  final int evaluatedMemberId;
  final String criterionId;
  final int score;

  const GroupResultsInputResponse({
    required this.evaluatedMemberId,
    required this.criterionId,
    required this.score,
  });
}

class GroupResultsDomainService {
  const GroupResultsDomainService();

  List<GroupResult> buildGroupResults({
    required List<GroupResultsInputGroup> groups,
    required List<GroupResultsInputMember> members,
    required List<GroupResultsInputResponse> responses,
    List<String> criteriaIds = const ['punct', 'contrib', 'commit', 'attitude'],
  }) {
    final result = <GroupResult>[];

    for (final group in groups) {
      final groupMembers = members
          .where((member) => member.groupId == group.id)
          .toList(growable: false);
      final memberIds = groupMembers.map((member) => member.memberId).toSet();

      final students = <StudentResult>[];
      for (final member in groupMembers) {
        final memberScores = responses
            .where((response) =>
                response.evaluatedMemberId == member.memberId &&
                response.score >= 2)
            .map((response) => response.score.toDouble())
            .toList(growable: false);

        final studentAverage = _average(memberScores);

        students.add(
          StudentResult(
            initial: member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
            name: member.name,
            score: studentAverage,
          ),
        );
      }

      final criteriaAverages = <double>[];
      for (final criterionId in criteriaIds) {
        final criterionScores = responses
            .where((response) =>
                memberIds.contains(response.evaluatedMemberId) &&
                response.criterionId == criterionId &&
                response.score >= 2)
            .map((response) => response.score.toDouble())
            .toList(growable: false);

        criteriaAverages.add(_average(criterionScores));
      }

      final validScores = students
          .where((student) => student.score > 0)
          .map((student) => student.score)
          .toList(growable: false);

      result.add(
        GroupResult(
          name: group.name,
          average: _average(validScores),
          criteria: criteriaAverages,
          students: students,
        ),
      );
    }

    return result;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.reduce((a, b) => a + b);
    final avg = sum / values.length;
    return double.parse(avg.toStringAsFixed(1));
  }
}
