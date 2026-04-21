import 'package:example/domain/models/teacher_insights.dart';

class TeacherInsightsDomainService {
  static const int minValidScore = 2;
  static const int maxValidScore = 5;
  static const int minStudentSamples = 4;
  static const int minBestGroupSamples = 4;
  static const double atRiskCutoff = 3.0;

  const TeacherInsightsDomainService();

  TeacherInsightsAggregate build(TeacherInsightsInput input) {
    final courseStats = <String, _StatsBucket>{};
    final categoryStats = <String, _StatsBucket>{};
    final groupStats = <String, _StatsBucket>{};
    final studentStats = <String, _StatsBucket>{};

    for (final point in input.scorePoints) {
      if (!_isValidScore(point.score)) {
        continue;
      }

      final courseKey = point.courseId;
      courseStats
          .putIfAbsent(
            courseKey,
            () => _StatsBucket(
              id: point.courseId,
              name: point.courseName,
              parentId: '',
              parentName: '',
            ),
          )
          .add(point.score);

      final categoryKey = point.categoryId;
      categoryStats
          .putIfAbsent(
            categoryKey,
            () => _StatsBucket(
              id: point.categoryId,
              name: point.categoryName,
              parentId: point.courseId,
              parentName: point.courseName,
            ),
          )
          .add(point.score);

      final groupKey = '${point.courseId}::${point.groupId}';
      groupStats
          .putIfAbsent(
            groupKey,
            () => _StatsBucket(
              id: point.groupId,
              name: point.groupName,
              parentId: point.courseId,
              parentName: point.courseName,
            ),
          )
          .add(point.score);

      final studentKey = point.studentId;
      studentStats
          .putIfAbsent(
            studentKey,
            () => _StatsBucket(
              id: point.studentId,
              name: point.studentName,
              parentId: '',
              parentName: '',
            ),
          )
          .add(point.score);
    }

    final courseAverages =
        courseStats.values
            .map(
              (bucket) => TeacherCourseAverage(
                courseId: bucket.id,
                courseName: bucket.name,
                average: _round1(bucket.average),
                sampleCount: bucket.count,
              ),
            )
            .toList(growable: false)
          ..sort(_compareCourseAverage);

    final categoryAverages =
        categoryStats.values
            .map(
              (bucket) => TeacherCategoryAverage(
                categoryId: bucket.id,
                categoryName: bucket.name,
                courseId: bucket.parentId,
                courseName: bucket.parentName,
                average: _round1(bucket.average),
                sampleCount: bucket.count,
              ),
            )
            .toList(growable: false)
          ..sort(_compareCategoryAverage);

    final bestGroupsByCourse = _buildBestGroups(groupStats);

    final rankingEligible =
        studentStats.values
            .where((bucket) => bucket.count >= minStudentSamples)
            .map(
              (bucket) => TeacherStudentAverage(
                studentId: bucket.id,
                studentName: bucket.name,
                average: _round1(bucket.average),
                sampleCount: bucket.count,
              ),
            )
            .toList(growable: false)
          ..sort(_compareStudentForTop);

    final atRiskStudents =
        rankingEligible
            .where((student) => student.average < atRiskCutoff)
            .toList(growable: false)
          ..sort(_compareStudentForAtRisk);

    final evaluations = _dedupeCoverage(input.evaluations);

    return TeacherInsightsAggregate(
      courseAverages: courseAverages,
      categoryAverages: categoryAverages,
      bestGroupsByCourse: bestGroupsByCourse,
      topStudents: rankingEligible,
      atRiskStudents: atRiskStudents,
      evaluations: evaluations,
    );
  }

  List<TeacherBestGroup> _buildBestGroups(
    Map<String, _StatsBucket> groupStats,
  ) {
    final byCourse = <String, List<_StatsBucket>>{};

    for (final bucket in groupStats.values) {
      if (bucket.count < minBestGroupSamples) {
        continue;
      }
      byCourse.putIfAbsent(bucket.parentId, () => <_StatsBucket>[]).add(bucket);
    }

    final winners = <TeacherBestGroup>[];
    for (final entry in byCourse.entries) {
      final groups = entry.value;
      if (groups.isEmpty) {
        continue;
      }

      groups.sort(_compareGroupForWinner);
      final winner = groups.first;

      winners.add(
        TeacherBestGroup(
          courseId: winner.parentId,
          courseName: winner.parentName,
          groupId: winner.id,
          groupName: winner.name,
          average: _round1(winner.average),
          sampleCount: winner.count,
        ),
      );
    }

    winners.sort((a, b) {
      final byCourse = a.courseName.toLowerCase().compareTo(
        b.courseName.toLowerCase(),
      );
      if (byCourse != 0) return byCourse;
      return a.courseId.compareTo(b.courseId);
    });

    return winners;
  }

  bool _isValidScore(double score) =>
      score >= minValidScore && score <= maxValidScore;

  double _round1(double value) => double.parse(value.toStringAsFixed(1));

  int _compareCourseAverage(TeacherCourseAverage a, TeacherCourseAverage b) {
    final byAvg = b.average.compareTo(a.average);
    if (byAvg != 0) return byAvg;
    final bySamples = b.sampleCount.compareTo(a.sampleCount);
    if (bySamples != 0) return bySamples;
    final byName = a.courseName.toLowerCase().compareTo(
      b.courseName.toLowerCase(),
    );
    if (byName != 0) return byName;
    return a.courseId.compareTo(b.courseId);
  }

  int _compareCategoryAverage(
    TeacherCategoryAverage a,
    TeacherCategoryAverage b,
  ) {
    final byAvg = b.average.compareTo(a.average);
    if (byAvg != 0) return byAvg;
    final bySamples = b.sampleCount.compareTo(a.sampleCount);
    if (bySamples != 0) return bySamples;
    final byCourse = a.courseName.toLowerCase().compareTo(
      b.courseName.toLowerCase(),
    );
    if (byCourse != 0) return byCourse;
    final byCategory = a.categoryName.toLowerCase().compareTo(
      b.categoryName.toLowerCase(),
    );
    if (byCategory != 0) return byCategory;
    return a.categoryId.compareTo(b.categoryId);
  }

  int _compareGroupForWinner(_StatsBucket a, _StatsBucket b) {
    final byAvg = b.average.compareTo(a.average);
    if (byAvg != 0) return byAvg;

    final bySamples = b.count.compareTo(a.count);
    if (bySamples != 0) return bySamples;

    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;

    return a.id.compareTo(b.id);
  }

  int _compareStudentForTop(TeacherStudentAverage a, TeacherStudentAverage b) {
    final byAvg = b.average.compareTo(a.average);
    if (byAvg != 0) return byAvg;
    final bySamples = b.sampleCount.compareTo(a.sampleCount);
    if (bySamples != 0) return bySamples;
    final byName = a.studentName.toLowerCase().compareTo(
      b.studentName.toLowerCase(),
    );
    if (byName != 0) return byName;
    return a.studentId.compareTo(b.studentId);
  }

  int _compareStudentForAtRisk(
    TeacherStudentAverage a,
    TeacherStudentAverage b,
  ) {
    final byAvg = a.average.compareTo(b.average);
    if (byAvg != 0) return byAvg;
    final bySamples = b.sampleCount.compareTo(a.sampleCount);
    if (bySamples != 0) return bySamples;
    final byName = a.studentName.toLowerCase().compareTo(
      b.studentName.toLowerCase(),
    );
    if (byName != 0) return byName;
    return a.studentId.compareTo(b.studentId);
  }

  List<TeacherInsightsEvaluationCoverage> _dedupeCoverage(
    List<TeacherInsightsEvaluationCoverage> rows,
  ) {
    final byId = <String, TeacherInsightsEvaluationCoverage>{};
    for (final row in rows) {
      byId[row.evaluationId] = row;
    }

    final values = byId.values.toList(growable: false)
      ..sort((a, b) {
        final byCourse = a.courseName.toLowerCase().compareTo(
          b.courseName.toLowerCase(),
        );
        if (byCourse != 0) return byCourse;
        final byCategory = a.categoryName.toLowerCase().compareTo(
          b.categoryName.toLowerCase(),
        );
        if (byCategory != 0) return byCategory;
        final byEval = a.evaluationName.toLowerCase().compareTo(
          b.evaluationName.toLowerCase(),
        );
        if (byEval != 0) return byEval;
        return a.evaluationId.compareTo(b.evaluationId);
      });

    return values;
  }
}

class _StatsBucket {
  final String id;
  final String name;
  final String parentId;
  final String parentName;

  double _sum = 0;
  int _count = 0;

  _StatsBucket({
    required this.id,
    required this.name,
    required this.parentId,
    required this.parentName,
  });

  int get count => _count;

  double get average {
    if (_count == 0) return 0;
    return _sum / _count;
  }

  void add(double score) {
    _sum += score;
    _count++;
  }
}
