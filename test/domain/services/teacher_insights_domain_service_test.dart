import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TeacherInsightsDomainService();

  test('computes weighted averages by course and category', () {
    final input = TeacherInsightsInput(
      scorePoints: const <TeacherInsightsScorePoint>[
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'Ingenieria de Software',
          categoryId: 'cat1',
          categoryName: 'Sprint 1',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's1',
          studentName: 'Ana Lopez',
          score: 5,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'Ingenieria de Software',
          categoryId: 'cat1',
          categoryName: 'Sprint 1',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's2',
          studentName: 'Bob Ruiz',
          score: 3,
        ),
        // Invalid score; should be ignored by [2..5] rule.
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'Ingenieria de Software',
          categoryId: 'cat1',
          categoryName: 'Sprint 1',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's2',
          studentName: 'Bob Ruiz',
          score: 1,
        ),
      ],
      evaluations: const <TeacherInsightsEvaluationCoverage>[
        TeacherInsightsEvaluationCoverage(
          evaluationId: 'e1',
          evaluationName: 'Eval 1',
          courseId: 'c1',
          courseName: 'Ingenieria de Software',
          categoryId: 'cat1',
          categoryName: 'Sprint 1',
        ),
      ],
    );

    final result = service.build(input);

    expect(result.courseAverages.single.average, 4.0);
    expect(result.courseAverages.single.sampleCount, 2);
    expect(result.categoryAverages.single.average, 4.0);
    expect(result.categoryAverages.single.sampleCount, 2);
  });

  test('applies best-group tie-break by sample count then name', () {
    final input = TeacherInsightsInput(
      scorePoints: const <TeacherInsightsScorePoint>[
        // Group Alfa average 4.0 with 4 samples.
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's1',
          studentName: 'Ana',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's2',
          studentName: 'Bob',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's3',
          studentName: 'Caro',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's4',
          studentName: 'Dani',
          score: 4,
        ),
        // Group Zeta average 4.0 with 5 samples (wins by higher sample count).
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Zeta',
          studentId: 's5',
          studentName: 'Eva',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Zeta',
          studentId: 's6',
          studentName: 'Fran',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Zeta',
          studentId: 's7',
          studentName: 'Gus',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Zeta',
          studentId: 's8',
          studentName: 'Hugo',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Zeta',
          studentId: 's9',
          studentName: 'Ines',
          score: 4,
        ),
      ],
      evaluations: const <TeacherInsightsEvaluationCoverage>[],
    );

    final result = service.build(input);

    expect(result.bestGroupsByCourse.single.groupName, 'Equipo Zeta');
    expect(result.bestGroupsByCourse.single.sampleCount, 5);
  });

  test('uses lexical tie-break when average and sample count are equal', () {
    final input = TeacherInsightsInput(
      scorePoints: const <TeacherInsightsScorePoint>[
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's1',
          studentName: 'Ana',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's2',
          studentName: 'Bob',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's3',
          studentName: 'Caro',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo Alfa',
          studentId: 's4',
          studentName: 'Dani',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Beta',
          studentId: 's5',
          studentName: 'Eva',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Beta',
          studentId: 's6',
          studentName: 'Fran',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Beta',
          studentId: 's7',
          studentName: 'Gus',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g2',
          groupName: 'Equipo Beta',
          studentId: 's8',
          studentName: 'Hugo',
          score: 4,
        ),
      ],
      evaluations: const <TeacherInsightsEvaluationCoverage>[],
    );

    final result = service.build(input);

    expect(result.bestGroupsByCourse.single.groupName, 'Equipo Alfa');
  });

  test('applies student threshold and at-risk cutoff', () {
    final input = TeacherInsightsInput(
      scorePoints: const <TeacherInsightsScorePoint>[
        // Ana: 4 scores, avg 4.5 -> top
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's1',
          studentName: 'Ana',
          score: 5,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's1',
          studentName: 'Ana',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's1',
          studentName: 'Ana',
          score: 4,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's1',
          studentName: 'Ana',
          score: 5,
        ),
        // Bob: 4 scores, avg 2.5 -> at risk
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's2',
          studentName: 'Bob',
          score: 2,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's2',
          studentName: 'Bob',
          score: 3,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's2',
          studentName: 'Bob',
          score: 2,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's2',
          studentName: 'Bob',
          score: 3,
        ),
        // Caro: only 3 samples -> excluded by threshold
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's3',
          studentName: 'Caro',
          score: 5,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's3',
          studentName: 'Caro',
          score: 5,
        ),
        TeacherInsightsScorePoint(
          evaluationId: 'e1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
          groupId: 'g1',
          groupName: 'Equipo',
          studentId: 's3',
          studentName: 'Caro',
          score: 5,
        ),
      ],
      evaluations: const <TeacherInsightsEvaluationCoverage>[],
    );

    final result = service.build(input);

    expect(result.topStudents, hasLength(2));
    expect(result.topStudents.first.studentName, 'Ana');
    expect(result.topStudents.first.average, 4.5);

    expect(result.atRiskStudents, hasLength(1));
    expect(result.atRiskStudents.single.studentName, 'Bob');
    expect(result.atRiskStudents.single.average, 2.5);
  });
}
