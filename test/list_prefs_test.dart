import 'package:azkar/data/list_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String id(String e) => e;
  const src = ['a', 'b', 'c', 'd'];

  test('without a saved order the list is unchanged', () {
    expect(const ListPrefs().ordered('k', src, id), src);
    expect(const ListPrefs().visible('k', src, id), src);
  });

  test('a saved order wins, unknown ids are ignored, new ones go last', () {
    const p = ListPrefs(order: {
      'k': ['c', 'x', 'a']
    });
    expect(p.ordered('k', src, id), ['c', 'a', 'b', 'd']);
  });

  test('hidden items stay in the order but not in the visible list', () {
    const p = ListPrefs(order: {
      'k': ['d', 'c', 'b', 'a']
    }, hidden: {
      'k': {'c'}
    });
    expect(p.ordered('k', src, id), ['d', 'c', 'b', 'a']);
    expect(p.visible('k', src, id), ['d', 'b', 'a']);
    expect(p.isCustom('k'), isTrue);
    expect(p.isCustom('other'), isFalse);
  });

  test('json round trip', () {
    const p = ListPrefs(order: {
      'k': ['b', 'a']
    }, hidden: {
      'k': {'a'}
    });
    final back = ListPrefs.fromJson(p.toJson());
    expect(back.order['k'], ['b', 'a']);
    expect(back.isHidden('k', 'a'), isTrue);
  });
}
