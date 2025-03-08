import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/components/rounded_component.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfirmExitSeq extends Sequence with KeyboardHandler {
  late final RoundedComponent dialogComponent;
  late final PositionComponent contentComponent;
  late final TextComponent confirmText;
  late final TextComponent confirmText2;
  late final TextComponent confirmText3;
  late final GameButtonGroup buttonGroup;
  late final GameDialogButton yesButton;
  late final GameDialogButton noButton;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    dialogComponent = RoundedComponent(
      position: BoxPusherGame.baseSize * 0.5,
      size: Vector2(300, 200),
      cornerRadius: 5,
      anchor: Anchor.center,
      color: const Color(0x80000000),
      borderColor: Colors.white,
      strokeWidth: 3,
    );
    contentComponent = PositionComponent(
      position: Vector2(20, 20),
      size: Vector2(260, 160),
    );
    dialogComponent.add(contentComponent);
    confirmText = TextComponent(
      text: loc.confirmExit1,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
        ),
      ),
    );
    confirmText2 = TextComponent(
      text: loc.confirmExit2,
      position: Vector2(0, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
        ),
      ),
    );
    confirmText3 = TextComponent(
      text: loc.confirmExit3,
      position: Vector2(0, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
        ),
      ),
    );
    yesButton = GameDialogButton(
      size: Vector2(100.0, 30.0),
      position: Vector2(0.0, 130.0),
      text: loc.dialogYes,
      onReleased: () {
        game.isGiveuping = true;
        game.setGameover();
        game.popSeq();
      },
    );
    noButton = GameDialogButton(
      size: Vector2(100.0, 30.0),
      position: Vector2(160.0, 130.0),
      text: loc.dialogNo,
      onReleased: () => game.popSeq(),
    );
    buttonGroup = GameButtonGroup(
      buttons: [
        yesButton,
        noButton,
      ],
      focusIdx: 1,
    )..focusNext();
    contentComponent
        .addAll([confirmText, confirmText2, confirmText3, yesButton, noButton]);
    addAll([
      // 背景をボタンにする(押すと元の画面に戻る)にすることで、背後のゲーム画面での操作を不可能にする
      ButtonComponent(
        button: RectangleComponent(
          size: BoxPusherGame.baseSize,
          paint: Paint()
            ..color = const Color(0x80000000)
            ..style = PaintingStyle.fill
            ..strokeWidth = 2,
        ),
        onReleased: () => game.popSeq(),
      ),
      dialogComponent,
    ]);
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 終了確認シーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'confirm_exit') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowLeft)) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      buttonGroup.focusPrev();
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowRight)) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
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
  void onUnFocus() {
    // キャンセルボタンにフォーカス
    buttonGroup.focusNext();
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    confirmText.text = loc.confirmExit1;
    confirmText2.text = loc.confirmExit2;
    confirmText3.text = loc.confirmExit3;
    yesButton.text = loc.dialogYes;
    noButton.text = loc.dialogNo;
  }
}
