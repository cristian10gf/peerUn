class TeacherInsightsInput {
  final List<TeacherInsightsScorePoint> scorePoints;
  final List<TeacherInsightsEvaluationCoverage> evaluations;

  const TeacherInsightsInput({
    required this.scorePoints,
    required this.evaluations,
  });

  Map<String, dynamic> toJson() => {
        'scorePoints': scorePoints.map((sp) => sp.toJson()).toList(),
        'evaluations': evaluations.map((e) => e.toJson()).toList(),
      };

  factory TeacherInsightsInput.fromJson(Map<String, dynamic> json) =>
      TeacherInsightsInput(
        scorePoints: (json['scorePoints'] as List)
            .map((e) => TeacherInsightsScorePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        evaluations: (json['evaluations'] as List)
            .map((e) => TeacherInsightsEvaluationCoverage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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
  final double score;

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

  Map<String, dynamic> toJson() => {
        'evaluationId': evaluationId,
        'courseId': courseId,
        'courseName': courseName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'groupId': groupId,
        'groupName': groupName,
        'studentId': studentId,
        'studentName': studentName,
        'score': score,
      };

  factory TeacherInsightsScorePoint.fromJson(Map<String, dynamic> json) =>
      TeacherInsightsScorePoint(
        evaluationId: json['evaluationId'] as String,
        courseId: json['courseId'] as String,
        courseName: json['courseName'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        groupId: json['groupId'] as String,
        groupName: json['groupName'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        score: (json['score'] as num).toDouble(),
      );
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

  Map<String, dynamic> toJson() => {
        'evaluationId': evaluationId,
        'evaluationName': evaluationName,
        'courseId': courseId,
        'courseName': courseName,
        'categoryId': categoryId,
        'categoryName': categoryName,
      };

  factory TeacherInsightsEvaluationCoverage.fromJson(Map<String, dynamic> json) =>
      TeacherInsightsEvaluationCoverage(
        evaluationId: json['evaluationId'] as String,
        evaluationName: json['evaluationName'] as String,
        courseId: json['courseId'] as String,
        courseName: json['courseName'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
      );
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
