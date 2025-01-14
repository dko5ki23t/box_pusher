import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuSeq extends Sequence with KeyboardHandler {
  late final GameButtonGroup buttonGroup;
  late final GameTextButton resumeButton;
  late final GameTextButton saveButton;
  late final GameTextButton giveUpButton;
  late final GameTextButton controllSettingButton;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    resumeButton = GameTextButton(
      keyName: 'resume',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 300.0),
      anchor: Anchor.center,
      text: loc.resume,
      onReleased: () => game.popSeq(),
    );
    saveButton = GameTextButton(
      keyName: 'save',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 350.0),
      anchor: Anchor.center,
      text: loc.save,
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
      text: loc.exit,
      onReleased: () async {
        await game.clearAndSaveStageData();
        game.pushSeqNamed('title');
      },
    );
    controllSettingButton = GameTextButton(
      keyName: 'controllSetting',
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 450.0),
      anchor: Anchor.center,
      text: "${loc.controller}${Config().playerControllButtonType + 1}",
      onReleased: () => Config().changePlayerControllButtonType(),
    );
    buttonGroup = GameButtonGroup(buttons: [
      resumeButton,
      saveButton,
      giveUpButton,
      controllSettingButton,
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
        text: loc.menu,
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
      giveUpButton, controllSettingButton,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    controllSettingButton.text =
        "${game.localization.controller}${Config().playerControllButtonType + 1}";
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
      if (buttonGroup.getCurrentFocusButton()?.keyName != "controllSetting") {
        buttonGroup.unFocus();
      }
    }

    return false;
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    resumeButton.text = loc.resume;
    saveButton.text = loc.save;
    giveUpButton.text = loc.exit;
  }
}
