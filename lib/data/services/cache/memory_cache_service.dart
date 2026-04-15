import 'package:example/domain/services/i_cache_service.dart';

class MemoryCacheService implements ICacheService {
  final _store = <String, String>{};

  @override
  Future<void> set(String key, String value) async => _store[key] = value;

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> invalidate(String key) async => _store.remove(key);

  @override
  Future<void> invalidateAll() async => _store.clear();
}
