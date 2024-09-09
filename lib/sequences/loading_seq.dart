import 'package:box_pusher/box_pusher_game.dart';
import 'package:flame/components.dart';

class LoadingSeq extends Component with HasGameReference<BoxPusherGame> {
  // 経過時間をカウントしているか
  bool isCounting = false;
  // ロード時間計測用カウント
  double timeCount = 0.0;

  @override
  Future<void> onLoad() async {
    final loadingSprite = await Sprite.load('loading.png');
    addAll([
      SpriteComponent(
        sprite: loadingSprite,
        position: BoxPusherGame.offset + Vector2(0.0, 0.0),
      ),
    ]);
    initialize();
  }

  void initialize() {
    isCounting = true;
    timeCount = 0.0;
  }

  @override
  void update(double dt) {
    if (isCounting) {
      timeCount += dt;
      // 1秒以上経過時
      if (timeCount >= 1) {
        // ゲームプレイへ
        isCounting = false;
        game.pushAndInitGame();
      }
    }
  }
}
