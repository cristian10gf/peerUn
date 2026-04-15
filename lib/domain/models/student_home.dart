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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory StudentHomeGroup.fromJson(Map<String, dynamic> j) => StudentHomeGroup(
    id: j['id'] as int,
    name: j['name'] as String,
    members: (j['members'] as List)
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
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
  double get progress =>
      totalPeerCount == 0 ? 0 : completedPeerCount / totalPeerCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'group': group?.toJson(),
    'activeEvaluationId': activeEvaluationId,
    'activeEvaluationName': activeEvaluationName,
    'completedPeerCount': completedPeerCount,
    'totalPeerCount': totalPeerCount,
  };

  factory StudentHomeCategory.fromJson(Map<String, dynamic> j) =>
      StudentHomeCategory(
        id: j['id'] as int,
        name: j['name'] as String,
        group: j['group'] == null
            ? null
            : StudentHomeGroup.fromJson(j['group'] as Map<String, dynamic>),
        activeEvaluationId: (j['activeEvaluationId'] as int?) ?? 0,
        activeEvaluationName: (j['activeEvaluationName'] as String?) ?? '',
        completedPeerCount: (j['completedPeerCount'] as int?) ?? 0,
        totalPeerCount: (j['totalPeerCount'] as int?) ?? 0,
      );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hasGroupAssignment': hasGroupAssignment,
    'categories': categories.map((c) => c.toJson()).toList(),
  };

  factory StudentHomeCourse.fromJson(Map<String, dynamic> j) =>
      StudentHomeCourse(
        id: j['id'] as int,
        name: j['name'] as String,
        hasGroupAssignment: j['hasGroupAssignment'] as bool,
        categories: (j['categories'] as List)
            .map((c) => StudentHomeCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
