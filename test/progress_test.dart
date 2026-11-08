import 'package:azkar/data/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 8);

  test('streak counts consecutive days ending today', () {
    expect(computeStreak(['2026-11-06', '2026-11-07', '2026-11-08'], today), 3);
  });

  test('streak survives until the end of the next day', () {
    expect(computeStreak(['2026-11-06', '2026-11-07'], today), 2);
  });

  test('a gap resets the streak', () {
    expect(computeStreak(['2026-11-05', '2026-11-08'], today), 1);
    expect(computeStreak(['2026-11-04'], today), 0);
    expect(computeStreak(<String>[], today), 0);
  });

  test('month boundaries are handled', () {
    expect(computeStreak(['2026-10-31', '2026-11-01'], DateTime(2026, 11, 1)), 2);
  });
}
