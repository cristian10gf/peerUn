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

  TeacherResultsOverviewViewModel buildOverview(List<GroupResult> groups) {
    final mappedGroups = groups
        .asMap()
        .entries
        .map(
          (entry) => TeacherResultsOverviewGroupViewModel(
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

    return TeacherResultsOverviewViewModel(
      overallAverage: overallAverage,
      overallAverageLabel: scoreLabel(overallAverage),
      groupCountLabel: groups.length.toString(),
      groups: mappedGroups,
    );
  }

  TeacherResultsDetailViewModel buildDetail(
    GroupResult group, {
    int groupIndex = 0,
  }) {
    final criteria = List<TeacherResultsCriterionViewModel>.generate(4, (
      index,
    ) {
      final value = index < group.criteria.length ? group.criteria[index] : 0.0;
      return TeacherResultsCriterionViewModel(
        id: criteriaIds[index],
        label: criteriaLabels[index],
        value: value,
        progress: toProgress(value),
        scoreLabel: scoreLabel(value, dashWhenZero: true),
      );
    }, growable: false);

    final students = group.students
        .map(
          (student) => TeacherResultsStudentViewModel(
            initial: student.initial,
            name: student.name,
            score: student.score,
            progress: toProgress(student.score),
            scoreLabel: scoreLabel(student.score, dashWhenZero: true),
          ),
        )
        .toList(growable: false);

    return TeacherResultsDetailViewModel(
      groupIndex: groupIndex,
      groupName: group.name,
      average: group.average,
      progress: toProgress(group.average),
      averageLabel: scoreLabel(group.average),
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
