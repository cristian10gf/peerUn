import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class IConnectivityRepository {
  Future<bool> hasNetworkConnection();
  Stream<bool> watchNetworkConnection();

  // Exposed for optional UI diagnostics.
  Stream<List<ConnectivityResult>> watchConnectivityTypes();
}
