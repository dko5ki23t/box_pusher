import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/components/rounded_component.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

class AchievementsSeq extends Sequence with KeyboardHandler {
  late final TextComponent achievementsText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton backButton;
  final List<RoundedComponent> achievementTiles = [];
  late final Image trophyImage;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    trophyImage = await Flame.images.load('trophy.png');
    achievementsText = TextComponent(
      text: loc.achievements,
      size: Vector2(150.0, 45.0),
      position: Vector2(60.0, 60.0),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Color(0xff000000),
          fontSize: 30,
        ),
      ),
    );
    backButton = GameTextButton(
      size: Vector2(120.0, 30.0),
      position: Vector2(180.0, 135.0),
      anchor: Anchor.center,
      text: loc.back,
      onReleased: () => game.pushSeqNamed('title'),
    );
    buttonGroup = GameButtonGroup(buttons: [
      backButton,
    ]);
    achievementTiles.add(RoundedComponent(
      position: Vector2(180, 205),
      anchor: Anchor.center,
      borderColor: Colors.grey,
      size: Vector2(240, 70),
      cornerRadius: 5,
      strokeWidth: 1,
      children: [
        PositionComponent(
            position: Vector2(10, 10),
            size: Vector2(220, 50),
            children: [
              SpriteComponent.fromImage(
                trophyImage,
                srcPosition: Vector2(0, 0),
                srcSize: Vector2(128, 180),
                size: Vector2(40, 50),
              ),
              TextComponent(
                text: '女の子を助ける',
                position: Vector2(50, 25),
                anchor: Anchor.centerLeft,
                textRenderer: TextPaint(
                  style: Config.gameTextStyle,
                ),
              ),
            ]),
      ],
    ));
    achievementTiles.add(RoundedComponent(
      position: Vector2(180, 295),
      anchor: Anchor.center,
      borderColor: Colors.grey,
      size: Vector2(240, 70),
      cornerRadius: 5,
      strokeWidth: 1,
      //children: [
      //  AlignComponent(
      //    alignment: Anchor.center,
      //    child: child,
      //  ),
      //],
    ));
    achievementTiles.add(RoundedComponent(
      position: Vector2(180, 385),
      anchor: Anchor.center,
      borderColor: Colors.grey,
      size: Vector2(240, 70),
      cornerRadius: 5,
      strokeWidth: 1,
      //children: [
      //  AlignComponent(
      //    alignment: Anchor.center,
      //    child: child,
      //  ),
      //],
    ));
    achievementTiles.add(RoundedComponent(
      position: Vector2(180, 475),
      anchor: Anchor.center,
      borderColor: Colors.grey,
      size: Vector2(240, 70),
      cornerRadius: 5,
      strokeWidth: 1,
      //children: [
      //  AlignComponent(
      //    alignment: Anchor.center,
      //    child: child,
      //  ),
      //],
    ));

    addAll([
      // 背景
      RectangleComponent(
        size: BoxPusherGame.baseSize,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      ),
      achievementsText,
      backButton,
      ...achievementTiles,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 実績シーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'achievements') return true;
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
  void onUnFocus() {
    // ボタン群のフォーカスをクリア
    buttonGroup.unFocus();
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    backButton.text = loc.back;
  }
}
