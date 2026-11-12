/// Arabic-Indic digits and correct Arabic number agreement for counted nouns.
library;

/// Replaces Latin digits with Arabic-Indic ones in [s].
String arDigits(String s) => s.replaceAllMapped(
      RegExp(r'\d'),
      (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
    );

String arNum(int n) => arDigits('$n');

/// A noun with its Arabic forms: 1 → singular (with «واحد»), 2 → dual,
/// 3–10 (and 0) → plural, 11+ → accusative singular.
class Noun {
  const Noun(this.one, this.two, this.few, this.many);

  final String one;
  final String two;
  final String few;
  final String many;

  String of(int n) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10 || n == 0) return '${arNum(n)} $few';
    return '${arNum(n)} $many';
  }
}

abstract final class Nouns {
  static const times = Noun('مرة واحدة', 'مرتان', 'مرات', 'مرة');
  static const item = Noun('نص واحد', 'نصان', 'نصوص', 'نصاً');
  static const chapter = Noun('باب واحد', 'بابان', 'أبواب', 'باباً');
  static const category = Noun('فئة واحدة', 'فئتان', 'فئات', 'فئة');
  static const day = Noun('يوم واحد', 'يومان', 'أيام', 'يوماً');
  static const dhikr = Noun('ذكر واحد', 'ذكران', 'أذكار', 'ذكراً');
  static const list = Noun('قائمة واحدة', 'قائمتان', 'قوائم', 'قائمة');
  static const minute = Noun('دقيقة واحدة', 'دقيقتان', 'دقائق', 'دقيقة');

  /// «بدرجة واحدة» / «بدرجتين» / «بـ ٣ درجات» for the font steps.
  static String degreesBy(int n) => switch (n) {
        1 => 'بدرجة واحدة',
        2 => 'بدرجتين',
        _ => 'بـ ${arNum(n)} درجات',
      };
}
