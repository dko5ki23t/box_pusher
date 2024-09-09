import 'package:box_pusher/box_pusher_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class SelectSeq extends Component
    with TapCallbacks, HasGameReference<BoxPusherGame> {
  @override
  Future<void> onLoad() async {
    final selectSprite = await Sprite.load('select.png');
    addAll([
      SpriteComponent(
        sprite: selectSprite,
        position: BoxPusherGame.offset + Vector2(0.0, 0.0),
      ),
    ]);
  }

  @override
  void update(double dt) {
    //
  }

  // TapCallbacks実装時には必要(PositionComponentでは不要)
  @override
  bool containsLocalPoint(Vector2 point) => true;

  // タップで指を離したとき
  @override
  void onTapUp(TapUpEvent event) {
    // ローディング画面へ
    game.router.pushNamed('loading');
  }
}
