import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/layout.dart';
//import 'package:flame/events.dart';
import 'package:flutter/material.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TitleSeq extends Sequence
    with /*TapCallbacks,*/ HasGameReference<BoxPusherGame> {
  late final TextComponent highScreText;
  late final GameTextButton continueButton;
  late final Image bugImage;
  late final GameTextButton debugButton;

  @override
  Future<void> onLoad() async {
    highScreText = TextComponent(
      text: "High Score : ${game.highScore}",
      textRenderer: TextPaint(
        style: Config.gameTextStyle,
      ),
    );
    continueButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 360.0),
      anchor: Anchor.center,
      text: "つづきから",
      enabled: game.stageData.isNotEmpty,
      onReleased: () => game.pushAndInitGame(),
    );
    debugButton = GameTextButton(
      size: Vector2(80.0, 30.0),
      position: Vector2(160.0, 460.0),
      anchor: Anchor.centerLeft,
      enabled: game.testMode,
      text: "デバッグ",
      onReleased: () async {
        game.pushSeqOverlay('debug_dialog');
      },
    );
    // アプリバージョン等取得
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    addAll([
      // 背景
      RectangleComponent(
        size: BoxPusherGame.baseSize,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      ),
      TextComponent(
        text: "押しごと",
        size: Vector2(150.0, 45.0),
        position: Vector2(180.0, 260.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: Config.gameTextFamily,
            color: Color(0xff000000),
            fontSize: 40,
          ),
        ),
      ),
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 310.0),
        anchor: Anchor.center,
        text: "はじめから",
        onReleased: () {
          if (game.stageData.isNotEmpty) {
            game.pushSeqOverlay('confirm_delete_stage_data_dialog');
          } else {
            game.pushAndInitGame();
          }
        },
      ),
      continueButton,
      GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 410.0),
        anchor: Anchor.center,
        text: "バージョンログ",
        onReleased: () async {
          game.pushSeqOverlay('version_log_dialog');
        },
      ),
      GameSpriteOnOffButton(
        size: Vector2.all(30),
        position: Vector2(120.0, 460.0),
        anchor: Anchor.centerLeft,
        isOn: game.testMode,
        onChanged: (isOn) => game.testMode = !game.testMode,
        sprite: await Sprite.load('bug_report.png'),
      ),
      // TODO:コメント外す
      //if (game.testMode)
      debugButton,
      RectangleComponent(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 510.0),
        anchor: Anchor.center,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: highScreText,
          ),
        ],
      ),
      TextComponent(
        text: 'Ver.${packageInfo.version}',
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 550.0),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: Config.gameTextStyle,
        ),
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
    debugButton.enabled = game.testMode;
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
