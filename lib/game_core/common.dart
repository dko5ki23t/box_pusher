import 'package:flame/components.dart';

/// 整数座標
class Point {
  int x = 0;
  int y = 0;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Point &&
            runtimeType == other.runtimeType &&
            x == other.x &&
            y == other.y);
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Point operator -() {
    return Point(-x, -y);
  }

  Point operator +(Point a) {
    return Point(x + a.x, y + a.y);
  }

  Point operator -(Point a) {
    return Point(x - a.x, y - a.y);
  }

  Point copy() => Point(x, y);

  /// 原点(0,0)からの距離
  int distance() {
    return (x.abs() + y.abs());
  }

  String encode() {
    return "$x,$y";
  }

  static Point decode(String str) {
    final xy = str.split(',');
    return Point(int.parse(xy[0]), int.parse(xy[1]));
  }
}

/// 移動
enum Move {
  none,
  left,
  right,
  up,
  down,
  upLeft,
  upRight,
  downLeft,
  downRight,
}

extension MoveExtent on Move {
  /// 対応する座標
  Point get point {
    switch (this) {
      case Move.none:
        return Point(0, 0);
      case Move.left:
        return Point(-1, 0);
      case Move.right:
        return Point(1, 0);
      case Move.up:
        return Point(0, -1);
      case Move.down:
        return Point(0, 1);
      case Move.upLeft:
        return Point(-1, -1);
      case Move.upRight:
        return Point(1, -1);
      case Move.downLeft:
        return Point(-1, 1);
      case Move.downRight:
        return Point(1, 1);
    }
  }

  /// 逆の向き
  Move get oppsite {
    switch (this) {
      case Move.none:
        return Move.none;
      case Move.left:
        return Move.right;
      case Move.right:
        return Move.left;
      case Move.up:
        return Move.down;
      case Move.down:
        return Move.up;
      case Move.upLeft:
        return Move.downRight;
      case Move.upRight:
        return Move.downLeft;
      case Move.downLeft:
        return Move.upRight;
      case Move.downRight:
        return Move.upLeft;
    }
  }

  /// 対応するベクトル
  Vector2 get vector {
    switch (this) {
      case Move.none:
        return Vector2(0, 0);
      case Move.left:
        return Vector2(-1.0, 0);
      case Move.right:
        return Vector2(1.0, 0);
      case Move.up:
        return Vector2(0, -1.0);
      case Move.down:
        return Vector2(0, 1.0);
      case Move.upLeft:
        return Vector2(-1.0, -1.0);
      case Move.upRight:
        return Vector2(1.0, -1.0);
      case Move.downLeft:
        return Vector2(-1.0, 1.0);
      case Move.downRight:
        return Vector2(1.0, 1.0);
    }
  }

  /// 上下左右のみのリスト
  static List<Move> get straights {
    return [Move.up, Move.down, Move.left, Move.right];
  }

  /// 斜めのみのリスト
  static List<Move> get diagonals {
    return [Move.upLeft, Move.upRight, Move.downLeft, Move.downRight];
  }
}
