import 'dart:ui';

import 'package:flame/components.dart';

// https://stackoverflow.com/questions/77707221/rectangle-component-with-round-corners
/// 角丸な四角形
class RoundedComponent extends PositionComponent {
  final Color color;
  final double cornerRadius;

  RoundedComponent({
    required super.size,
    this.color = const Color(0xFFFFFFFF),
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
  }
}
