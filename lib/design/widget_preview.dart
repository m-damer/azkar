import 'package:flutter/material.dart';

import 'typography.dart';

/// A live, approximate picture of the Android home-screen widget, drawn with
/// the same rules as the native code: the title and text start at their
/// default size times the chosen scale and shrink one step at a time until
/// they fit, never below the default floor.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({
    super.key,
    required this.title,
    required this.text,
    required this.titleScale,
    required this.textScale,
    this.arrows = false,
  });

  /// Previous / next buttons, shown when the list holds more than one azkar.
  final bool arrows;

  final String title;
  final String text;
  final double titleScale;
  final double textScale;

  static const double _height = 112;
  static const double _pad = 16;
  static const double _gap = 6;
  static const double _titleBase = 12;
  static const double _textBase = 17;
  static const double _textFloor = 10;
  static const double _arrowBox = 28;

  /// Largest size from [max] down to [floor] that fits the box.
  static double fit(String s, TextStyle base, double max, double floor,
      double w, double h, bool oneLine, TextAlign align) {
    var sp = max;
    while (true) {
      final p = TextPainter(
        text: TextSpan(text: s, style: base.copyWith(fontSize: sp)),
        textDirection: TextDirection.rtl,
        textAlign: align,
        maxLines: oneLine ? 1 : null,
      )..layout(maxWidth: oneLine ? double.infinity : w);
      final fits = p.height <= h && (!oneLine || p.width <= w);
      if (fits || sp <= floor) return sp;
      sp -= 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF2A241E) : const Color(0xFFF3ECE0);
    final titleColor = dark ? const Color(0xFFB8A48C) : const Color(0xFF7A6A58);
    final textColor = dark ? const Color(0xFFF3ECE0) : const Color(0xFF2B2420);
    return Container(
      height: _height,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(_pad),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth - (arrows ? _arrowBox * 2 : 0);
        final full = box.maxWidth;
        final inner = box.maxHeight;
        final titleH = ((_titleBase * titleScale * 1.5).ceilToDouble())
            .clamp(18.0, (inner - _gap) * 0.4);
        final textH = inner - titleH - _gap;
        final titleStyle = TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w500,
            color: titleColor,
            height: 1);
        final textStyle = TextStyle(
            fontFamily: AppFonts.dhikr, color: textColor, height: 1.15);
        final ts = fit(title, titleStyle, _titleBase * titleScale, _titleBase,
            w, titleH, true, TextAlign.start);
        final xs = fit(text, textStyle, _textBase * textScale, _textFloor, full,
            textH, false, TextAlign.center);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: titleH,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle.copyWith(fontSize: ts)),
                      ),
                    ),
                    if (arrows) ...[
                      Icon(Icons.chevron_right, size: _arrowBox, color: titleColor),
                      Icon(Icons.chevron_left, size: _arrowBox, color: titleColor),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              Expanded(
                child: Center(
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: textStyle.copyWith(fontSize: xs)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
