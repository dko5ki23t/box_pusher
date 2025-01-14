import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/layout.dart';
//import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TitleSeq extends Sequence with /*TapCallbacks,*/ KeyboardHandler {
  late final TextComponent titleText;
  late final TextComponent highScreText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton newGameButton;
  late final GameTextButton continueButton;
  late final GameTextButton languageButton;
  late final GameTextButton versionLogButton;
  late final Image bugImage;
  //late final GameButton debugOnOffButton;
  late final GameTextButton debugButton;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    titleText = TextComponent(
      text: loc.gameTitle,
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
    );
    highScreText = TextComponent(
      text: "${loc.highScore} : ${game.highScore}",
      textRenderer: TextPaint(
        style: Config.gameTextStyle,
      ),
    );
    newGameButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 310.0),
      anchor: Anchor.center,
      text: loc.newGame,
      onReleased: () {
        if (game.stageData.isNotEmpty) {
          game.pushSeqOverlay('confirm_delete_stage_data_dialog');
        } else {
          game.pushAndInitGame();
        }
      },
    );
    continueButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 360.0),
      anchor: Anchor.center,
      text: loc.loadGame,
      enabled: game.stageData.isNotEmpty,
      onReleased: () => game.pushAndInitGame(),
    );
    buttonGroup = GameButtonGroup(buttons: [
      newGameButton,
      continueButton,
    ]);
    languageButton = GameTextButton(
      size: Vector2(80.0, 20.0),
      position: Vector2(300.0, 40.0),
      anchor: Anchor.center,
      text: loc.language,
      onReleased: () => game.changeLocale(),
    );
    versionLogButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 410.0),
      anchor: Anchor.center,
      text: loc.versionLog,
      onReleased: () async {
        game.pushSeqOverlay('version_log_dialog');
      },
    );
    debugButton = GameTextButton(
      size: Vector2(80.0, 30.0),
      position: Vector2(160.0, 460.0),
      anchor: Anchor.centerLeft,
      enabled: game.testMode,
      text: loc.debug,
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
      titleText,
      newGameButton,
      continueButton,
      languageButton,
      versionLogButton,
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
    super.update(dt);
    highScreText.text = "${game.localization.highScore} : ${game.highScore}";
    continueButton.enabled = game.stageData.isNotEmpty;
    debugButton.enabled = game.testMode;
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // タイトルシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'title') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      buttonGroup.focusPrev();
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      buttonGroup.focusNext();
    }

    // スペースキー->フォーカスしているボタンを押す
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
      buttonGroup.unFocus();
    }

    return false;
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    titleText.text = loc.gameTitle;
    newGameButton.text = loc.newGame;
    continueButton.text = loc.loadGame;
    languageButton.text = loc.language;
    versionLogButton.text = loc.versionLog;
    debugButton.text = loc.debug;
  }
}
