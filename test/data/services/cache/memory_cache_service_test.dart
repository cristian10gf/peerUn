import 'package:flutter_test/flutter_test.dart';
import 'package:example/data/services/cache/memory_cache_service.dart';

void main() {
  group('MemoryCacheService', () {
    late MemoryCacheService cache;
    setUp(() => cache = MemoryCacheService());

    test('stores and retrieves a value', () async {
      await cache.set('k', 'v');
      expect(await cache.get('k'), 'v');
    });

    test('returns null for missing key', () async {
      expect(await cache.get('nope'), isNull);
    });

    test('overwrite replaces value', () async {
      await cache.set('k', 'first');
      await cache.set('k', 'second');
      expect(await cache.get('k'), 'second');
    });

    test('invalidate removes entry', () async {
      await cache.set('k', 'v');
      await cache.invalidate('k');
      expect(await cache.get('k'), isNull);
    });

    test('invalidate on missing key is no-op', () async {
      await cache.invalidate('ghost'); // must not throw
    });

    test('invalidateAll clears everything', () async {
      await cache.set('a', '1');
      await cache.set('b', '2');
      await cache.invalidateAll();
      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
    });

    test('different keys are independent', () async {
      await cache.set('x', 'X');
      await cache.set('y', 'Y');
      expect(await cache.get('x'), 'X');
      expect(await cache.get('y'), 'Y');
    });
  });
}
