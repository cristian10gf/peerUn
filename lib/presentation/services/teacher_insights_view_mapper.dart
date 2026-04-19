import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';

class TeacherInsightsViewMapper {
  const TeacherInsightsViewMapper();

  TeacherDataInsightsViewModel build(TeacherInsightsAggregate aggregate) {
    final orderedCourseAverages =
        aggregate.courseAverages.toList(growable: false)..sort((a, b) {
          final byAvg = b.average.compareTo(a.average);
          if (byAvg != 0) return byAvg;
          final bySamples = b.sampleCount.compareTo(a.sampleCount);
          if (bySamples != 0) return bySamples;
          return a.courseName.toLowerCase().compareTo(
            b.courseName.toLowerCase(),
          );
        });

    final orderedCategoryAverages =
        aggregate.categoryAverages.toList(growable: false)..sort((a, b) {
          final byAvg = b.average.compareTo(a.average);
          if (byAvg != 0) return byAvg;
          final bySamples = b.sampleCount.compareTo(a.sampleCount);
          if (bySamples != 0) return bySamples;
          final byCourse = a.courseName.toLowerCase().compareTo(
            b.courseName.toLowerCase(),
          );
          if (byCourse != 0) return byCourse;
          return a.categoryName.toLowerCase().compareTo(
            b.categoryName.toLowerCase(),
          );
        });

    final orderedBestGroups =
        aggregate.bestGroupsByCourse.toList(growable: false)..sort((a, b) {
          final byCourse = a.courseName.toLowerCase().compareTo(
            b.courseName.toLowerCase(),
          );
          if (byCourse != 0) return byCourse;
          return a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase());
        });

    final orderedTopStudents = aggregate.topStudents.toList(growable: false)
      ..sort((a, b) {
        final byAvg = b.average.compareTo(a.average);
        if (byAvg != 0) return byAvg;
        final bySamples = b.sampleCount.compareTo(a.sampleCount);
        if (bySamples != 0) return bySamples;
        return a.studentName.toLowerCase().compareTo(
          b.studentName.toLowerCase(),
        );
      });

    final orderedAtRiskStudents =
        aggregate.atRiskStudents.toList(growable: false)..sort((a, b) {
          final byAvg = a.average.compareTo(b.average);
          if (byAvg != 0) return byAvg;
          final bySamples = b.sampleCount.compareTo(a.sampleCount);
          if (bySamples != 0) return bySamples;
          return a.studentName.toLowerCase().compareTo(
            b.studentName.toLowerCase(),
          );
        });

    final orderedEvaluations = aggregate.evaluations.toList(growable: false)
      ..sort((a, b) {
        final byCourse = a.courseName.toLowerCase().compareTo(
          b.courseName.toLowerCase(),
        );
        if (byCourse != 0) return byCourse;
        final byCategory = a.categoryName.toLowerCase().compareTo(
          b.categoryName.toLowerCase(),
        );
        if (byCategory != 0) return byCategory;
        return a.evaluationName.toLowerCase().compareTo(
          b.evaluationName.toLowerCase(),
        );
      });

    final totalValidScores = orderedCourseAverages.fold<int>(
      0,
      (sum, item) => sum + item.sampleCount,
    );

    final weightedScoreSum = orderedCourseAverages.fold<double>(
      0,
      (sum, item) => sum + (item.average * item.sampleCount),
    );

    final overallAverage = totalValidScores == 0
        ? 0.0
        : weightedScoreSum / totalValidScores;

    return TeacherDataInsightsViewModel(
      overallAverageLabel: totalValidScores == 0
          ? '-'
          : _scoreLabel(overallAverage),
      evaluationsCountLabel: orderedEvaluations.length.toString(),
      validScoresCountLabel: totalValidScores.toString(),
      showNoEvaluationsState: orderedEvaluations.isEmpty,
      showNoResponsesState:
          orderedEvaluations.isNotEmpty && totalValidScores == 0,
      courseAverages: orderedCourseAverages
          .map(
            (row) => TeacherInsightsCourseAverageVm(
              courseId: row.courseId,
              courseName: row.courseName,
              average: row.average,
              sampleCount: row.sampleCount,
              averageLabel: _scoreLabel(row.average),
              sampleCountLabel: row.sampleCount.toString(),
            ),
          )
          .toList(growable: false),
      categoryAverages: orderedCategoryAverages
          .map(
            (row) => TeacherInsightsCategoryAverageVm(
              categoryId: row.categoryId,
              categoryName: row.categoryName,
              courseId: row.courseId,
              courseName: row.courseName,
              average: row.average,
              sampleCount: row.sampleCount,
              averageLabel: _scoreLabel(row.average),
              sampleCountLabel: row.sampleCount.toString(),
            ),
          )
          .toList(growable: false),
      bestGroups: orderedBestGroups
          .map(
            (row) => TeacherInsightsBestGroupVm(
              courseId: row.courseId,
              courseName: row.courseName,
              groupId: row.groupId,
              groupName: row.groupName,
              average: row.average,
              sampleCount: row.sampleCount,
              averageLabel: _scoreLabel(row.average),
              sampleCountLabel: row.sampleCount.toString(),
            ),
          )
          .toList(growable: false),
      topStudents: orderedTopStudents
          .map(
            (row) => TeacherInsightsStudentVm(
              studentId: row.studentId,
              studentName: row.studentName,
              average: row.average,
              sampleCount: row.sampleCount,
              averageLabel: _scoreLabel(row.average),
              sampleCountLabel: row.sampleCount.toString(),
            ),
          )
          .toList(growable: false),
      atRiskStudents: orderedAtRiskStudents
          .map(
            (row) => TeacherInsightsStudentVm(
              studentId: row.studentId,
              studentName: row.studentName,
              average: row.average,
              sampleCount: row.sampleCount,
              averageLabel: _scoreLabel(row.average),
              sampleCountLabel: row.sampleCount.toString(),
            ),
          )
          .toList(growable: false),
      evaluations: orderedEvaluations
          .map(
            (row) => TeacherInsightsEvaluationCoverageVm(
              evaluationId: row.evaluationId,
              evaluationName: row.evaluationName,
              courseId: row.courseId,
              courseName: row.courseName,
              categoryId: row.categoryId,
              categoryName: row.categoryName,
            ),
          )
          .toList(growable: false),
    );
  }

  String _scoreLabel(double value) => value.toStringAsFixed(1);
}
