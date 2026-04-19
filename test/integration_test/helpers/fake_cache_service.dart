// test/helpers/fake_cache_service.dart
import 'package:example/domain/services/i_cache_service.dart';

/// In-memory ICacheService for use in unit tests.
/// Tracks method calls for assertion in tests.
class FakeCacheService implements ICacheService {
  final _store = <String, String>{};

  /// Keys passed to [set], in order.
  final List<String> setCalls = [];

  /// Keys passed to [invalidate], in order.
  final List<String> invalidateCalls = [];

  int invalidateAllCalls = 0;

  /// Pre-populate the cache (simulates a warm cache hit).
  void seed(String key, String value) => _store[key] = value;

  @override
  Future<void> set(String key, String value) async {
    setCalls.add(key);
    _store[key] = value;
  }

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> invalidate(String key) async {
    invalidateCalls.add(key);
    _store.remove(key);
  }

  @override
  Future<void> invalidateAll() async {
    invalidateAllCalls++;
    _store.clear();
  }
}
