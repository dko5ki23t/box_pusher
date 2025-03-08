import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameoverSeq extends Sequence with KeyboardHandler {
  late final TextComponent gameoverText;
  late final TextComponent scoreText;
  late final GameButtonGroup buttonGroup;
  late final GameMenuButton restartButton;
  late final GameMenuButton toTitleButton;
  late final GameMenuButton takeOneStepBackButton;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    gameoverText = TextComponent(
      text: loc.gameover,
      size: Vector2(320.0, 45.0),
      position: Vector2(180.0, 180.0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
          fontSize: 35,
        ),
      ),
    );
    scoreText = TextComponent(
      text: "${loc.scoreIs}${game.getCurrentScore()}",
      size: Vector2(320.0, 45.0),
      position: Vector2(180.0, 250.0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
          fontSize: 30,
        ),
      ),
    );
    restartButton = GameMenuButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 330.0),
        anchor: Anchor.center,
        text: loc.tryAgain,
        onReleased: () async {
          game.pushAndInitGame(useLastTreasureData: false);
        });
    toTitleButton = GameMenuButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 380.0),
        anchor: Anchor.center,
        text: loc.toTitle,
        onReleased: () async {
          game.pushSeqNamed('title');
        });
    takeOneStepBackButton = GameMenuButton(
        size: Vector2(120.0, 60.0),
        position: Vector2(180.0, 445.0),
        anchor: Anchor.center,
        text:
            '${loc.takeOneStepBack}\n${loc.score} -${game.requiredScoreToUndo}',
        onReleased: () async {
          await game.setAndSaveOneStepBeforeStageData();
          game.pushAndInitGame(useLastTreasureData: false);
        });
    buttonGroup = GameButtonGroup(buttons: [
      restartButton,
      toTitleButton,
      if (Config().canGoOneTurnBack) takeOneStepBackButton,
    ]);
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
      gameoverText,
      scoreText,
      restartButton,
      toTitleButton,
      if (Config().canGoOneTurnBack) takeOneStepBackButton,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    scoreText.text = "${game.localization.scoreIs}${game.getCurrentScore()}";
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // ゲームオーバーシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'gameover') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      buttonGroup.focusPrev();
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      buttonGroup.focusNext();
    }

    // スペースキー->フォーカスしているボタンを押す
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
    }

    return false;
  }

  @override
  void onFocus(String? before) {
    final loc = game.localization;
    takeOneStepBackButton.text =
        '${loc.takeOneStepBack}\n${loc.score} -${game.requiredScoreToUndo}';
    takeOneStepBackButton.enabled = game.canTakeOneStepBack();
  }

  @override
  void onUnFocus() {
    // ボタン群のフォーカスをクリア
    buttonGroup.unFocus();
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    gameoverText.text = loc.gameover;
    restartButton.text = loc.tryAgain;
    toTitleButton.text = loc.toTitle;
    takeOneStepBackButton.text =
        '${loc.takeOneStepBack}\n${loc.score} -${game.requiredScoreToUndo}';
  }
}
