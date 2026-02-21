List<String> parseInstructions(String raw) {
  if (raw.trim().isEmpty) return [];

  final cleaned = raw
      .replaceAll(RegExp(r'<[^>]*>'), '\n')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();

  return cleaned
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}
