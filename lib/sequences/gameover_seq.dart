import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class GameoverSeq extends Sequence with HasGameReference<BoxPusherGame> {
  late final TextComponent scoreText;

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: "スコア：${game.getCurrentScore()}",
      size: Vector2(320.0, 45.0),
      position: Vector2(180.0, 250.0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          fontSize: 30,
        ),
      ),
    );
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
      TextComponent(
        text: "ゲームオーバー",
        size: Vector2(320.0, 45.0),
        position: Vector2(180.0, 180.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: Config.gameTextFamily,
            fontSize: 35,
          ),
        ),
      ),
      scoreText,
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 300.0),
        anchor: Anchor.center,
        text: "もう一度プレイ",
        onReleased: () => game.pushAndInitGame(),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 350.0),
        anchor: Anchor.center,
        text: "タイトルへ",
        onReleased: () => game.pushSeqNamed('title'),
      ),
    ]);
  }

  @override
  void update(double dt) {
    scoreText.text = "スコア：${game.getCurrentScore()}";
  }
}
