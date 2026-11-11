import 'package:flutter/material.dart';

/// Dhikr weights. Level 0 is the designed default and the lightest the font
/// offers (Amiri Regular); Amiri ships in two weights only, so the heavier
/// steps come from Bold plus an outline of the same colour around the glyphs.
enum DhikrWeight {
  normal('w1', FontWeight.w400, 0.0),
  heavier1('w2', FontWeight.w400, 0.014),
  heavier2('w3', FontWeight.w700, 0.0),
  heavier3('w4', FontWeight.w700, 0.014),
  heavier4('w5', FontWeight.w700, 0.03);

  const DhikrWeight(this.key, this.weight, this.strokeRatio);

  final String key;
  final FontWeight weight;

  /// Outline width relative to the font size.
  final double strokeRatio;

  int get step => index;

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
