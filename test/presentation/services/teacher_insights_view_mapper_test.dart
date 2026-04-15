import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TeacherInsightsViewMapper();

  test('maps aggregate into ordered view model blocks', () {
    final aggregate = TeacherInsightsAggregate(
      courseAverages: const <TeacherCourseAverage>[
        TeacherCourseAverage(
          courseId: 'c1',
          courseName: 'IS',
          average: 4.2,
          sampleCount: 20,
        ),
      ],
      categoryAverages: const <TeacherCategoryAverage>[
        TeacherCategoryAverage(
          categoryId: 'cat1',
          categoryName: 'Sprint',
          courseId: 'c1',
          courseName: 'IS',
          average: 4.0,
          sampleCount: 10,
        ),
      ],
      bestGroupsByCourse: const <TeacherBestGroup>[
        TeacherBestGroup(
          courseId: 'c1',
          courseName: 'IS',
          groupId: 'g1',
          groupName: 'Alfa',
          average: 4.5,
          sampleCount: 8,
        ),
      ],
      topStudents: const <TeacherStudentAverage>[
        TeacherStudentAverage(
          studentId: 's1',
          studentName: 'Ana',
          average: 4.6,
          sampleCount: 12,
        ),
      ],
      atRiskStudents: const <TeacherStudentAverage>[],
      evaluations: const <TeacherInsightsEvaluationCoverage>[
        TeacherInsightsEvaluationCoverage(
          evaluationId: 'e1',
          evaluationName: 'Eval 1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
        ),
      ],
    );

    final vm = mapper.build(aggregate);

    expect(vm.overallAverageLabel, '4.2');
    expect(vm.evaluationsCountLabel, '1');
    expect(vm.validScoresCountLabel, '20');

    expect(vm.courseAverages.single.averageLabel, '4.2');
    expect(vm.bestGroups.single.groupName, 'Alfa');
    expect(vm.topStudents.single.studentName, 'Ana');
    expect(vm.atRiskStudents, isEmpty);

    expect(vm.showNoEvaluationsState, isFalse);
    expect(vm.showNoResponsesState, isFalse);
    expect(vm.isCourseSectionEmpty, isFalse);
    expect(vm.isAtRiskSectionEmpty, isTrue);

    expect(vm.evaluations.single.evaluationName, 'Eval 1');
  });

  test('sets no-responses state when evaluations exist but no score data', () {
    final aggregate = TeacherInsightsAggregate(
      courseAverages: const <TeacherCourseAverage>[],
      categoryAverages: const <TeacherCategoryAverage>[],
      bestGroupsByCourse: const <TeacherBestGroup>[],
      topStudents: const <TeacherStudentAverage>[],
      atRiskStudents: const <TeacherStudentAverage>[],
      evaluations: const <TeacherInsightsEvaluationCoverage>[
        TeacherInsightsEvaluationCoverage(
          evaluationId: 'e1',
          evaluationName: 'Eval 1',
          courseId: 'c1',
          courseName: 'IS',
          categoryId: 'cat1',
          categoryName: 'Sprint',
        ),
      ],
    );

    final vm = mapper.build(aggregate);

    expect(vm.showNoEvaluationsState, isFalse);
    expect(vm.showNoResponsesState, isTrue);
    expect(vm.overallAverageLabel, '-');
    expect(vm.validScoresCountLabel, '0');
    expect(vm.evaluationsCountLabel, '1');
  });

  test('sets no-evaluations state when coverage list is empty', () {
    final aggregate = TeacherInsightsAggregate(
      courseAverages: const <TeacherCourseAverage>[],
      categoryAverages: const <TeacherCategoryAverage>[],
      bestGroupsByCourse: const <TeacherBestGroup>[],
      topStudents: const <TeacherStudentAverage>[],
      atRiskStudents: const <TeacherStudentAverage>[],
      evaluations: const <TeacherInsightsEvaluationCoverage>[],
    );

    final vm = mapper.build(aggregate);

    expect(vm.showNoEvaluationsState, isTrue);
    expect(vm.showNoResponsesState, isFalse);
    expect(vm.evaluations, isEmpty);
  });
}
