import 'dart:convert';
import 'dart:math';

import 'package:box_pusher/config.dart';
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

  Point operator *(int a) {
    return Point(x * a, y * a);
  }

  Point copy() => Point(x, y);

  /// 原点(0,0)からの距離
  int distance() {
    return (x.abs() + y.abs());
  }

  /// リストの中から最も近い点のリストを返す
  List<Point> closests(List<Point> points) {
    if (points.isEmpty) return [];
    Point myP = copy();
    final List<Point> ret = [];
    int closestD = (myP - points.first).distance();
    for (final point in points) {
      int d = (myP - point).distance();
      if (d == closestD) {
        ret.add(point);
      } else if (d < closestD) {
        ret.clear();
        ret.add(point);
        closestD = d;
      }
    }
    return ret;
  }

  String encode() {
    return "$x,$y";
  }

  static Point decode(String str) {
    final xy = str.split(',');
    return Point(int.parse(xy[0]), int.parse(xy[1]));
  }
}

/// 整数座標による範囲表現
abstract class PointRange {
  /// 引数の座標が範囲内にあるか
  bool contains(Point p);

  /// 範囲内座標のセット
  Set<Point> get set;

  static PointRange createFromStrings(List<String> data) {
    switch (data[0]) {
      case 'rect':
        return PointRectRange(Point(int.parse(data[1]), int.parse(data[2])),
            Point(int.parse(data[3]), int.parse(data[4])));
      case 'distance':
        return PointDistanceRange(
            Point(int.parse(data[1]), int.parse(data[2])), int.parse(data[5]));
      default:
        throw ('[PointRange]無効な文字列が範囲タイプとして入力された');
    }
  }

  List<String> toStrings();

  @override
  String toString() {
    final strings = toStrings();
    String ret = strings.first;
    for (int i = 1; i < strings.length; i++) {
      ret += ',${strings[i]}';
    }
    return ret;
  }

  static PointRange fromStr(String str) =>
      PointRange.createFromStrings(str.split(','));
}

/// 整数座標による四角形表現
class PointRectRange extends PointRange {
  Point lt = Point(0, 0);
  Point rb = Point(0, 0);

  /// 左上と右下は逆で指定しても良い
  PointRectRange(this.lt, this.rb) {
    if (lt.x > rb.x || lt.y > rb.y) {
      Point tmp = lt.copy();
      lt = rb.copy();
      rb = tmp;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PointRectRange &&
            runtimeType == other.runtimeType &&
            lt == other.lt &&
            rb == other.rb);
  }

  @override
  int get hashCode => lt.hashCode ^ rb.hashCode;

  /// 引数の座標が四角形内にあるか
  @override
  bool contains(Point p) {
    return (p.x >= lt.x && p.x <= rb.x && p.y >= lt.y && p.y <= rb.y);
  }

  /// 四角形内座標のセット
  @override
  Set<Point> get set {
    return {
      for (int y = lt.y; y <= rb.y; y++)
        for (int x = lt.x; x <= rb.x; x++) Point(x, y)
    };
  }

  @override
  List<String> toStrings() => [
        'rect',
        lt.x.toString(),
        lt.y.toString(),
        rb.x.toString(),
        rb.y.toString()
      ];
}

/// 整数座標による直線表現(ただし、縦横斜め8方向のみ)
class PointLineRange extends PointRange {
  Point start = Point(0, 0);
  Move direct = Move.down;
  int length = 0;

  PointLineRange(this.start, this.direct, this.length);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PointLineRange &&
            runtimeType == other.runtimeType &&
            start == other.start &&
            direct == other.direct &&
            length == other.length);
  }

  @override
  int get hashCode => start.hashCode ^ direct.hashCode ^ length.hashCode;

  Point get end => start + direct.point * length;

  /// 引数の座標が直線上にあるか
  @override
  bool contains(Point p) {
    switch (direct) {
      case Move.none:
        return start == p;
      case Move.left:
      case Move.right:
      case Move.up:
      case Move.down:
        return (p.x >= min(start.x, end.x) &&
            p.x <= max(start.x, end.x) &&
            p.y >= min(start.y, end.y) &&
            p.y <= max(start.y, end.y));
      case Move.upRight:
      case Move.downLeft:
        // 傾き1の直線
        return ((p.x >= min(start.x, end.x) && p.x <= max(start.x, end.x)) &&
            (p.y == (p.x + start.y)));
      case Move.upLeft:
      case Move.downRight:
        // 傾き-1の直線
        return ((p.x >= min(start.x, end.x) && p.x <= max(start.x, end.x)) &&
            (p.y == (-p.x + start.y)));
    }
  }

  /// 直線内座標のセット
  @override
  Set<Point> get set {
    return {for (int i = 0; i < length; i++) start + direct.point * i};
  }

  @override
  List<String> toStrings() => [
        'line',
        start.x.toString(),
        start.y.toString(),
        direct.name,
        '',
        length.toString(),
      ];
}

/// 整数座標による等距離範囲（≒円）表現
class PointDistanceRange extends PointRange {
  Point center = Point(0, 0);
  int distance = 0;

  PointDistanceRange(this.center, this.distance);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PointDistanceRange &&
            runtimeType == other.runtimeType &&
            center == other.center &&
            distance == other.distance);
  }

  @override
  int get hashCode => center.hashCode ^ distance.hashCode;

  /// 引数の座標が範囲内にあるか
  @override
  bool contains(Point p) {
    return (p - center).distance() <= distance;
  }

  // TODO:テスト
  /// 範囲内座標のセット
  @override
  Set<Point> get set {
    Set<Point> ret = {};
    for (int dy = -distance; dy <= distance; dy++) {
      int d2 = distance - dy.abs();
      for (int dx = -d2; dx <= d2; dx++) {
        ret.add(center + Point(dx, dy));
      }
    }
    return ret;
  }

  @override
  List<String> toStrings() => [
        'distance',
        center.x.toString(),
        center.y.toString(),
        '',
        '',
        distance.toString()
      ];
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

  /// 隣接する2つの向き
  List<Move> get neighbors {
    switch (this) {
      case Move.none:
        return [];
      case Move.left:
        return [Move.upLeft, Move.downLeft];
      case Move.right:
        return [Move.upRight, Move.downRight];
      case Move.up:
        return [Move.upLeft, Move.upRight];
      case Move.down:
        return [Move.downLeft, Move.downRight];
      case Move.upLeft:
        return [Move.up, Move.left];
      case Move.upRight:
        return [Move.up, Move.right];
      case Move.downLeft:
        return [Move.down, Move.left];
      case Move.downRight:
        return [Move.down, Move.right];
    }
  }

  /// 角度
  double angle({required Move base}) {
    double downBase(Move move) {
      switch (move) {
        case Move.none:
          return 0;
        case Move.left:
          return 0.5;
        case Move.right:
          return -0.5;
        case Move.up:
          return 1;
        case Move.down:
          return 0;
        case Move.upLeft:
          return 0.75;
        case Move.upRight:
          return -0.75;
        case Move.downLeft:
          return 0.25 * pi;
        case Move.downRight:
          return -0.25;
      }
    }

    return (downBase(base) + downBase(this)) * pi;
  }

  /// 上下左右かどうか
  bool get isStraight =>
      this == Move.left ||
      this == Move.right ||
      this == Move.up ||
      this == Move.down;

  /// 斜めの向きかどうか
  bool get isDiagonal =>
      this == Move.upLeft ||
      this == Move.downLeft ||
      this == Move.upRight ||
      this == Move.downRight;

  /// 斜めの向きを直線向き（左右）に変換
  Move toStraightLR() {
    switch (this) {
      case Move.downLeft:
      case Move.upLeft:
        return Move.left;
      case Move.downRight:
      case Move.upRight:
        return Move.right;
      default:
        return this;
    }
  }

  /// 現在の向きに上下左右の向きを加えて新たな向き（斜めあり）を作り出す。該当する向きがなければ、元の向きを返す。
  ///
  /// ex)
  ///
  /// * Move.left.addStraight(Move.up) -> Move.upLeft
  /// * Move.none.addStraight(Move.left) -> Move.left
  /// * Move.left.addStraight(Move.right) -> Move.left
  /// * Move.upLeft.addStraight(Move.down) -> Move.upLeft
  /// * Move.none.addStraight(Move.upLeft) -> Move.none
  Move addStraight(Move a) {
    if (this == Move.none && a.isStraight) {
      return a;
    }
    if ((this == Move.up && a == Move.left) ||
        (this == Move.left && a == Move.up)) {
      return Move.upLeft;
    } else if ((this == Move.up && a == Move.right) ||
        (this == Move.right && a == Move.up)) {
      return Move.upRight;
    } else if ((this == Move.down && a == Move.left) ||
        (this == Move.left && a == Move.down)) {
      return Move.downLeft;
    } else if ((this == Move.down && a == Move.right) ||
        (this == Move.right && a == Move.down)) {
      return Move.downRight;
    }
    return this;
  }

  /// 現在の向きから上下左右の向きを引いて新たな向き（斜めあり）を作り出す。該当する向きがなければ、元の向きを返す。
  ///
  /// ex)
  /// * Move.upLeft.subStraight(Move.up) -> Move.left
  /// * Move.up.subStraight(Move.up) -> Move.none
  /// * Move.left.subStraight(Move.right) -> Move.left
  /// * Move.upLeft.subStraight(Move.down) -> Move.upLeft
  /// * Move.none.subStraight(Move.left) -> Move.none
  /// * Move.upLeft.subStraight(Move.upLeft) -> Move.upLeft (=引数に斜めを入力しても無視する)
  Move subStraight(Move a) {
    if (a.isStraight && this == a) {
      return Move.none;
    }
    if ((this == Move.upLeft && a == Move.left) ||
        (this == Move.upRight && a == Move.right)) {
      return Move.up;
    } else if ((this == Move.downLeft && a == Move.left) ||
        (this == Move.downRight && a == Move.right)) {
      return Move.down;
    } else if ((this == Move.upLeft && a == Move.up) ||
        (this == Move.downLeft && a == Move.down)) {
      return Move.left;
    } else if ((this == Move.upRight && a == Move.up) ||
        (this == Move.downRight && a == Move.down)) {
      return Move.right;
    }
    return this;
  }

  /// 現在の向きを上下左右の向きの組み合わせに分解し、そのリストを返す
  ///
  /// ex)
  /// * Move.upLeft.toStraightList() -> [Move.up, Move.left]
  /// * Move.left.toStraightList() -> [Move.left]
  /// * Move.none.toStraightList() -> []
  List<Move> toStraightList() {
    if (this == Move.none) {
      return [];
    }
    if (this == Move.upLeft) {
      return [Move.up, Move.left];
    } else if (this == Move.upRight) {
      return [Move.up, Move.right];
    } else if (this == Move.downLeft) {
      return [Move.down, Move.left];
    } else if (this == Move.downRight) {
      return [Move.down, Move.right];
    }
    return [this];
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

enum RoundMode {
  floor,
  ceil,
  round,
  randomRound,
}

/// 分布を管理する
class Distribution<T> {
  /// 各オブジェクトごとの数
  final Map<T, int> _total = {};

  /// 各オブジェクトごとの数(残り)
  final Map<T, int> _remain = {};

  /// 総数
  int totalTotal;

  /// 残りの総数
  int remainTotal;

  /// 総数以上取り出したときに例外を発生させるかどうか
  final bool overdoseException;

  Distribution(Map<T, int> nums, this.totalTotal,
      {this.overdoseException = true})
      : remainTotal = totalTotal {
    _total.addAll(nums);
    _remain.addAll(nums);
  }

  Distribution.fromPercent(
      Map<T, int> percents, this.totalTotal, RoundMode roundMode,
      {this.overdoseException = true})
      : remainTotal = totalTotal {
    for (final e in percents.entries) {
      double n = totalTotal * e.value * 0.01;
      switch (roundMode) {
        case RoundMode.floor:
          _total[e.key] = n.floor();
          break;
        case RoundMode.ceil:
          _total[e.key] = n.ceil();
          break;
        case RoundMode.round:
          _total[e.key] = n.round();
          break;
        case RoundMode.randomRound:
          _total[e.key] = randomRound(n);
          break;
      }
    }
    _remain.addAll(_total);
  }

  Distribution.fromPercentWithMinMax(
      Map<T, NumsAndPercent> percents, this.totalTotal, RoundMode roundMode,
      {this.overdoseException = true})
      : remainTotal = totalTotal {
    for (final e in percents.entries) {
      double n = totalTotal * e.value.percent * 0.01;
      switch (roundMode) {
        case RoundMode.floor:
          _total[e.key] = n.floor();
          break;
        case RoundMode.ceil:
          _total[e.key] = n.ceil();
          break;
        case RoundMode.round:
          _total[e.key] = n.round();
          break;
        case RoundMode.randomRound:
          _total[e.key] = randomRound(n);
          break;
      }
      if (e.value.min >= 0) {
        _total[e.key] = max(_total[e.key]!, e.value.min);
      }
      if (e.value.max >= 0) {
        _total[e.key] = min(_total[e.key]!, e.value.max);
      }
    }
    _remain.addAll(_total);
  }

  void reset() {
    _remain.clear();
    _remain.addAll(_total);
    remainTotal = totalTotal;
  }

  bool get isEmpty => remainTotal <= 0;

  Iterable<T> get keys => _total.keys;

  T? getOne() {
    if (isEmpty) {
      if (overdoseException) {
        throw ('総数が0の分布に対してget操作が行われた。');
      } else {
        return null;
      }
    }
    int r = Config().random.nextInt(remainTotal);
    int t = 0;
    for (final e in _remain.entries) {
      t += e.value;
      if (r < t) {
        _remain[e.key] = _remain[e.key]! - 1;
        remainTotal--;
        return e.key;
      }
    }
    remainTotal--;
    return null;
  }

  List<T?> getList(int len) {
    List<T?> ret = [];
    for (int i = 0; i < len; i++) {
      ret.add(getOne());
    }
    return ret;
  }

  int getRemainNum(T key) => _remain[key]!;

  int getTotalNum(T key) => _total[key]!;

  Distribution.decode(Map<String, dynamic> json, T Function(String) strToKey,
      {this.overdoseException = true})
      : totalTotal = json['totalTotal'],
        remainTotal = json['remainTotal'] {
    final Map<String, dynamic> jsonDecodedT = jsonDecode(json['total']);
    for (final entry in jsonDecodedT.entries) {
      _total[strToKey(entry.key)] = entry.value;
    }
    final Map<String, dynamic> jsonDecodedR = jsonDecode(json['remain']);
    for (final entry in jsonDecodedR.entries) {
      _remain[strToKey(entry.key)] = entry.value;
    }
  }

  Map<String, dynamic> encode({String Function(T)? toStringFn}) {
    final Map<String, dynamic> totalMap = {};
    for (final entry in _total.entries) {
      totalMap[toStringFn != null
          ? toStringFn(entry.key)
          : entry.key.toString()] = entry.value;
    }
    final Map<String, dynamic> remainMap = {};
    for (final entry in _remain.entries) {
      remainMap[toStringFn != null
          ? toStringFn(entry.key)
          : entry.key.toString()] = entry.value;
    }
    return {
      'total': jsonEncode(totalMap),
      'totalTotal': totalTotal,
      'remain': jsonEncode(remainMap),
      'remainTotal': remainTotal
    };
  }
}

/// ランダムに切り上げ/切り下げしたintを返す
int randomRound(double a) => Config().random.nextBool() ? a.ceil() : a.floor();
