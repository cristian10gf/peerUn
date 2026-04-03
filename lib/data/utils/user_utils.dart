String buildDisplayNameFromEmail(String email, {String fallback = 'User'}) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return fallback;
  return local
      .split(RegExp(r'[._-]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}
