import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:example/data/repositories/connectivity_repository_impl.dart';
import 'package:example/data/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityService extends ConnectivityService {
  final Future<List<ConnectivityResult>> Function() _check;
  final Stream<List<ConnectivityResult>> Function() _watch;

  _FakeConnectivityService({
    required Future<List<ConnectivityResult>> Function() check,
    required Stream<List<ConnectivityResult>> Function() watch,
  }) : _check = check,
       _watch = watch,
       super(connectivity: Connectivity());

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => _check();

  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged() => _watch();
}

void main() {
  test('hasNetworkConnection returns true for non-none connectivity', () async {
    final service = _FakeConnectivityService(
      check: () async => const <ConnectivityResult>[ConnectivityResult.wifi],
      watch: () => const Stream<List<ConnectivityResult>>.empty(),
    );

    final repo = ConnectivityRepositoryImpl(service);
    final connected = await repo.hasNetworkConnection();

    expect(connected, isTrue);
  });

  test('hasNetworkConnection returns false for empty or none connectivity', () async {
    final emptyService = _FakeConnectivityService(
      check: () async => const <ConnectivityResult>[],
      watch: () => const Stream<List<ConnectivityResult>>.empty(),
    );
    final noneService = _FakeConnectivityService(
      check: () async => const <ConnectivityResult>[ConnectivityResult.none],
      watch: () => const Stream<List<ConnectivityResult>>.empty(),
    );

    final emptyRepo = ConnectivityRepositoryImpl(emptyService);
    final noneRepo = ConnectivityRepositoryImpl(noneService);

    expect(await emptyRepo.hasNetworkConnection(), isFalse);
    expect(await noneRepo.hasNetworkConnection(), isFalse);
  });

  test('watchNetworkConnection maps types to bool and removes duplicates', () async {
    final controller = StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(controller.close);

    final service = _FakeConnectivityService(
      check: () async => const <ConnectivityResult>[ConnectivityResult.none],
      watch: () => controller.stream,
    );

    final repo = ConnectivityRepositoryImpl(service);
    final expectation = expectLater(
      repo.watchNetworkConnection(),
      emitsInOrder(<dynamic>[false, true, false]),
    );

    controller.add(const <ConnectivityResult>[ConnectivityResult.none]);
    controller.add(const <ConnectivityResult>[ConnectivityResult.none]);
    controller.add(const <ConnectivityResult>[ConnectivityResult.wifi]);
    controller.add(const <ConnectivityResult>[ConnectivityResult.mobile]);
    controller.add(const <ConnectivityResult>[ConnectivityResult.none]);

    await expectation;
  });

  test('watchConnectivityTypes forwards connectivity stream unchanged', () async {
    final controller = StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(controller.close);

    final service = _FakeConnectivityService(
      check: () async => const <ConnectivityResult>[ConnectivityResult.none],
      watch: () => controller.stream,
    );

    final repo = ConnectivityRepositoryImpl(service);
    final expectation = expectLater(
      repo.watchConnectivityTypes(),
      emitsInOrder(<dynamic>[
        const <ConnectivityResult>[ConnectivityResult.wifi],
        const <ConnectivityResult>[
          ConnectivityResult.mobile,
          ConnectivityResult.bluetooth,
        ],
      ]),
    );

    controller.add(const <ConnectivityResult>[ConnectivityResult.wifi]);
    controller.add(
      const <ConnectivityResult>[
        ConnectivityResult.mobile,
        ConnectivityResult.bluetooth,
      ],
    );

    await expectation;
  });
}
