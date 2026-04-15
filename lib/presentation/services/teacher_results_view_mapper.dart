import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';

class TeacherResultsViewMapper {
  static const List<String> criteriaIds = <String>[
    'punct',
    'contrib',
    'commit',
    'attitude',
  ];

  static const List<String> criteriaLabels = <String>[
    'PUNTU',
    'CONTRIB',
    'COMPRO',
    'ACTITU',
  ];

  const TeacherResultsViewMapper();

  TeacherResultsOverviewVm buildOverview(List<GroupResult> groups) {
    final mappedGroups = groups
        .asMap()
        .entries
        .map(
          (entry) => TeacherResultsGroupCardVm(
            index: entry.key,
            name: entry.value.name,
            average: entry.value.average,
            progress: toProgress(entry.value.average),
            averageLabel: scoreLabel(entry.value.average),
          ),
        )
        .toList(growable: false);

    final nonZeroAverages = groups
        .where((group) => group.average > 0)
        .map((group) => group.average)
        .toList(growable: false);

    final overallAverage = _average(nonZeroAverages);

    return TeacherResultsOverviewVm(
      overallAverageLabel: scoreLabel(overallAverage, dashWhenZero: true),
      groupCountLabel: groups.length.toString(),
      groups: mappedGroups,
      hasGroups: groups.isNotEmpty,
    );
  }

  TeacherResultsDetailVm buildDetail(
    GroupResult group, {
    int groupIndex = 0,
  }) {
    final criteria = List<TeacherResultsCriterionVm>.generate(4, (
      index,
    ) {
      final value = index < group.criteria.length ? group.criteria[index] : 0.0;
      return TeacherResultsCriterionVm(
        id: criteriaIds[index],
        label: criteriaLabels[index],
        score: value,
        progress: toProgress(value),
        scoreLabel: scoreLabel(value),
      );
    }, growable: false);

    final students = group.students
        .map(
          (student) => TeacherResultsStudentVm(
            initial: student.initial,
            name: student.name,
            score: student.score,
            scoreLabel: scoreLabel(student.score),
          ),
        )
        .toList(growable: false);

    return TeacherResultsDetailVm(
      groupName: group.name,
      criteria: criteria,
      students: students,
    );
  }

  double toProgress(double value) {
    return ((value - 2) / 3).clamp(0.0, 1.0);
  }

  String scoreLabel(double value, {bool dashWhenZero = false}) {
    if (value <= 0) {
      return dashWhenZero ? '-' : '0.0';
    }
    return value.toStringAsFixed(1);
  }

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }
}
