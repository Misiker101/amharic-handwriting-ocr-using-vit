class ResultFormatter {
  ResultFormatter._();

  static List<String> splitLines(String text) {
    if (text.trim().isEmpty) return [];
    return text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  static int wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  static int charCount(String text) => text.replaceAll('\n', '').length;
}
