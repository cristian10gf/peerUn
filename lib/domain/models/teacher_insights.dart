class TeacherInsightsInput {
  final List<TeacherInsightsScorePoint> scorePoints;
  final List<TeacherInsightsEvaluationCoverage> evaluations;

  const TeacherInsightsInput({
    required this.scorePoints,
    required this.evaluations,
  });
}

class TeacherInsightsScorePoint {
  final String evaluationId;
  final String courseId;
  final String courseName;
  final String categoryId;
  final String categoryName;
  final String groupId;
  final String groupName;
  final String studentId;
  final String studentName;
  final int score;

  const TeacherInsightsScorePoint({
    required this.evaluationId,
    required this.courseId,
    required this.courseName,
    required this.categoryId,
    required this.categoryName,
    required this.groupId,
    required this.groupName,
    required this.studentId,
    required this.studentName,
    required this.score,
  });
}

class TeacherInsightsEvaluationCoverage {
  final String evaluationId;
  final String evaluationName;
  final String courseId;
  final String courseName;
  final String categoryId;
  final String categoryName;

  const TeacherInsightsEvaluationCoverage({
    required this.evaluationId,
    required this.evaluationName,
    required this.courseId,
    required this.courseName,
    required this.categoryId,
    required this.categoryName,
  });
}

class TeacherInsightsAggregate {
  final List<TeacherCourseAverage> courseAverages;
  final List<TeacherCategoryAverage> categoryAverages;
  final List<TeacherBestGroup> bestGroupsByCourse;
  final List<TeacherStudentAverage> topStudents;
  final List<TeacherStudentAverage> atRiskStudents;
  final List<TeacherInsightsEvaluationCoverage> evaluations;

  const TeacherInsightsAggregate({
    required this.courseAverages,
    required this.categoryAverages,
    required this.bestGroupsByCourse,
    required this.topStudents,
    required this.atRiskStudents,
    required this.evaluations,
  });

  bool get hasScoreData =>
      courseAverages.isNotEmpty ||
      categoryAverages.isNotEmpty ||
      bestGroupsByCourse.isNotEmpty ||
      topStudents.isNotEmpty ||
      atRiskStudents.isNotEmpty;
}

class TeacherCourseAverage {
  final String courseId;
  final String courseName;
  final double average;
  final int sampleCount;

  const TeacherCourseAverage({
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.sampleCount,
  });
}

class TeacherCategoryAverage {
  final String categoryId;
  final String categoryName;
  final String courseId;
  final String courseName;
  final double average;
  final int sampleCount;

  const TeacherCategoryAverage({
    required this.categoryId,
    required this.categoryName,
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.sampleCount,
  });
}

class TeacherBestGroup {
  final String courseId;
  final String courseName;
  final String groupId;
  final String groupName;
  final double average;
  final int sampleCount;

  const TeacherBestGroup({
    required this.courseId,
    required this.courseName,
    required this.groupId,
    required this.groupName,
    required this.average,
    required this.sampleCount,
  });
}

class TeacherStudentAverage {
  final String studentId;
  final String studentName;
  final double average;
  final int sampleCount;

  const TeacherStudentAverage({
    required this.studentId,
    required this.studentName,
    required this.average,
    required this.sampleCount,
  });
}
