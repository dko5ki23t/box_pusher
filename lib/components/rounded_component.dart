import 'dart:ui';

import 'package:flame/components.dart';

// https://stackoverflow.com/questions/77707221/rectangle-component-with-round-corners
/// 角丸な四角形
class RoundedComponent extends PositionComponent {
  Color color;
  Color? borderColor;
  double? strokeWidth;
  double cornerRadius;

  RoundedComponent({
    required super.size,
    this.color = const Color(0xFFFFFFFF),
    this.borderColor,
    this.strokeWidth,
    this.cornerRadius = 50,
    super.position,
    super.anchor,
    super.priority,
    super.children,
  });

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(cornerRadius),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (borderColor != null && strokeWidth != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(cornerRadius),
        ),
        Paint()
          ..color = borderColor!
          ..strokeWidth = strokeWidth!
          ..style = PaintingStyle.stroke,
      );
    }
  }
}
