import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class MenuSeq extends Component with HasGameReference<BoxPusherGame> {
  @override
  Future<void> onLoad() async {
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
        text: "メニュー",
        size: Vector2(320.0, 45.0),
        position: Vector2(180.0, 180.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Aboreto',
            fontSize: 35,
          ),
        ),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 300.0),
        anchor: Anchor.center,
        text: "ゲームに戻る",
        // TODO: ここだけonPressedなのは、onReleasedだとこの後ボタンが表示されなくなるから。原因究明求む
        onPressed: () => game.router.pop(),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 350.0),
        anchor: Anchor.center,
        text: "最初から",
        // TODO: ここだけonPressedなのは、onReleasedだとこの後ボタンが表示されなくなるから。原因究明求む
        onPressed: () {
          game.resetGame();
          game.router.pop();
        },
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 400.0),
        anchor: Anchor.center,
        text: "一時中断する",
        onReleased: () async {
          await game.setAndSaveStageData();
          game.router.pushNamed('title');
        },
      ),
      GameTextButton(
          size: Vector2(120.0, 30.0),
          position: Vector2(180.0, 450.0),
          anchor: Anchor.center,
          text: "あきらめる",
          onReleased: () async {
            await game.clearAndSaveStageData();
            game.router.pushNamed('title');
          }),
    ]);
  }
}