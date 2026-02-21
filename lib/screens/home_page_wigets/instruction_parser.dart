List<String> parseInstruction(String raw) {
  if (raw.trim().isEmpty) return [];

  return raw
      .replaceAll(RegExp(r'<[^>]*>'), '\n')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\n+'), '\n')
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}
