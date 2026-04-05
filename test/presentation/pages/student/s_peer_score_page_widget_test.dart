import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_peer_score_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../helpers/controller_spies.dart';
import '../../../helpers/getx_test_harness.dart';

void main() {
  setUp(resetGetxTestState);

  testWidgets('SPeerScorePage renders current peer and 4 criteria cards',
      (tester) async {
    final ctrl = SpyStudentController();
    ctrl.currentPeer.value = Peer(id: '1', name: 'Bob Ruiz', initials: 'BR');

    Get.put<StudentController>(ctrl);
    await tester.pumpWidget(
      buildGetxTestApp(
        home: const SPeerScorePage(),
        extraRoutes: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: '/student/peers',
            page: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );

    expect(find.text('Bob Ruiz'), findsOneWidget);
    expect(find.textContaining('/4 criterios'), findsOneWidget);
  });
}
