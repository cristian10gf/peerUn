import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TeacherResultsViewMapper mapper;

  setUp(() {
    mapper = const TeacherResultsViewMapper();
  });

  test('buildOverview matches Task 1 overview contract', () {
    final groups = <GroupResult>[
      const GroupResult(
        name: 'Equipo A',
        average: 4.0,
        criteria: <double>[4.0, 4.0, 4.0, 4.0],
        students: <StudentResult>[],
      ),
      const GroupResult(
        name: 'Equipo B',
        average: 0.0,
        criteria: <double>[0.0, 0.0, 0.0, 0.0],
        students: <StudentResult>[],
      ),
      const GroupResult(
        name: 'Equipo C',
        average: -1.0,
        criteria: <double>[0.0, 0.0, 0.0, 0.0],
        students: <StudentResult>[],
      ),
    ];

    final TeacherResultsOverviewVm overview = mapper.buildOverview(groups);

    expect(overview.overallAverageLabel, '4.0');
    expect(overview.groupCountLabel, '3');
    expect(overview.hasGroups, isTrue);

    expect(overview.groups, hasLength(3));
    final TeacherResultsGroupCardVm firstGroup = overview.groups[0];
    expect(firstGroup.index, 0);
    expect(firstGroup.name, 'Equipo A');
    expect(firstGroup.average, 4.0);
    expect(firstGroup.progress, closeTo(0.6666666667, 1e-9));
    expect(firstGroup.averageLabel, '4.0');

    final TeacherResultsGroupCardVm secondGroup = overview.groups[1];
    expect(secondGroup.index, 1);
    expect(secondGroup.average, 0.0);
    expect(secondGroup.progress, 0.0);
    expect(secondGroup.averageLabel, '0.0');
  });

  test('buildOverview uses dash label when all averages are non-positive', () {
    final groups = <GroupResult>[
      const GroupResult(
        name: 'Equipo B',
        average: 0.0,
        criteria: <double>[0.0, 0.0, 0.0, 0.0],
        students: <StudentResult>[],
      ),
      const GroupResult(
        name: 'Equipo C',
        average: -1.0,
        criteria: <double>[0.0, 0.0, 0.0, 0.0],
        students: <StudentResult>[],
      ),
    ];

    final TeacherResultsOverviewVm overview = mapper.buildOverview(groups);

    expect(overview.overallAverageLabel, '-');
    expect(overview.groupCountLabel, '2');
    expect(overview.hasGroups, isTrue);
  });

  test('buildOverview sets hasGroups false for empty input', () {
    final TeacherResultsOverviewVm overview = mapper.buildOverview(
      const <GroupResult>[],
    );

    expect(overview.groupCountLabel, '0');
    expect(overview.overallAverageLabel, '-');
    expect(overview.hasGroups, isFalse);
  });

  test('buildDetail matches Task 1 detail contract', () {
    const group = GroupResult(
      name: 'Equipo Delta',
      average: 3.5,
      criteria: <double>[5.0, 3.5],
      students: <StudentResult>[
        StudentResult(initial: 'A', name: 'Ana', score: 4.5),
        StudentResult(initial: 'B', name: 'Beto', score: 0.0),
      ],
    );

    final TeacherResultsDetailVm detail = mapper.buildDetail(group);

    expect(detail.groupName, 'Equipo Delta');

    expect(detail.criteria, hasLength(4));
    expect(
      detail.criteria
          .map((TeacherResultsCriterionVm criterion) => criterion.id)
          .toList(),
      const <String>['punct', 'contrib', 'commit', 'attitude'],
    );
    expect(
      detail.criteria
          .map((TeacherResultsCriterionVm criterion) => criterion.label)
          .toList(),
      const <String>['PUNTU', 'CONTRIB', 'COMPRO', 'ACTITU'],
    );

    final TeacherResultsCriterionVm criterion0 = detail.criteria[0];
    expect(criterion0.score, 5.0);
    expect(criterion0.progress, 1.0);
    expect(criterion0.scoreLabel, '5.0');

    final TeacherResultsCriterionVm criterion1 = detail.criteria[1];
    expect(criterion1.id, 'contrib');
    expect(criterion1.label, 'CONTRIB');
    expect(criterion1.score, 3.5);
    expect(criterion1.progress, 0.5);
    expect(criterion1.scoreLabel, '3.5');

    final TeacherResultsCriterionVm criterion2 = detail.criteria[2];
    expect(criterion2.id, 'commit');
    expect(criterion2.label, 'COMPRO');
    expect(criterion2.score, 0.0);
    expect(criterion2.progress, 0.0);
    expect(criterion2.scoreLabel, '0.0');

    final TeacherResultsCriterionVm criterion3 = detail.criteria[3];
    expect(criterion3.id, 'attitude');
    expect(criterion3.label, 'ACTITU');
    expect(criterion3.score, 0.0);
    expect(criterion3.progress, 0.0);
    expect(criterion3.scoreLabel, '0.0');

    expect(detail.students, hasLength(2));

    final TeacherResultsStudentVm student0 = detail.students[0];
    expect(student0.initial, 'A');
    expect(student0.name, 'Ana');
    expect(student0.score, 4.5);
    expect(student0.scoreLabel, '4.5');

    final TeacherResultsStudentVm student1 = detail.students[1];
    expect(student1.initial, 'B');
    expect(student1.name, 'Beto');
    expect(student1.score, 0.0);
    expect(student1.scoreLabel, '0.0');
  });

  test('scoreLabel follows Task 1 zero and precision rules', () {
    expect(mapper.scoreLabel(0.0, dashWhenZero: true), '-');
    expect(mapper.scoreLabel(-5.0, dashWhenZero: true), '-');
    expect(mapper.scoreLabel(0.0), '0.0');
    expect(mapper.scoreLabel(-2.0), '0.0');
    expect(mapper.scoreLabel(3.14159), '3.1');
  });

  test('toProgress follows the fixed formula and clamp range', () {
    expect(mapper.toProgress(1.0), 0.0);
    expect(mapper.toProgress(2.0), 0.0);
    expect(mapper.toProgress(3.5), 0.5);
    expect(mapper.toProgress(5.0), 1.0);
    expect(mapper.toProgress(8.0), 1.0);
  });
}
