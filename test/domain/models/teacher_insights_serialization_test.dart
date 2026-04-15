import 'dart:convert';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scorePoint = TeacherInsightsScorePoint(
    evaluationId: 'e1',
    courseId: 'c1',
    courseName: 'IS',
    categoryId: 'cat1',
    categoryName: 'Sprint',
    groupId: 'g1',
    groupName: 'Alfa',
    studentId: 's1',
    studentName: 'Ana',
    score: 5,
  );

  const coverage = TeacherInsightsEvaluationCoverage(
    evaluationId: 'e1',
    evaluationName: 'Eval 1',
    courseId: 'c1',
    courseName: 'IS',
    categoryId: 'cat1',
    categoryName: 'Sprint',
  );

  test('TeacherInsightsScorePoint round-trips through JSON', () {
    final json = scorePoint.toJson();
    final restored = TeacherInsightsScorePoint.fromJson(json);
    expect(restored.evaluationId, scorePoint.evaluationId);
    expect(restored.courseId, scorePoint.courseId);
    expect(restored.courseName, scorePoint.courseName);
    expect(restored.categoryId, scorePoint.categoryId);
    expect(restored.categoryName, scorePoint.categoryName);
    expect(restored.groupId, scorePoint.groupId);
    expect(restored.groupName, scorePoint.groupName);
    expect(restored.studentId, scorePoint.studentId);
    expect(restored.studentName, scorePoint.studentName);
    expect(restored.score, scorePoint.score);
  });

  test('TeacherInsightsEvaluationCoverage round-trips through JSON', () {
    final json = coverage.toJson();
    final restored = TeacherInsightsEvaluationCoverage.fromJson(json);
    expect(restored.evaluationId, coverage.evaluationId);
    expect(restored.evaluationName, coverage.evaluationName);
    expect(restored.courseId, coverage.courseId);
    expect(restored.courseName, coverage.courseName);
    expect(restored.categoryId, coverage.categoryId);
    expect(restored.categoryName, coverage.categoryName);
  });

  test('TeacherInsightsInput round-trips through JSON', () {
    const input = TeacherInsightsInput(
      scorePoints: [scorePoint],
      evaluations: [coverage],
    );

    final jsonStr = jsonEncode(input.toJson());
    final restored = TeacherInsightsInput.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );

    expect(restored.scorePoints, hasLength(1));
    expect(restored.scorePoints.first.studentId, 's1');
    expect(restored.evaluations, hasLength(1));
    expect(restored.evaluations.first.evaluationName, 'Eval 1');
  });

  test('TeacherInsightsInput with empty lists round-trips through JSON', () {
    const input = TeacherInsightsInput(
      scorePoints: [],
      evaluations: [],
    );

    final jsonStr = jsonEncode(input.toJson());
    final restored = TeacherInsightsInput.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );

    expect(restored.scorePoints, isEmpty);
    expect(restored.evaluations, isEmpty);
  });
}
