/// Converts a raw API/exception error into a clean, user-readable message.
///
/// Handles the Roble API error format:
///   RobleApiError inesperado:\nRobleApiException: HTTP 400:\n[message]
String parseApiError(
  Object error, {
  String fallback = 'Error inesperado',
}) {
  String raw = error.toString().trim();

  // Strip outermost "RobleApiError inesperado:\n" wrapper.
  raw = raw.replaceFirst(
    RegExp(r'^RobleApiError\s+inesperado\s*:\s*\n?', caseSensitive: false),
    '',
  );

  // Strip "RobleApiException: HTTP NNN:\n" (with optional spaces/newlines).
  raw = raw.replaceFirst(
    RegExp(r'^RobleApiException\s*:\s*HTTP\s*\d+\s*:\s*\n?', caseSensitive: false),
    '',
  );

  // Strip plain "Exception: " prefix.
  raw = raw.replaceFirst(RegExp(r'^Exception\s*:\s*'), '');

  raw = raw.trim();

  // Unwrap "[message]" bracket notation used by Roble validation errors.
  final bracketMatch = RegExp(r'^\[(.+)\]$', dotAll: true).firstMatch(raw);
  if (bracketMatch != null) {
    raw = bracketMatch.group(1)!.trim();
  }

  return raw.isEmpty ? fallback : raw;
}

/// Same as [parseApiError] but maps well-known HTTP status codes to friendly
/// Spanish messages before falling back to the extracted text.
String parseApiErrorFriendly(
  Object error, {
  String fallback = 'Error inesperado',
  Map<String, String> overrides = const {},
}) {
  final raw = error.toString();

  // Check for status code overrides first.
  if (raw.contains('401')) {
    return overrides['401'] ?? 'Correo o contraseña incorrectos';
  }
  if (raw.contains('409') ||
      raw.toLowerCase().contains('registrado') ||
      raw.toLowerCase().contains('already') ||
      raw.toLowerCase().contains('duplicate')) {
    return overrides['409'] ?? 'El correo ya está registrado';
  }
  if (raw.contains('503') || raw.contains('sin conexion') || raw.contains('sin conexión')) {
    return overrides['503'] ?? 'Sin conexión a internet';
  }

  return parseApiError(error, fallback: fallback);
}
