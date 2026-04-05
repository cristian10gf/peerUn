import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:example/data/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> current = const <ConnectivityResult>[
    ConnectivityResult.none,
  ];
  int checkCalls = 0;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    checkCalls++;
    return current;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> values) {
    _controller.add(values);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  late ConnectivityPlatform originalPlatform;
  late _FakeConnectivityPlatform fakePlatform;

  setUp(() {
    originalPlatform = ConnectivityPlatform.instance;
    fakePlatform = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fakePlatform;
  });

  tearDown(() async {
    ConnectivityPlatform.instance = originalPlatform;
    await fakePlatform.dispose();
  });

  test('checkConnectivity delegates to connectivity plugin', () async {
    fakePlatform.current = const <ConnectivityResult>[ConnectivityResult.wifi];
    final service = ConnectivityService(connectivity: Connectivity());

    final result = await service.checkConnectivity();

    expect(result, const <ConnectivityResult>[ConnectivityResult.wifi]);
    expect(fakePlatform.checkCalls, 1);
  });

  test('onConnectivityChanged emits plugin events', () async {
    final service = ConnectivityService(connectivity: Connectivity());

    final expectation = expectLater(
      service.onConnectivityChanged(),
      emitsInOrder(<dynamic>[
        const <ConnectivityResult>[ConnectivityResult.none],
        const <ConnectivityResult>[ConnectivityResult.mobile],
      ]),
    );

    fakePlatform.emit(const <ConnectivityResult>[ConnectivityResult.none]);
    fakePlatform.emit(const <ConnectivityResult>[ConnectivityResult.mobile]);

    await expectation;
  });
}
