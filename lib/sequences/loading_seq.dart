import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class LoadingSeq extends Sequence with HasGameReference<BoxPusherGame> {
  @override
  Future<void> onLoad() async {
    final loadingImage = await Flame.images.load('loading.png');
    addAll([
      SpriteAnimationComponent.fromFrameData(
        loadingImage,
        SpriteAnimationData.sequenced(
            amount: 8, stepTime: 0.1, textureSize: Vector2(63, 64)),
        position: BoxPusherGame.baseSize / 2,
        anchor: Anchor.center,
      ),
    ]);
  }

  @override
  void update(double dt) {
    // ゲームの準備ができたらこのシーケンスを終わる
    if (game.isGameReady()) {
      game.popSeq();
    }
  }
}
