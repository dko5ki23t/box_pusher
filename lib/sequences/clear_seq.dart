import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class ClearSeq extends Sequence {
  late final TextComponent clearText;
  late final GameTextButton continueButton;
  late final GameTextButton toTitleButton;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    clearText = TextComponent(
      text: loc.clear,
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
    continueButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 300.0),
      anchor: Anchor.center,
      text: loc.continueGameAfterClear,
      onReleased: () => game.popSeq(),
    );
    toTitleButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 350.0),
      anchor: Anchor.center,
      text: loc.toTitle,
      onReleased: () => game.pushSeqNamed('title'),
    );
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
      clearText,
      continueButton,
      toTitleButton,
    ]);
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    clearText.text = loc.clear;
    continueButton.text = loc.continueGameAfterClear;
    toTitleButton.text = loc.toTitle;
  }
}
