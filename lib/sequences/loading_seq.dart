import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class LoadingSeq extends Sequence {
  @override
  Future<void> onLoad() async {
    final loadingImage = await Flame.images.load('loading.png');
    addAll([
      // 背景をボタンにする(しかし押しても何も起きない)にすることで、背後のゲーム画面での操作を不可能にする
      ButtonComponent(
        button: RectangleComponent(
          size: BoxPusherGame.baseSize,
          paint: Paint()
            ..color = const Color(0x80000000)
            ..style = PaintingStyle.fill
            ..strokeWidth = 2,
        ),
      ),
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
    super.update(dt);
    // ゲームの準備ができたらこのシーケンスを終わる
    if (game.isGameReady()) {
      game.popSeq();
    }
  }

  @override
  void onLangChanged() {}
}
