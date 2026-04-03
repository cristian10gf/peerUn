String normalizeEmail(
  String value, {
  String defaultDomain = 'uninorte.edu.co',
}) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('@')) return normalized;
  return '$normalized@$defaultDomain';
}
