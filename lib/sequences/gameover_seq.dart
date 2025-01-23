import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameoverSeq extends Sequence with KeyboardHandler {
  late final TextComponent gameoverText;
  late final TextComponent scoreText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton restartButton;
  late final GameTextButton toTitleButton;

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
          fontSize: 30,
        ),
      ),
    );
    restartButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 300.0),
      anchor: Anchor.center,
      text: loc.tryAgain,
      onReleased: () => game.pushAndInitGame(),
    );
    toTitleButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 350.0),
      anchor: Anchor.center,
      text: loc.toTitle,
      onReleased: () => game.pushSeqNamed('title'),
    );
    buttonGroup = GameButtonGroup(buttons: [
      restartButton,
      toTitleButton,
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
    RawKeyEvent event,
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
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
    }

    return false;
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
  }
}
