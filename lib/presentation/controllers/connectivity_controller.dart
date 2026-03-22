import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:example/domain/repositories/i_connectivity_repository.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  final IConnectivityRepository _connectivityRepository;

  ConnectivityController(this._connectivityRepository);

  final isConnected = true.obs;
  final activeTypes = <ConnectivityResult>[].obs;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<List<ConnectivityResult>>? _typesSub;

  String get statusMessage => isConnected.value
      ? 'Con conexión de red. Puedes realizar acciones en línea.'
      : 'Sin conexión a internet. Inicia sesión y registro estarán deshabilitados.';

  String get shortStatusLabel => isConnected.value ? 'En linea' : 'Sin internet';

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  Future<void> _boot() async {
    isConnected.value = await _connectivityRepository.hasNetworkConnection();

    _connectionSub = _connectivityRepository
        .watchNetworkConnection()
        .listen((connected) => isConnected.value = connected);

    _typesSub = _connectivityRepository
        .watchConnectivityTypes()
        .listen((types) => activeTypes.assignAll(types));
  }

  @override
  void onClose() {
    _connectionSub?.cancel();
    _typesSub?.cancel();
    super.onClose();
  }
}
