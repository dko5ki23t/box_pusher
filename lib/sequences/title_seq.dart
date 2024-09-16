import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:flame/components.dart';
//import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class TitleSeq extends Component
    with /*TapCallbacks,*/ HasGameReference<BoxPusherGame> {
  @override
  Future<void> onLoad() async {
    addAll([
      // 背景
      RectangleComponent(
        size: BoxPusherGame.baseSize,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      ),
      TextComponent(
        text: "箱推し",
        size: Vector2(150.0, 45.0),
        position: Vector2(180.0, 280.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Aboreto',
            color: Color(0xff000000),
            fontSize: 40,
          ),
        ),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 330.0),
        anchor: Anchor.center,
        text: "クエスト",
        onReleased: () => game.router.pushNamed('quest'),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 380.0),
        anchor: Anchor.center,
        text: "エンドレス",
        onReleased: () => game.pushAndInitGame(mode: GameMode.endless),
      ),
      if (game.testMode)
        GameTextButton(
          size: Vector2(120.0, 30.0),
          position: Vector2(180.0, 430.0),
          anchor: Anchor.center,
          text: "デバッグ",
          onReleased: () async {
            game.router.pushOverlay('debug_dialog');
          },
        ),
    ]);
  }

  @override
  void update(double dt) {}

  // TapCallbacks実装時には必要(PositionComponentでは不要)
//  @override
//  bool containsLocalPoint(Vector2 point) => true;
//
//  // タップで指を離したとき
//  @override
//  void onTapUp(TapUpEvent event) {
//    // ステージ選択へ
//    game.router.pushNamed('select');
//  }
}
