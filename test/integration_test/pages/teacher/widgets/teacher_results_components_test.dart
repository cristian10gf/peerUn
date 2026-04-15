import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_detail_body.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_overview_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TeacherResultsOverviewBody renders groups and reports tapped index',
      (tester) async {
    var tappedIndex = -1;
    const vm = TeacherResultsOverviewVm(
      overallAverageLabel: '4.0',
      groupCountLabel: '2',
      hasGroups: true,
      groups: [
        TeacherResultsGroupCardVm(
          index: 0,
          name: 'Equipo Alfa',
          average: 4.2,
          progress: 0.73,
          averageLabel: '4.2',
        ),
        TeacherResultsGroupCardVm(
          index: 1,
          name: 'Equipo Beta',
          average: 3.8,
          progress: 0.60,
          averageLabel: '3.8',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        TeacherResultsOverviewBody(
          vm: vm,
          onGroupTap: (index) => tappedIndex = index,
        ),
      ),
    );

    expect(find.byKey(const Key('results-overview-panel')), findsOneWidget);
    expect(find.text('Equipo Alfa'), findsOneWidget);
    expect(find.text('Equipo Beta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('results-group-card-1')));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('TeacherResultsDetailBody renders criteria and student values',
      (tester) async {
    const vm = TeacherResultsDetailVm(
      groupName: 'Equipo Alfa',
      criteria: [
        TeacherResultsCriterionVm(
          id: 'punct',
          label: 'Puntualidad',
          score: 4.6,
          progress: 0.86,
          scoreLabel: '4.6',
        ),
        TeacherResultsCriterionVm(
          id: 'contrib',
          label: 'Contribucion',
          score: 3.7,
          progress: 0.56,
          scoreLabel: '3.7',
        ),
      ],
      students: [
        TeacherResultsStudentVm(
          initial: 'AL',
          name: 'Ana Lopez',
          score: 4.4,
          scoreLabel: '4.4',
        ),
        TeacherResultsStudentVm(
          initial: 'BR',
          name: 'Bruno Ruiz',
          score: 3.9,
          scoreLabel: '3.9',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(const TeacherResultsDetailBody(vm: vm)));

    expect(find.byKey(const Key('results-detail-panel')), findsOneWidget);

    expect(find.text('Puntualidad'), findsOneWidget);
    expect(find.text('Contribucion'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text('3.7'), findsOneWidget);

    expect(find.text('Ana Lopez'), findsOneWidget);
    expect(find.text('Bruno Ruiz'), findsOneWidget);
    expect(find.text('4.4'), findsOneWidget);
    expect(find.text('3.9'), findsOneWidget);
  });
}
