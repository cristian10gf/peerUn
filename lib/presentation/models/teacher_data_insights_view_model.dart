class TeacherDataInsightsViewModel {
  final String overallAverageLabel;
  final String evaluationsCountLabel;
  final String validScoresCountLabel;

  final bool showNoEvaluationsState;
  final bool showNoResponsesState;

  final List<TeacherInsightsCourseAverageVm> courseAverages;
  final List<TeacherInsightsCategoryAverageVm> categoryAverages;
  final List<TeacherInsightsBestGroupVm> bestGroups;
  final List<TeacherInsightsStudentVm> topStudents;
  final List<TeacherInsightsStudentVm> atRiskStudents;
  final List<TeacherInsightsEvaluationCoverageVm> evaluations;

  const TeacherDataInsightsViewModel({
    required this.overallAverageLabel,
    required this.evaluationsCountLabel,
    required this.validScoresCountLabel,
    required this.showNoEvaluationsState,
    required this.showNoResponsesState,
    required this.courseAverages,
    required this.categoryAverages,
    required this.bestGroups,
    required this.topStudents,
    required this.atRiskStudents,
    required this.evaluations,
  });

  bool get isCourseSectionEmpty => courseAverages.isEmpty;
  bool get isCategorySectionEmpty => categoryAverages.isEmpty;
  bool get isBestGroupSectionEmpty => bestGroups.isEmpty;
  bool get isTopStudentsSectionEmpty => topStudents.isEmpty;
  bool get isAtRiskSectionEmpty => atRiskStudents.isEmpty;

  bool get hasAnyKpiData =>
      courseAverages.isNotEmpty ||
      categoryAverages.isNotEmpty ||
      bestGroups.isNotEmpty ||
      topStudents.isNotEmpty ||
      atRiskStudents.isNotEmpty;
}

class TeacherInsightsCourseAverageVm {
  final String courseId;
  final String courseName;
  final double average;
  final int sampleCount;
  final String averageLabel;
  final String sampleCountLabel;

  const TeacherInsightsCourseAverageVm({
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.sampleCount,
    required this.averageLabel,
    required this.sampleCountLabel,
  });
}

class TeacherInsightsCategoryAverageVm {
  final String categoryId;
  final String categoryName;
  final String courseId;
  final String courseName;
  final double average;
  final int sampleCount;
  final String averageLabel;
  final String sampleCountLabel;

  const TeacherInsightsCategoryAverageVm({
    required this.categoryId,
    required this.categoryName,
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.sampleCount,
    required this.averageLabel,
    required this.sampleCountLabel,
  });
}

class TeacherInsightsBestGroupVm {
  final String courseId;
  final String courseName;
  final String groupId;
  final String groupName;
  final double average;
  final int sampleCount;
  final String averageLabel;
  final String sampleCountLabel;

  const TeacherInsightsBestGroupVm({
    required this.courseId,
    required this.courseName,
    required this.groupId,
    required this.groupName,
    required this.average,
    required this.sampleCount,
    required this.averageLabel,
    required this.sampleCountLabel,
  });
}

class TeacherInsightsStudentVm {
  final String studentId;
  final String studentName;
  final double average;
  final int sampleCount;
  final String averageLabel;
  final String sampleCountLabel;

  const TeacherInsightsStudentVm({
    required this.studentId,
    required this.studentName,
    required this.average,
    required this.sampleCount,
    required this.averageLabel,
    required this.sampleCountLabel,
  });
}

class TeacherInsightsEvaluationCoverageVm {
  final String evaluationId;
  final String evaluationName;
  final String courseId;
  final String courseName;
  final String categoryId;
  final String categoryName;

  const TeacherInsightsEvaluationCoverageVm({
    required this.evaluationId,
    required this.evaluationName,
    required this.courseId,
    required this.courseName,
    required this.categoryId,
    required this.categoryName,
  });
}
