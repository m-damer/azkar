import 'package:azkar/data/my_duas.dart';
import 'package:azkar/data/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  test('a written dua lives on the page, in a list, and is edited', () async {
    final c = await _container();
    final n = c.read(myDuasProvider.notifier);
    final a = n.addCustom('دعاء الصباح', 'اللهم بك أصبحنا');
    expect(c.read(myDuasProvider).loose, [a]);
    final list = n.createList('قائمتي');
    final b = n.addCustom('دعاء ثان', 'نص', listId: list);
    expect(c.read(myDuasProvider).list(list)!.itemIds, [b]);
    n.editCustom(a, 'اسم جديد', 'نص جديد');
    expect(c.read(myDuasProvider).dua(a)!.name, 'اسم جديد');
  });

  test('built-in azkar are added once; own duas vanish when unused', () async {
    final c = await _container();
    final n = c.read(myDuasProvider.notifier);
    n.addMany(['b1', 'b2', 'b1']);
    n.addMany(['b2', 'b3']);
    expect(c.read(myDuasProvider).loose, ['b1', 'b2', 'b3']);
    final own = n.addCustom('x', 'y');
    n.remove(own);
    expect(c.read(myDuasProvider).dua(own), isNull);
    final list = n.createList('l');
    final inList = n.addCustom('p', 'q', listId: list);
    n.deleteList(list);
    expect(c.read(myDuasProvider).dua(inList), isNull);
  });

  test('state survives a restart', () async {
    final c = await _container();
    c.read(myDuasProvider.notifier).addCustom('اسم', 'نص');
    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    expect(c2.read(myDuasProvider).duas.single.name, 'اسم');
  });
}
