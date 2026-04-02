String normalizeProfileImageUrl(String value) {
  final trimmed = value.trim().replaceAll('"', '');
  if (trimmed.isEmpty) return trimmed;

  return trimmed
      .replaceFirst(
        'http://infinity-sharing.money/uploads/',
        'https://www.infinity-sharing.money/api/uploads/',
      )
      .replaceFirst(
        'https://infinity-sharing.money/uploads/',
        'https://www.infinity-sharing.money/api/uploads/',
      )
      .replaceFirst(
        'http://www.infinity-sharing.money/uploads/',
        'https://www.infinity-sharing.money/api/uploads/',
      )
      .replaceFirst(
        'https://www.infinity-sharing.money/uploads/',
        'https://www.infinity-sharing.money/api/uploads/',
      );
}
