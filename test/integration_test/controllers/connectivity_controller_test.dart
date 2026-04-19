import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/repository_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('status labels change when connectivity stream emits offline', () async {
    final repo = FakeConnectivityRepository(connected: true);
    final ctrl = ConnectivityController(repo);

    ctrl.onInit();
    await pumpEventQueue();
    expect(ctrl.shortStatusLabel, 'En linea');

    repo.emit(false);
    await pumpEventQueue();

    expect(ctrl.shortStatusLabel, 'Sin internet');
    expect(ctrl.isConnected.value, false);
    expect(ctrl.activeTypes, <ConnectivityResult>[ConnectivityResult.none]);

    await repo.close();
    ctrl.onClose();
  });
}
