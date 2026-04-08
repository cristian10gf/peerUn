import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

final _extraRoutes = <GetPage>[
  GetPage(name: '/student/peer-score', page: () => const SizedBox.shrink()),
  GetPage(name: '/student/courses',    page: () => const SizedBox.shrink()),
];

void main() {
  setUp(resetGetxTestState);

  testWidgets('SPeersPage shows submit button when all peers are evaluated',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentGroupName.value = 'Equipo A';
    ctrl.peers.addAll(<Peer>[
      Peer(id: '1', name: 'Bob',  initials: 'BR', evaluated: true),
      Peer(id: '2', name: 'Luis', initials: 'LR', evaluated: true),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeersPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Enviar evaluación completa'), findsOneWidget);
  });

  testWidgets('SPeersPage hides submit button when not all peers are evaluated',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.peers.addAll(<Peer>[
      Peer(id: '1', name: 'Bob',  initials: 'BR', evaluated: true),
      Peer(id: '2', name: 'Luis', initials: 'LR', evaluated: false),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeersPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Enviar evaluación completa'), findsNothing);
  });

  testWidgets('SPeersPage lists all peer names', (tester) async {
    final ctrl = SpyStudentController();
    ctrl.peers.addAll(<Peer>[
      Peer(id: '1', name: 'Ana García',   initials: 'AG'),
      Peer(id: '2', name: 'Pedro López',  initials: 'PL'),
      Peer(id: '3', name: 'María Torres', initials: 'MT'),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeersPage(), extraRoutes: _extraRoutes),
    );

    expect(find.text('Ana García'),   findsOneWidget);
    expect(find.text('Pedro López'),  findsOneWidget);
    expect(find.text('María Torres'), findsOneWidget);
  });

  testWidgets('SPeersPage shows group name and progress in header',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentGroupName.value = 'Equipo Rojo';
    ctrl.peers.addAll(<Peer>[
      Peer(id: '1', name: 'A', initials: 'A', evaluated: true),
      Peer(id: '2', name: 'B', initials: 'B', evaluated: false),
    ]);

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeersPage(), extraRoutes: _extraRoutes),
    );

    // Header: "Equipo Rojo · 1/2 evaluados"
    expect(find.textContaining('Equipo Rojo'), findsOneWidget);
    expect(find.textContaining('1/2 evaluados'), findsOneWidget);
  });

  testWidgets('SPeersPage peer card tap navigates to peer-score page',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.activeEvalDb.value = Evaluation(
      id: 1,
      name: 'E',
      categoryId: 1,
      categoryName: 'C',
      hours: 24,
      visibility: 'private',
      createdAt: DateTime.now(),
      closesAt: DateTime.now().add(const Duration(hours: 24)),
    );
    ctrl.peers.add(Peer(id: '1', name: 'Bob Ruiz', initials: 'BR'));

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(home: const SPeersPage(), extraRoutes: _extraRoutes),
    );

    await tester.tap(find.text('Bob Ruiz'));
    await tester.pumpAndSettle();

    // Should have navigated to /student/peer-score (stubbed as SizedBox).
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
