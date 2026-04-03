import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:example/data/services/connectivity_service.dart';
import 'package:example/domain/repositories/i_connectivity_repository.dart';

class ConnectivityRepositoryImpl implements IConnectivityRepository {
  final ConnectivityService _service;

  ConnectivityRepositoryImpl(this._service);

  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<bool> hasNetworkConnection() async {
    final current = await _service.checkConnectivity();
    return _isConnected(current);
  }

  @override
  Stream<bool> watchNetworkConnection() {
    return _service.onConnectivityChanged().map(_isConnected).distinct();
  }

  @override
  Stream<List<ConnectivityResult>> watchConnectivityTypes() {
    return _service.onConnectivityChanged();
  }
}
