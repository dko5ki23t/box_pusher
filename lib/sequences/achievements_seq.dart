import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/components/rounded_component.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

class AchieveComponents {
  final SpriteComponent trophyComponent;
  final TextComponent textComponent;

  AchieveComponents(this.trophyComponent, this.textComponent);
}

class AchievementsSeq extends Sequence with KeyboardHandler {
  late final TextComponent achievementsText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton backButton;
  final List<RoundedComponent> achievementTiles = [];
  late final Image trophyImage;
  late final List<Sprite> trophySprites;
  final List<AchieveComponents> achieveComponents = [];

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    trophyImage = await Flame.images.load('trophy.png');
    // 銅・銀・金・虹色のトロフィーのスプライト
    trophySprites = [
      for (int i = 1; i <= 4; i++)
        Sprite(trophyImage,
            srcPosition: Vector2(i * 128, 0), srcSize: Vector2(128, 180))
    ];
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
    achieveComponents.addAll([
      // 【実績】女の子を助ける
      AchieveComponents(
        SpriteComponent(
          sprite: trophySprites[0], // 銅
          position: Vector2(10, 0),
          size: Vector2(40, 50),
        ),
        TextComponent(
          text: '女の子を助ける',
          position: Vector2(70, 25),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
            style: Config.gameTextStyle,
          ),
        ),
      ),
      // 【実績】ダイヤを作る
      AchieveComponents(
        SpriteComponent(
          sprite: trophySprites[2], // 金
          position: Vector2(10, 0),
          size: Vector2(40, 50),
        ),
        TextComponent(
          text: '？？？（宝石）を作る',
          position: Vector2(70, 25),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
            style: Config.gameTextStyle,
          ),
        ),
      ),
      // 【実績】宝箱を見つける
      AchieveComponents(
        SpriteComponent(
          sprite: trophySprites[1], // 銀
          position: Vector2(10, 0),
          size: Vector2(40, 50),
        ),
        TextComponent(
          text: '？？？を見つける',
          position: Vector2(70, 25),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
            style: Config.gameTextStyle,
          ),
        ),
      ),
      // 【実績】1ゲームでブロック破壊率を20%にする
      AchieveComponents(
        SpriteComponent(
          sprite: trophySprites[0], // 銅
          position: Vector2(10, 0),
          size: Vector2(40, 50),
        ),
        TextComponent(
          text: '1ゲームでブロック破壊率を20%にする',
          position: Vector2(70, 25),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
              style: const TextStyle(
                  fontFamily: Config.gameTextFamily,
                  color: Color(0xff000000),
                  fontSize: 12)),
        ),
      ),
    ]);
    Vector2 tilePos = Vector2(180, 205);
    for (final a in achieveComponents) {
      achievementTiles.add(RoundedComponent(
        position: tilePos.clone(),
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
              a.trophyComponent,
              a.textComponent,
            ],
          ),
        ],
      ));
      tilePos += Vector2(0, 90);
    }

    _updateAchievementTile();

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

  void _updateAchievementTile() {
    // 達成状況を画面に反映
    if (game.achievementData['hasHelpedGirl']!) {
      achieveComponents[0]
          .trophyComponent
          .add(OpacityEffect.to(1.0, EffectController(duration: 0)));
    } else {
      achieveComponents[0]
          .trophyComponent
          .add(OpacityEffect.to(0.5, EffectController(duration: 0)));
    }
    if (game.achievementData['maxJewelLevel']! >= 14) {
      achieveComponents[1]
          .trophyComponent
          .add(OpacityEffect.to(1.0, EffectController(duration: 0)));
      achieveComponents[1].textComponent.text = 'ダイヤモンドを作る';
    } else {
      achieveComponents[1]
          .trophyComponent
          .add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[1].textComponent.text = '？？？（宝石）を作る';
    }
    if (game.achievementData['maxFoundTreasureNum']! >= 9) {
      achieveComponents[2].trophyComponent
        ..sprite = trophySprites[3] // 虹
        ..add(OpacityEffect.to(1.0, EffectController(duration: 0)));
      achieveComponents[2].textComponent
        ..text =
            '1ゲームで宝箱を\n9個見つける(${game.achievementData["maxFoundTreasureNum"]!})'
        ..textRenderer = TextPaint(
            style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Color(0xff000000),
                fontSize: 12));
    } else if (game.achievementData['maxFoundTreasureNum']! >= 6) {
      achieveComponents[2].trophyComponent
        ..sprite = trophySprites[3] // 虹
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[2].textComponent
        ..text =
            '1ゲームで宝箱を\n9個見つける(${game.achievementData["maxFoundTreasureNum"]!})'
        ..textRenderer = TextPaint(
            style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Color(0xff000000),
                fontSize: 12));
    } else if (game.achievementData['maxFoundTreasureNum']! >= 3) {
      achieveComponents[2].trophyComponent
        ..sprite = trophySprites[2] // 金
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[2].textComponent
        ..text =
            '1ゲームで宝箱を\n6個見つける(${game.achievementData["maxFoundTreasureNum"]!})'
        ..textRenderer = TextPaint(
            style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Color(0xff000000),
                fontSize: 12));
    } else if (game.achievementData['maxFoundTreasureNum']! >= 1) {
      achieveComponents[2].trophyComponent
        ..sprite = trophySprites[1] // 銀
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[2].textComponent
        ..text =
            '1ゲームで宝箱を\n3個見つける(${game.achievementData["maxFoundTreasureNum"]!})'
        ..textRenderer = TextPaint(
            style: const TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Color(0xff000000),
                fontSize: 12));
    } else {
      achieveComponents[2].trophyComponent
        ..sprite = trophySprites[0] // 銅
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[2].textComponent
        ..text = '？？？を見つける'
        ..textRenderer = TextPaint(
          style: Config.gameTextStyle,
        );
    }
    if (game.achievementData['maxBreakBlockRate']! >= 100) {
      achieveComponents[3].trophyComponent
        ..sprite = trophySprites[3] // 虹
        ..add(OpacityEffect.to(1.0, EffectController(duration: 0)));
      achieveComponents[3].textComponent.text =
          '1ゲームでブロック破壊率を\n100%にする(${game.achievementData["maxBreakBlockRate"]!}%)';
    } else if (game.achievementData['maxBreakBlockRate']! >= 80) {
      achieveComponents[3].trophyComponent
        ..sprite = trophySprites[3] // 虹
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[3].textComponent.text =
          '1ゲームでブロック破壊率を\n100%にする(${game.achievementData["maxBreakBlockRate"]!}%)';
    } else if (game.achievementData['maxBreakBlockRate']! >= 40) {
      achieveComponents[3].trophyComponent
        ..sprite = trophySprites[2] // 金
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[3].textComponent.text =
          '1ゲームでブロック破壊率を\n80%にする(${game.achievementData["maxBreakBlockRate"]!}%)';
    } else if (game.achievementData['maxBreakBlockRate']! >= 20) {
      achieveComponents[3].trophyComponent
        ..sprite = trophySprites[1] // 銀
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[3].textComponent.text =
          '1ゲームでブロック破壊率を\n40%にする(${game.achievementData["maxBreakBlockRate"]!}%)';
    } else {
      achieveComponents[3].trophyComponent
        ..sprite = trophySprites[0] // 銅
        ..add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      achieveComponents[3].textComponent.text =
          '1ゲームでブロック破壊率を\n20%にする(${game.achievementData["maxBreakBlockRate"]!}%)';
    }
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
  void onFocus(String? before) {
    if (achieveComponents.isNotEmpty) {
      _updateAchievementTile();
    }
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
