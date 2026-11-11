import 'package:flutter/material.dart';

import '../../data/library.dart';
import '../../data/reminders.dart';
import '../../design/dimens.dart';
import '../../design/theme.dart';
import '../../design/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/dates.dart';
import '../../l10n/numbers.dart';
import 'widgets.dart';

/// A wheel of labels; reports the selected index.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.labels,
    required this.initial,
    required this.onChanged,
  });

  final List<String> labels;
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const SizedBox(height: AppSize.touchMin, width: double.infinity),
        ),
        ListWheelScrollView.useDelegate(
          itemExtent: AppSize.touchMin,
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(initialItem: initial),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildListDelegate(children: [
            for (final l in labels)
              Center(
                child: Text(l,
                    style: AppType.titleSm.copyWith(color: c.textPrimary)),
              ),
          ]),
        ),
      ],
    );
  }
}

/// Bottom-sheet time picker (hour, minute, ص / م).
Future<TimeOfDay?> showTimeSheet(
  BuildContext context, {
  required String title,
  required TimeOfDay initial,
}) {
  final t = AppLocalizations.of(context);
  var h12 = initial.hourOfPeriod == 0 ? 12 : initial.hourOfPeriod;
  var minute = initial.minute;
  var pm = initial.period == DayPeriod.pm;
  return showAppSheet<TimeOfDay>(
    context,
    title: title,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSize.tileHero,
          child: Row(
            children: [
              Expanded(
                child: _Wheel(
                  labels: [for (var i = 1; i <= 12; i++) arDigits('$i')],
                  initial: h12 - 1,
                  onChanged: (i) => h12 = i + 1,
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              Expanded(
                child: _Wheel(
                  labels: [
                    for (var i = 0; i < 60; i++)
                      arDigits(i.toString().padLeft(2, '0')),
                  ],
                  initial: minute,
                  onChanged: (i) => minute = i,
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              Expanded(
                child: _Wheel(
                  labels: const ['ص', 'م'],
                  initial: pm ? 1 : 0,
                  onChanged: (i) => pm = i == 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        WideButton(
          label: t.done,
          onPressed: () =>
              close(TimeOfDay(hour: (h12 % 12) + (pm ? 12 : 0), minute: minute)),
        ),
        const SizedBox(height: AppSpace.s2),
        TextButton(onPressed: () => close(null), child: Text(t.cancel)),
      ],
    ),
  );
}

/// "اليوم" / "غداً" / "الأربعاء ١٢ نوفمبر".
String dayLabel(DateTime d, DateTime today) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(today.year, today.month, today.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'غداً';
  return '${weekdayNames[d.weekday]} ${arDigits('${d.day}')} ${monthNames[d.month - 1]}';
}

/// Bottom-sheet day picker over the next [days] days.
Future<DateTime?> showDaySheet(
  BuildContext context, {
  required String title,
  required DateTime today,
  DateTime? initial,
  int days = 60,
}) {
  final t = AppLocalizations.of(context);
  final start = DateTime(today.year, today.month, today.day);
  final list = [for (var i = 0; i < days; i++) DateTime(start.year, start.month, start.day + i)];
  var index = initial == null
      ? 0
      : list.indexWhere((d) =>
          d.year == initial.year &&
          d.month == initial.month &&
          d.day == initial.day);
  if (index < 0) index = 0;
  return showAppSheet<DateTime>(
    context,
    title: title,
    builder: (sheet, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSize.tileHero,
          child: _Wheel(
            labels: [for (final d in list) dayLabel(d, start)],
            initial: index,
            onChanged: (i) => index = i,
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        WideButton(label: t.done, onPressed: () => close(list[index])),
        const SizedBox(height: AppSpace.s2),
        TextButton(onPressed: () => close(null), child: Text(t.cancel)),
      ],
    ),
  );
}

/// "٦:٠٠ م · كل يوم" / "٦:٠٠ م · السبت، الأحد" / "٦:٠٠ م · غداً".
String reminderSummary(WirdReminder r, DateTime now) {
  final time = formatTime(TimeOfDay(hour: r.hour, minute: r.minute));
  if (r.once) {
    final d = r.onceDate;
    return d == null ? time : '$time · ${dayLabel(d, now)}';
  }
  if (r.days.length == 7) return '$time · كل يوم';
  final names = [
    for (final d in weekOrder)
      if (r.days.contains(d)) weekdayNames[d]!,
  ];
  return '$time · ${names.join('، ')}';
}
