import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peers_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SPeersPage shows submit button when all peers are evaluated',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentGroupName.value = 'Equipo A';
    ctrl.peers.addAll(<Peer>[
      Peer(id: '1', name: 'Bob', initials: 'BR', evaluated: true),
      Peer(id: '2', name: 'Luis', initials: 'LR', evaluated: true),
    ]);

    Get.put<StudentController>(ctrl);

    await tester.pumpWidget(buildGetxTestApp(home: const SPeersPage()));

    expect(find.text('Enviar evaluación completa'), findsOneWidget);
  });
}
