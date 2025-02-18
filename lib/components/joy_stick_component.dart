import 'package:push_and_merge/game_core/common.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

/// 操作ジョイスティック
class JoyStickComponent extends CircleComponent with DragCallbacks {
  late final Vector2 _initialPosition;
  Vector2 _mousePosition = Vector2.zero();
  final void Function(Move) inputMove;
  bool enableDiagonalInput = false;
  final void Function() onControllStart;
  final void Function() onControllEnd;

  /// 可動域の半径
  double fieldRadius = 0;

  JoyStickComponent({
    required super.radius,
    required super.position,
    required this.fieldRadius,
    super.anchor,
    required this.inputMove,
    required this.onControllStart,
    required this.onControllEnd,
    this.enableDiagonalInput = false,
  }) {
    _initialPosition = super.position.clone();
    _mousePosition = super.position.clone();
    super.paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    super.priority = 100;
  }

  // 押せる範囲は可動域上とする
  @override
  bool containsPoint(Vector2 point) {
    return Circle(center, fieldRadius).containsPoint(point);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    super.paint.color = const Color(0xffeeeeee);
    onControllStart();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _mousePosition += event.localDelta;
    Vector2 direct = _mousePosition - _initialPosition;
    inputMove(Move.none);
    if (direct.length >= fieldRadius * 0.7) {
      // 入力された向き判定
      double angle = degrees(Vector2(1, 0).angleToSigned(direct));
      if (angle < 0) {
        angle += 360.0;
      }
      if (angle <= 20 || angle >= 340) {
        inputMove(Move.right);
      } else if (70 <= angle && angle <= 110) {
        inputMove(Move.down);
      } else if (160 <= angle && angle <= 200) {
        inputMove(Move.left);
      } else if (250 <= angle && angle <= 290) {
        inputMove(Move.up);
      } else if (enableDiagonalInput) {
        if (25 <= angle && angle <= 65) {
          inputMove(Move.downRight);
        } else if (115 <= angle && angle <= 155) {
          inputMove(Move.downLeft);
        } else if (205 <= angle && angle <= 245) {
          inputMove(Move.upLeft);
        } else if (295 <= angle && angle <= 335) {
          inputMove(Move.upRight);
        }
      }
    }
    // ジョイスティックは可動域内にとどめる
    direct.clampLength(0, fieldRadius);
    position = _initialPosition + direct;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    super.paint.color = Colors.white;
    position = _initialPosition;
    _mousePosition = _initialPosition.clone();
    inputMove(Move.none);
    onControllEnd();
  }
}

class JoyStickFieldComponent extends CustomPainterComponent {
  JoyStickFieldComponent({
    super.position,
    super.size,
    super.anchor,
    required double radius,
    required double strokeWidth,
    required double arcStrokeWidth,
  }) : super(
          painter: JoyStickFieldPainter(
            radius: radius,
            strokeWidth: strokeWidth,
            arcStrokeWidth: arcStrokeWidth,
          ),
        );

  set drawDiagonalArcs(bool b) =>
      (painter as JoyStickFieldPainter).drawDiagonalArcs = b;
}

class JoyStickFieldPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final double arcStrokeWidth;
  bool drawDiagonalArcs = false;

  JoyStickFieldPainter({
    required this.radius,
    required this.strokeWidth,
    required this.arcStrokeWidth,
    this.drawDiagonalArcs = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final bgPaint = Paint()
      ..color = const Color(0x80000000)
      ..style = PaintingStyle.fill;
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcStrokeWidth;
    final center = Offset(radius, radius);
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, framePaint);
    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        radians(-20),
        radians(40),
        false,
        arcPaint);
    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        radians(70),
        radians(40),
        false,
        arcPaint);
    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        radians(160),
        radians(40),
        false,
        arcPaint);
    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        radians(250),
        radians(40),
        false,
        arcPaint);
    if (drawDiagonalArcs) {
      canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
          radians(25),
          radians(40),
          false,
          arcPaint);
      canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
          radians(115),
          radians(40),
          false,
          arcPaint);
      canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
          radians(205),
          radians(40),
          false,
          arcPaint);
      canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
          radians(295),
          radians(40),
          false,
          arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
