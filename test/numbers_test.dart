import 'package:azkar/l10n/numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('digits are Arabic-Indic', () {
    expect(arDigits('7/150 و 33'), '٧/١٥٠ و ٣٣');
    expect(arNum(1234), '١٢٣٤');
  });

  test('counted nouns agree with their number', () {
    expect(Nouns.times.of(1), 'مرة واحدة');
    expect(Nouns.times.of(2), 'مرتان');
    expect(Nouns.times.of(3), '٣ مرات');
    expect(Nouns.times.of(10), '١٠ مرات');
    expect(Nouns.times.of(11), '١١ مرة');
    expect(Nouns.times.of(100), '١٠٠ مرة');
    expect(Nouns.day.of(2), 'يومان');
    expect(Nouns.day.of(15), '١٥ يوماً');
    expect(Nouns.item.of(5), '٥ نصوص');
    expect(Nouns.degreesBy(1), 'بدرجة واحدة');
    expect(Nouns.degreesBy(6), 'بـ ٦ درجات');
  });
}
