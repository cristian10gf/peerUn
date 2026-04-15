class TeacherResultsOverviewViewModel {
  final double overallAverage;
  final String overallAverageLabel;
  final String groupCountLabel;
  final List<TeacherResultsOverviewGroupViewModel> groups;

  const TeacherResultsOverviewViewModel({
    required this.overallAverage,
    required this.overallAverageLabel,
    required this.groupCountLabel,
    required this.groups,
  });
}

class TeacherResultsOverviewGroupViewModel {
  final int index;
  final String name;
  final double average;
  final double progress;
  final String averageLabel;

  const TeacherResultsOverviewGroupViewModel({
    required this.index,
    required this.name,
    required this.average,
    required this.progress,
    required this.averageLabel,
  });
}

class TeacherResultsDetailViewModel {
  final int groupIndex;
  final String groupName;
  final double average;
  final double progress;
  final String averageLabel;
  final List<TeacherResultsCriterionViewModel> criteria;
  final List<TeacherResultsStudentViewModel> students;

  const TeacherResultsDetailViewModel({
    required this.groupIndex,
    required this.groupName,
    required this.average,
    required this.progress,
    required this.averageLabel,
    required this.criteria,
    required this.students,
  });
}

class TeacherResultsCriterionViewModel {
  final String id;
  final String label;
  final double value;
  final double progress;
  final String scoreLabel;

  const TeacherResultsCriterionViewModel({
    required this.id,
    required this.label,
    required this.value,
    required this.progress,
    required this.scoreLabel,
  });
}

class TeacherResultsStudentViewModel {
  final String initial;
  final String name;
  final double score;
  final double progress;
  final String scoreLabel;

  const TeacherResultsStudentViewModel({
    required this.initial,
    required this.name,
    required this.score,
    required this.progress,
    required this.scoreLabel,
  });
}
