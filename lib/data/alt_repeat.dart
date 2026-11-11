import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress.dart';

/// Items for which the user picked the longer count (e.g. 100 instead of 10).
class AltRepeatNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final raw = ref.read(sharedPreferencesProvider).getString('altRepeat');
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
    } catch (_) {
      return const {};
    }
  }

  void set(String itemId, bool alt) {
    final next = {...state}..remove(itemId);
    if (alt) next.add(itemId);
    ref
        .read(sharedPreferencesProvider)
        .setString('altRepeat', jsonEncode(next.toList()));
    state = next;
  }
}

final altRepeatProvider =
    NotifierProvider<AltRepeatNotifier, Set<String>>(AltRepeatNotifier.new);
