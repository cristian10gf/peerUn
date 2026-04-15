import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TeacherResultsViewMapper mapper;

  setUp(() {
    mapper = const TeacherResultsViewMapper();
  });

  test('buildOverview ignores zero-score groups for overall average', () {
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

    final vm = mapper.buildOverview(groups);

    expect(vm.overallAverage, 4.0);
    expect(vm.overallAverageLabel, '4.0');
    expect(vm.groupCountLabel, '3');

    expect(vm.groups, hasLength(3));
    expect(vm.groups[0].index, 0);
    expect(vm.groups[0].average, 4.0);
    expect(vm.groups[0].progress, closeTo(0.6666666667, 1e-9));
    expect(vm.groups[0].averageLabel, '4.0');

    expect(vm.groups[1].index, 1);
    expect(vm.groups[1].average, 0.0);
    expect(vm.groups[1].progress, 0.0);
    expect(vm.groups[1].averageLabel, '0.0');
  });

  test('buildDetail maps criteria and students with progress values', () {
    const group = GroupResult(
      name: 'Equipo Delta',
      average: 3.5,
      criteria: <double>[5.0, 3.5],
      students: <StudentResult>[
        StudentResult(initial: 'A', name: 'Ana', score: 4.5),
        StudentResult(initial: 'B', name: 'Beto', score: 0.0),
      ],
    );

    final vm = mapper.buildDetail(group, groupIndex: 7);

    expect(vm.groupName, 'Equipo Delta');
    expect(vm.groupIndex, 7);

    expect(vm.criteria, hasLength(4));
    expect(vm.criteria[0].id, 'punct');
    expect(vm.criteria[0].label, 'PUNTU');
    expect(vm.criteria[0].value, 5.0);
    expect(vm.criteria[0].progress, 1.0);
    expect(vm.criteria[0].scoreLabel, '5.0');

    expect(vm.criteria[1].id, 'contrib');
    expect(vm.criteria[1].label, 'CONTRIB');
    expect(vm.criteria[1].value, 3.5);
    expect(vm.criteria[1].progress, 0.5);
    expect(vm.criteria[1].scoreLabel, '3.5');

    expect(vm.criteria[2].id, 'commit');
    expect(vm.criteria[2].label, 'COMPRO');
    expect(vm.criteria[2].value, 0.0);
    expect(vm.criteria[2].progress, 0.0);
    expect(vm.criteria[2].scoreLabel, '-');

    expect(vm.criteria[3].id, 'attitude');
    expect(vm.criteria[3].label, 'ACTITU');
    expect(vm.criteria[3].value, 0.0);
    expect(vm.criteria[3].progress, 0.0);
    expect(vm.criteria[3].scoreLabel, '-');

    expect(vm.students, hasLength(2));
    expect(vm.students[0].initial, 'A');
    expect(vm.students[0].name, 'Ana');
    expect(vm.students[0].score, 4.5);
    expect(vm.students[0].progress, closeTo(0.8333333333, 1e-9));
    expect(vm.students[0].scoreLabel, '4.5');

    expect(vm.students[1].initial, 'B');
    expect(vm.students[1].name, 'Beto');
    expect(vm.students[1].score, 0.0);
    expect(vm.students[1].progress, 0.0);
    expect(vm.students[1].scoreLabel, '-');
  });
}
