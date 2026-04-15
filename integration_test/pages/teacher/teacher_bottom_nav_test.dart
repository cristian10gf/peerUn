import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/getx_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  testWidgets(
    'tapping active DATOS item does not throw when route context is unavailable',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: tkBackground,
            bottomNavigationBar: TeacherBottomNav(activeIndex: 2),
          ),
        ),
      );

      await tester.tap(find.text('DATOS'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigates to data-insights route when DATOS is tapped', (
    tester,
  ) async {
    final routes = <GetPage<dynamic>>[
      GetPage(
        name: '/teacher/data-insights',
        page: () => const Scaffold(body: Text('DATA-INSIGHTS-ROUTE')),
      ),
      GetPage(
        name: '/teacher/dash',
        page: () => const Scaffold(body: Text('DASH-ROUTE')),
      ),
      GetPage(
        name: '/teacher/new-eval',
        page: () => const Scaffold(body: Text('NEW-EVAL-ROUTE')),
      ),
      GetPage(
        name: '/teacher/import',
        page: () => const Scaffold(body: Text('IMPORT-ROUTE')),
      ),
    ];

    await tester.pumpWidget(
      buildGetxTestApp(
        home: const Scaffold(
          backgroundColor: tkBackground,
          bottomNavigationBar: TeacherBottomNav(activeIndex: 0),
        ),
        extraRoutes: routes,
      ),
    );

    await tester.tap(find.text('DATOS'));
    await tester.pumpAndSettle();

    expect(find.text('DATA-INSIGHTS-ROUTE'), findsOneWidget);
  });
}
