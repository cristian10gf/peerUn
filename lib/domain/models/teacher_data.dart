class TeacherCourse {
  final String id;
  final String name;
  final String code;
  final int groupCount;
  final bool hasActive;

  const TeacherCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.groupCount,
    this.hasActive = false,
  });
}

class GroupResult {
  final String name;
  final double average;
  final List<double> criteria; // [punct, contrib, commit, actitud]
  final List<StudentResult> students;

  const GroupResult({
    required this.name,
    required this.average,
    required this.criteria,
    required this.students,
  });

  double get barFraction => ((average - 2) / 3).clamp(0.0, 1.0);
}

class StudentResult {
  final String initial;
  final String name;
  final double score;

  const StudentResult({
    required this.initial,
    required this.name,
    required this.score,
  });
}
