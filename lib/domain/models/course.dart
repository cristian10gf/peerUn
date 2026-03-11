class Course {
  final String id;
  final String name;
  final String groupName;
  final int memberCount;

  const Course({
    required this.id,
    required this.name,
    required this.groupName,
    required this.memberCount,
  });
}

class ActiveEvaluation {
  final String id;
  final String title;
  final String courseAndDeadline;
  final int completedCount;
  final int totalCount;

  const ActiveEvaluation({
    required this.id,
    required this.title,
    required this.courseAndDeadline,
    required this.completedCount,
    required this.totalCount,
  });

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
}
