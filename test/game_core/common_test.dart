import 'package:test/test.dart';
import 'package:box_pusher/game_core/common.dart';

void main() {
  group('Point class の単体テスト', () {
    final a1 = Point(1, -2);
    final a2 = Point(1, -2);
    final b = Point(-3, 4);
    final c = Point(-2, 4);
    final d = Point(-4, 4);
    final e = Point(-2, 5);

    test('等価', () {
      expect(a1 == a2, true);
    });

    test('負', () {
      expect(-a1.x, -1);
      expect(-a1.y, 2);
    });

    test('加算', () {
      expect((a1 + b).x, -2);
      expect((a1 + b).y, 2);
    });

    test('減算', () {
      expect((a1 - b).x, 4);
      expect((a1 - b).y, -6);
    });

    test('乗算', () {
      expect((a1 * 5).x, 5);
      expect((a1 * 5).y, -10);
    });

    test('原点からの距離', () {
      expect(b.distance(), 7);
    });

    test('距離が近い点のリスト取得', () {
      expect(b.closests([]).isEmpty, true);
      expect(b.closests([b, c]), [b]);
      expect(b.closests([c, e]), [c]);
      expect(b.closests([c, d, e]), [c, d]);
    });

    test('エンコード', () {
      expect(b.encode(), '-3,4');
    });

    test('デコード', () {
      expect(Point.decode('-3,4'), b);
    });
  });

  group('PointRectRange class の単体テスト', () {
    final p1 = Point(3, 4);
    final p2 = Point(-1, -2);
    final r1 = PointRectRange(p1, p2);
    final r2 = PointRectRange(p1, p2);
    final p3 = Point(0, 1); // 四角形内
    final p4 = Point(2, -3); // x座標は範囲内だが、y座標が範囲外
    final p5 = Point(5, 3); // y座標は範囲内だが、x座標が範囲外
    final p6 = Point(5, -3); // x座標、y座標とも範囲外
    final p7 = Point(-1, 3); // 四角形の辺上
    final p8 = Point(3, -2); // 四角形の頂点

    test('左上座標と右下座標の自動交換', () {
      expect(r1.lt, p2);
      expect(r1.rb, p1);
    });

    test('等価', () {
      expect(r1 == r2, true);
    });

    test('領域内かどうかの判定', () {
      expect(r1.contains(p3), true);
      expect(r1.contains(p4), false);
      expect(r1.contains(p5), false);
      expect(r1.contains(p6), false);
      expect(r1.contains(p7), true);
      expect(r1.contains(p8), true);
    });
  });

  group('PointDistanceRange class の単体テスト', () {
    final p1 = Point(3, 4);
    final r1 = PointDistanceRange(p1, 3);
    final r2 = PointDistanceRange(p1, 3);
    final p2 = Point(1, 4); // 基準点からの距離内
    final p3 = Point(1, 4); // 基準点
    final p4 = Point(0, 4); // 基準点か距離ちょうどの点
    final p5 = Point(0, 0); // 範囲外

    test('等価', () {
      expect(r1 == r2, true);
    });

    test('領域内かどうかの判定', () {
      expect(r1.contains(p2), true);
      expect(r1.contains(p3), true);
      expect(r1.contains(p4), true);
      expect(r1.contains(p5), false);
    });
  });
}
