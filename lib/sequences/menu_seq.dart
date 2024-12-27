import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuSeq extends Sequence
    with HasGameReference<BoxPusherGame>, KeyboardHandler {
  late final GameButtonGroup buttonGroup;
  late final GameButton resumeButton;
  late final GameButton saveButton;
  late final GameButton giveUpButton;

  @override
  Future<void> onLoad() async {
    resumeButton = GameTextButton(
      keyName: 'resume',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 300.0),
      anchor: Anchor.center,
      text: "ゲームに戻る",
      onReleased: () => game.popSeq(),
    );
    saveButton = GameTextButton(
      keyName: 'save',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 350.0),
      anchor: Anchor.center,
      text: "一時中断する",
      onReleased: () async {
        await game.setAndSaveStageData();
        game.pushSeqNamed('title');
      },
    );
    giveUpButton = GameTextButton(
      keyName: 'giveUp',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 400.0),
      anchor: Anchor.center,
      text: "あきらめる",
      onReleased: () async {
        await game.clearAndSaveStageData();
        game.pushSeqNamed('title');
      },
    );
    buttonGroup = GameButtonGroup(buttons: [
      resumeButton,
      saveButton,
      giveUpButton,
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
      TextComponent(
        text: "メニュー",
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
      resumeButton, saveButton,
      giveUpButton,
    ]);
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // メニューシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'menu') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      buttonGroup.focusPrev();
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      buttonGroup.focusNext();
    }

    // Escキー->メニューを閉じる
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.escape)) {
      game.popSeq();
    }

    // スペースキー->フォーカスしているボタンを押す
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
      buttonGroup.unFocus();
    }

    return false;
  }
}
