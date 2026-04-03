import 'package:example/domain/models/group_category.dart';

class StudentHomeGroup {
  final int id;
  final String name;
  final List<GroupMember> members;

  const StudentHomeGroup({
    required this.id,
    required this.name,
    required this.members,
  });
}

class StudentHomeCategory {
  final int id;
  final String name;
  final StudentHomeGroup? group;
  final int activeEvaluationId;
  final String activeEvaluationName;
  final int completedPeerCount;
  final int totalPeerCount;

  const StudentHomeCategory({
    required this.id,
    required this.name,
    this.group,
    this.activeEvaluationId = 0,
    this.activeEvaluationName = '',
    this.completedPeerCount = 0,
    this.totalPeerCount = 0,
  });

  bool get hasGroup => group != null;
  bool get hasActiveEvaluation => activeEvaluationId != 0;
  double get progress => totalPeerCount == 0 ? 0 : completedPeerCount / totalPeerCount;
}

class StudentHomeCourse {
  final int id;
  final String name;
  final bool hasGroupAssignment;
  final List<StudentHomeCategory> categories;

  const StudentHomeCourse({
    required this.id,
    required this.name,
    required this.hasGroupAssignment,
    required this.categories,
  });
}
