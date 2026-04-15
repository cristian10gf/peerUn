import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/domain/services/i_cache_service.dart';

/// Cache that persists data across app restarts via SharedPreferences.
/// All keys are prefixed with [_prefix] to avoid colliding with session
/// keys written by DatabaseServiceSession.
class SharedPreferencesCacheService implements ICacheService {
  static const _prefix = 'evalia_cache_v1_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> set(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(_prefix + key, value);
  }

  @override
  Future<String?> get(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(_prefix + key);
  }

  @override
  Future<void> invalidate(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(_prefix + key);
  }

  @override
  Future<void> invalidateAll() async {
    final prefs = await _getPrefs();
    final cacheKeys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in cacheKeys) {
      await prefs.remove(k);
    }
  }
}
