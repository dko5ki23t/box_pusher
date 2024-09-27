import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/components/confirm_delete_stage_data_dialog.dart';
import 'package:flame/components.dart';
import 'package:flame/layout.dart';
//import 'package:flame/events.dart';
import 'package:flutter/material.dart';
//import 'package:share_plus/share_plus.dart';

class TitleSeq extends Component
    with /*TapCallbacks,*/ HasGameReference<BoxPusherGame> {
  late final TextComponent highScreText;
  late final GameTextButton continueButton;

  @override
  Future<void> onLoad() async {
    highScreText = TextComponent(
      text: "High Score : ${game.highScore}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Aboreto',
          color: Color(0xff000000),
        ),
      ),
    );
    continueButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 380.0),
      anchor: Anchor.center,
      text: "つづきから",
      enabled: game.stageData.isNotEmpty,
      onReleased: () => game.pushAndInitGame(),
    );

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
        text: "はじめから",
        onReleased: () {
          if (game.stageData.isNotEmpty) {
            game.router.pushOverlay('confirm_delete_stage_data_dialog');
          } else {
            game.pushAndInitGame();
          }
        },
      ),
      continueButton,
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
      RectangleComponent(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 480.0),
        anchor: Anchor.center,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: highScreText,
          ),
        ],
      ),
      // TODO: 例外発生 -> MissingPluginException (MissingPluginException(No implementation found for method share on channel dev.fluttercommunity.plus/share))
      // 当面必要ないと思うのでコメントアウト
      /*GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 530.0),
        anchor: Anchor.center,
        text: "シェア",
        onReleased: () => Share.share("共有のテスト"),
      ),*/
    ]);
  }

  @override
  void update(double dt) {
    highScreText.text = "High Score : ${game.highScore}";
    continueButton.enabled = game.stageData.isNotEmpty;
  }

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
