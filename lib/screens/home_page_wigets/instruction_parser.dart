List<String> parseInstruction(String raw) {
  if (raw.trim().isEmpty) return [];

  final cleaned = _prepareInstructionText(raw);

  final extractedSetSteps = _extractSetInstructions(cleaned);
  if (extractedSetSteps.isNotEmpty) {
    return extractedSetSteps;
  }

  final fragments = cleaned
      .split('\n')
      .expand((line) => line.split(RegExp(r'(?=\d+\.\s*)')))
      .map((e) => e.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final List<String> merged = <String>[];
  String current = '';

  for (final fragment in fragments) {
    final hasStepNumber = RegExp(r'^\d+\.\s*').hasMatch(fragment);
    final text = fragment.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
    if (text.isEmpty) continue;

    if (current.isEmpty) {
      current = text;
      continue;
    }

    if (hasStepNumber && _isInstructionComplete(current)) {
      merged.add(_normalizeInstructionText(current));
      current = text;
    } else {
      current = '$current $text'.trim();
    }
  }

  if (current.isNotEmpty) {
    merged.add(_normalizeInstructionText(current));
  }

  return merged.expand(_splitRepeatedSetSegments).toList();
}

String _prepareInstructionText(String raw) {
  var cleaned = raw
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s*(•|·)\s*'), '\n');

  // Some payloads arrive like "18-2. Set..." where the trailing hyphen is
  // only a broken separator before the next numbered instruction.
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z0-9])\s*[-–—]+\s*(?=\d+\s*[\.\)])'),
    (match) => '${match.group(1)}\n',
  );

  return cleaned.trim();
}

List<String> _extractSetInstructions(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final matches = RegExp(
    r'(?:\d+\.\s*)?(set\b.*?)(?=(?:\d+\.\s*)?set\b|$)',
    caseSensitive: false,
  ).allMatches(normalized);

  final results = matches
      .map((m) => _normalizeInstructionText((m.group(1) ?? '').trim()))
      .where((e) => e.isNotEmpty)
      .toList();

  return results.length >= 2 ? results : <String>[];
}

bool _isInstructionComplete(String text) {
  final normalized = text.toLowerCase();
  return RegExp(
    r'\b(rep|reps|kg|kgs|sec|secs|second|seconds|min|mins|minute|minutes|time|times|x)\b',
  ).hasMatch(normalized);
}

String _normalizeInstructionText(String text) {
  var normalized = text.replaceAll('\$', '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  normalized = normalized.replaceAll(RegExp(r'\s*=\s*'), ' = ');
  normalized = normalized.replaceAllMapped(
    RegExp(r'(\d)\s*-\s*(\d)'),
    (match) => '${match.group(1)} - ${match.group(2)}',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'(\d)(reps?|sets?|kg|kgs|sec|secs|min|mins)\b',
        caseSensitive: false),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'\b(kg|kgs|sec|secs|min|mins)(\d)', caseSensitive: false),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  normalized = normalized.replaceAll(RegExp(r'\(\s+'), '(');
  normalized = normalized.replaceAll(RegExp(r'\s+\)'), ')');
  normalized = normalized.replaceAllMapped(
    RegExp(r'\bset\s*=', caseSensitive: false),
    (_) => 'Set =',
  );
  normalized = normalized.replaceFirst(
    RegExp(r'^set\b', caseSensitive: false),
    'Set',
  );
  normalized = normalized.replaceFirst(RegExp(r'\s*[-–—]+\s*$'), '');
  return normalized.trim();
}

List<String> _splitRepeatedSetSegments(String text) {
  final normalized = _normalizeInstructionText(text);
  final matches = RegExp(
    r'\bset\b(?=\s*(?:=|\d))',
    caseSensitive: false,
  ).allMatches(normalized).toList();

  if (matches.length <= 1) {
    return <String>[normalized];
  }

  final segments = <String>[];
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].start;
    final end =
        i + 1 < matches.length ? matches[i + 1].start : normalized.length;
    final part = normalized.substring(start, end).trim();
    if (part.isNotEmpty) {
      segments.add(_normalizeInstructionText(part));
    }
  }
  return segments.isEmpty ? <String>[normalized] : segments;
}
