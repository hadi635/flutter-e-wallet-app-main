String normalizePublicUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;

  return trimmed.replaceFirst(
    'http://infinity-sharing.money',
    'https://infinity-sharing.money',
  );
}
