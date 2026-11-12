import 'package:azkar/data/progress.dart';
import 'package:azkar/data/wird_lists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('wird lists group awrad without owning them', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    final n = c.read(wirdListsProvider.notifier);
    final id = n.create('  وردي  ');
    n.addWirds(id, ['a', 'b']);
    n.addWirds(id, ['b', 'c']);
    expect(c.read(wirdListsProvider).single.name, 'وردي');
    expect(c.read(wirdListsProvider).single.wirdIds, ['a', 'b', 'c']);
    n.reorder(id, ['c', 'a', 'b']);
    n.removeWird(id, 'a');
    expect(c.read(wirdListsProvider).single.wirdIds, ['c', 'b']);
    n.forgetWird('c');
    n.rename(id, 'جديد');
    expect(c.read(wirdListsProvider).single.wirdIds, ['b']);
    expect(c.read(wirdListsProvider).single.name, 'جديد');
    n.delete(id);
    expect(c.read(wirdListsProvider), isEmpty);
  });
}
