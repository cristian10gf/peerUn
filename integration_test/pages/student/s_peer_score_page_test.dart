import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peer_score_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/getx_test_harness.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/student/peers', page: () => const SizedBox.shrink()),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetGetxTestState);

  testWidgets('SPeerScorePage renders current peer name and criterion counter',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Bob Ruiz', initials: 'BR');

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeerScorePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Bob Ruiz'), findsOneWidget);
    expect(find.textContaining('/4 criterios'), findsOneWidget);
  });

  testWidgets('SPeerScorePage renders exactly 4 criterion cards', (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Ana', initials: 'AG');

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeerScorePage(), extraRoutes: _extraRoutes),
    );

    // Each criterion label should appear once.
    expect(find.text('Puntualidad'),    findsOneWidget);
    expect(find.text('Contribuciones'), findsOneWidget);
    expect(find.text('Compromiso'),     findsOneWidget);
    expect(find.text('Actitud'),        findsOneWidget);
  });

  testWidgets(
      'SPeerScorePage shows disabled submit text when criteria are incomplete',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Ana', initials: 'AG');
    // scores is empty → allCriteriaScored = false

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeerScorePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Completa los 4 criterios'), findsOneWidget);
    expect(find.text('Guardar y continuar'),      findsNothing);
  });

  testWidgets('SPeerScorePage shows Guardar button when all criteria scored',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Ana', initials: 'AG');
    // Score all 4 criteria.
    for (final c in EvalCriterion.defaults) {
      ctrl.setScore(c.id, 4);
    }

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeerScorePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Guardar y continuar'),      findsOneWidget);
    expect(find.text('Completa los 4 criterios'), findsNothing);
  });

  testWidgets('SPeerScorePage counter increments as criteria are scored',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Ana', initials: 'AG');

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeerScorePage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('0/4 criterios'), findsOneWidget);

    ctrl.setScore('punct', 5);
    await tester.pump();

    expect(find.text('1/4 criterios'), findsOneWidget);
  });
}
