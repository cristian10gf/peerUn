// lib/domain/services/i_cache_service.dart

/// Key-value cache for recently fetched API data.
/// Stores JSON strings keyed by a stable string key.
/// No Flutter or platform imports — pure Dart.
abstract class ICacheService {
  /// Stores [value] (JSON string) under [key], replacing any prior value.
  Future<void> set(String key, String value);

  /// Returns the stored JSON string for [key], or null if absent.
  Future<String?> get(String key);

  /// Removes the entry for [key] (no-op if absent).
  Future<void> invalidate(String key);

  /// Removes ALL entries.
  Future<void> invalidateAll();
}
