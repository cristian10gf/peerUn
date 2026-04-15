import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/data/services/cache/shared_prefs_cache_service.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences to an empty in-memory store before each test.
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesCacheService', () {
    test('stores and retrieves a value', () async {
      final cache = SharedPreferencesCacheService();
      await cache.set('k', 'v');
      expect(await cache.get('k'), 'v');
    });

    test('returns null for missing key', () async {
      final cache = SharedPreferencesCacheService();
      expect(await cache.get('nope'), isNull);
    });

    test('overwrite replaces value', () async {
      final cache = SharedPreferencesCacheService();
      await cache.set('k', 'first');
      await cache.set('k', 'second');
      expect(await cache.get('k'), 'second');
    });

    test('invalidate removes entry', () async {
      final cache = SharedPreferencesCacheService();
      await cache.set('k', 'v');
      await cache.invalidate('k');
      expect(await cache.get('k'), isNull);
    });

    test('invalidate on missing key is no-op', () async {
      final cache = SharedPreferencesCacheService();
      await cache.invalidate('ghost'); // must not throw
    });

    test('invalidateAll clears only cache entries', () async {
      final cache = SharedPreferencesCacheService();
      await cache.set('a', '1');
      await cache.set('b', '2');

      // Simulate a non-cache key already in SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('student_session', 'should_survive');

      await cache.invalidateAll();

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
      // Session data must NOT be wiped.
      expect(prefs.getString('student_session'), 'should_survive');
    });

    test('invalidateAll on empty store is no-op', () async {
      final cache = SharedPreferencesCacheService();
      await cache.invalidateAll(); // must not throw when no cache keys exist
    });

    test('different keys are independent', () async {
      final cache = SharedPreferencesCacheService();
      await cache.set('x', 'X');
      await cache.set('y', 'Y');
      expect(await cache.get('x'), 'X');
      expect(await cache.get('y'), 'Y');
    });

    test('data persists across instances (same SharedPreferences backend)', () async {
      final first = SharedPreferencesCacheService();
      await first.set('persist', 'yes');

      // New instance — SharedPreferences is process-global, data persists.
      final second = SharedPreferencesCacheService();
      expect(await second.get('persist'), 'yes');
    });
  });
}
