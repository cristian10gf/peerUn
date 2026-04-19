import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/pages/teacher/t_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/fake_cache_service.dart';
import '../../helpers/getx_test_harness.dart';
import '../../helpers/repository_fakes.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/teacher/import',  page: () => const SizedBox.shrink()),
  GetPage(name: '/teacher/profile', page: () => const SizedBox.shrink()),
  GetPage(name: '/login',           page: () => const SizedBox.shrink()),
];

void _register(SpyTeacherSessionController session) {
  final gr = FakeGroupRepository();
  Get.put<TeacherSessionController>(session);
  Get.put<TeacherCourseImportController>(
    TeacherCourseImportController(
      session, gr, FakeCourseRepository(), TeacherImportCsvUseCase(gr), FakeCacheService(),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  testWidgets('TProfilePage renders teacher name and logout button',
      (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '1', name: 'Docente Uno', email: 'doc@uni.edu', initials: 'DU'),
    );
    _register(session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TProfilePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Docente Uno'), findsOneWidget);
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(session.logoutCalled, isTrue);
  });

  testWidgets('TProfilePage displays teacher email', (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(
        id: '2',
        name: 'Docente Dos',
        email: 'docente2@uni.edu',
        initials: 'DD',
      ),
    );
    _register(session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TProfilePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('docente2@uni.edu'), findsOneWidget);
  });

  testWidgets('TProfilePage shows initials avatar', (tester) async {
    final session = SpyTeacherSessionController();
    session.setTeacherSession(
      const Teacher(id: '3', name: 'Pedro Cruz', email: 'p@uni.edu', initials: 'PC'),
    );
    _register(session);

    await tester.pumpWidget(
      buildGetxTestApp(home: const TProfilePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('PC'), findsOneWidget);
  });
}
