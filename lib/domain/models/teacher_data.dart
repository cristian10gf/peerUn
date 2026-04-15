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

class StudentResult {
  final String initial;
  final String name;
  final double score;

  const StudentResult({
    required this.initial,
    required this.name,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'initial': initial,
    'name': name,
    'score': score,
  };

  factory StudentResult.fromJson(Map<String, dynamic> j) => StudentResult(
    initial: j['initial'] as String,
    name:    j['name']    as String,
    score:   (j['score']  as num).toDouble(),
  );
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'average': average,
    'criteria': criteria,
    'students': students.map((s) => s.toJson()).toList(),
  };

  factory GroupResult.fromJson(Map<String, dynamic> j) => GroupResult(
    name:     j['name']    as String,
    average:  (j['average'] as num).toDouble(),
    criteria: (j['criteria'] as List).map((c) => (c as num).toDouble()).toList(),
    students: (j['students'] as List)
        .map((s) => StudentResult.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}
