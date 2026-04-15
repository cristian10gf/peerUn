class TeacherResultsOverviewVm {
  final String overallAverageLabel;
  final String groupCountLabel;
  final List<TeacherResultsGroupCardVm> groups;
  final bool hasGroups;

  const TeacherResultsOverviewVm({
    required this.overallAverageLabel,
    required this.groupCountLabel,
    required this.groups,
    required this.hasGroups,
  });
}

class TeacherResultsGroupCardVm {
  final int index;
  final String name;
  final double average;
  final double progress;
  final String averageLabel;

  const TeacherResultsGroupCardVm({
    required this.index,
    required this.name,
    required this.average,
    required this.progress,
    required this.averageLabel,
  });
}

class TeacherResultsDetailVm {
  final String groupName;
  final List<TeacherResultsCriterionVm> criteria;
  final List<TeacherResultsStudentVm> students;

  const TeacherResultsDetailVm({
    required this.groupName,
    required this.criteria,
    required this.students,
  });
}

class TeacherResultsCriterionVm {
  final String id;
  final String label;
  final double score;
  final double progress;
  final String scoreLabel;

  const TeacherResultsCriterionVm({
    required this.id,
    required this.label,
    required this.score,
    required this.progress,
    required this.scoreLabel,
  });
}

class TeacherResultsStudentVm {
  final String initial;
  final String name;
  final double score;
  final String scoreLabel;

  const TeacherResultsStudentVm({
    required this.initial,
    required this.name,
    required this.score,
    required this.scoreLabel,
  });
}
