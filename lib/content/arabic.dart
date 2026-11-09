/// Arabic text helpers: diacritics removal and search normalisation.
final RegExp _diacritics = RegExp('[ً-ٰٟـۖ-ۭ]');

String stripDiacritics(String s) => s.replaceAll(_diacritics, '');

String _fold(String ch) {
  switch (ch) {
    case 'أ':
    case 'إ':
    case 'آ':
    case 'ٱ':
      return 'ا';
    case 'ى':
      return 'ي';
    case 'ة':
      return 'ه';
    case 'ؤ':
      return 'و';
    case 'ئ':
      return 'ي';
    default:
      return ch;
  }
}

/// A normalised copy of a string that remembers where each character came
/// from, so matches can be highlighted in the original text.
class NormText {
  NormText._(this.text, this.map);

  factory NormText(String original) {
    final buf = StringBuffer();
    final map = <int>[];
    for (var i = 0; i < original.length; i++) {
      final ch = original[i];
      if (_diacritics.hasMatch(ch)) continue;
      buf.write(_fold(ch));
      map.add(i);
    }
    return NormText._(buf.toString(), map);
  }

  /// Folded text without diacritics.
  final String text;

  /// `map[i]` is the index in the original string of `text[i]`.
  final List<int> map;
}

String normalizeQuery(String q) => NormText(q.trim()).text;
