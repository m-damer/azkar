import 'package:flutter/material.dart';

/// Five weights for the dhikr text, thin to thick; the middle one is the
/// default. Amiri ships in two weights only, so the steps in between come from
/// an outline of the same colour drawn around the glyphs.
enum DhikrWeight {
  thin('w1', FontWeight.w400, 0.0),
  light('w2', FontWeight.w400, 0.014),
  normal('w3', FontWeight.w700, 0.0),
  bold('w4', FontWeight.w700, 0.014),
  heavy('w5', FontWeight.w700, 0.03);

  const DhikrWeight(this.key, this.weight, this.strokeRatio);

  final String key;
  final FontWeight weight;

  /// Outline width relative to the font size.
  final double strokeRatio;

  int get step => index - 2;

  DhikrWeight? get lighter => index > 0 ? values[index - 1] : null;
  DhikrWeight? get heavier => index < values.length - 1 ? values[index + 1] : null;

  static DhikrWeight fromKey(String? k, [DhikrWeight fallback = normal]) =>
      values.firstWhere((v) => v.key == k, orElse: () => fallback);
}

/// Dhikr text drawn at the chosen [DhikrWeight].
class DhikrText extends StatelessWidget {
  const DhikrText(
    this.text, {
    super.key,
    required this.style,
    required this.color,
    required this.weight,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final DhikrWeight weight;

  @override
  Widget build(BuildContext context) {
    final base = style.copyWith(fontWeight: weight.weight);
    final fill = Text(text, textAlign: TextAlign.center,
        style: base.copyWith(color: color));
    if (weight.strokeRatio == 0) return fill;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (style.fontSize ?? 0) * weight.strokeRatio
      ..color = color;
    return Stack(
      children: [
        fill,
        Text(text,
            textAlign: TextAlign.center,
            style: base.copyWith(foreground: outline)),
      ],
    );
  }
}
