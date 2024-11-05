import 'package:test/test.dart';
import 'package:box_pusher/game_core/common.dart';

void main() {
  group('Point class の単体テスト', () {
    final a1 = Point(1, -2);
    final a2 = Point(1, -2);
    final b = Point(-3, 4);

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

    test('エンコード', () {
      expect(b.encode(), '-3,4');
    });

    test('デコード', () {
      expect(Point.decode('-3,4'), b);
    });
  });
}
