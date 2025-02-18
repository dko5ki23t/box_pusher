import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

enum TrophyRarity {
  copper,
  silver,
  gold,
  rainbow,
}

class AchieveComponents {
  final SpriteComponent trophyComponent;
  final TextComponent textComponent;
  late final ButtonComponent levelDownButton;
  late final ButtonComponent levelUpButton;

  AchieveComponents(this.trophyComponent, this.textComponent) {
    levelDownButton = ButtonComponent(
        size: Vector2(10, 50),
        button: AlignComponent(
            alignment: Anchor.center,
            child: PolygonComponent(
                [Vector2(0, 0), Vector2(10, -5), Vector2(10, 5)],
                paint: Paint()..color = Colors.transparent)),
        position: Vector2(0, 25),
        anchor: Anchor.center);
    levelUpButton = ButtonComponent(
        size: Vector2(10, 50),
        button: AlignComponent(
          alignment: Anchor.center,
          child: PolygonComponent(
              [Vector2(10, 0), Vector2(0, -5), Vector2(0, 5)],
              paint: Paint()..color = Colors.transparent),
        ),
        position: Vector2(220, 25),
        anchor: Anchor.center);
  }
}

class AchieveState {
  int achievedLevel = 0;
  int viewLevel = 1;
  final int maxLevel;
  final Map<int, TrophyRarity> levelToRarityMap;
  Map<int, String> levelToTextMap;
  final Map<int, double?> levelToFontSizeMap;

  AchieveState(this.maxLevel, this.levelToRarityMap, this.levelToTextMap,
      this.levelToFontSizeMap);
}

class AchievementsSeq extends Sequence with KeyboardHandler {
  late final TextComponent achievementsText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton backButton;
  final List<GameButton> achievementTiles = [];
  late final Image trophyImage;
  late final Image checkImage;
  late final Map<TrophyRarity, Sprite> trophySprites;
  final List<AchieveComponents> achieveComponents = [];
  final List<AchieveState> achieveStates = [];

  SpriteComponent _trophyComponent(TrophyRarity rarity) {
    return SpriteComponent(
        sprite: trophySprites[rarity]!,
        position: Vector2(10, 0),
        size: Vector2(40, 50),
        children: [
          AlignComponent(
            alignment: Anchor.bottomRight,
            child: SpriteComponent.fromImage(checkImage, size: Vector2(15, 15)),
          ),
        ]);
  }

  void _trophyConfig(SpriteComponent trophy, TrophyRarity rarity, bool isOn) {
    trophy.sprite = trophySprites[rarity];
    trophy
        .add(OpacityEffect.to(isOn ? 1.0 : 0.5, EffectController(duration: 0)));
    ((trophy.children.first as AlignComponent).child as SpriteComponent)
        .add(OpacityEffect.to(isOn ? 1.0 : 0.0, EffectController(duration: 0)));
  }

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    trophyImage = await Flame.images.load('trophy.png');
    checkImage = await Flame.images.load('check.png');
    // 銅・銀・金・虹色のトロフィーのスプライト
    trophySprites = {
      for (final rarity in TrophyRarity.values)
        rarity: Sprite(trophyImage,
            srcPosition: Vector2((rarity.index + 1) * 128, 0),
            srcSize: Vector2(128, 180))
    };
    achieveStates.addAll([
      AchieveState(
          1,
          {1: TrophyRarity.copper},
          {0: loc.achievement1level0, 1: loc.achievement1level1},
          {0: null, 1: null}),
      AchieveState(
          1,
          {1: TrophyRarity.gold},
          {0: loc.achievement2level0, 1: loc.achievement2level1},
          {0: null, 1: null}),
      AchieveState(4, {
        1: TrophyRarity.copper,
        2: TrophyRarity.silver,
        3: TrophyRarity.gold,
        4: TrophyRarity.rainbow
      }, {
        0: loc.achievement3level0,
        1: loc.achievement3level1,
        2: loc.achievement3level2,
        3: loc.achievement3level3,
        4: loc.achievement3level4,
      }, {
        0: null,
        1: 12,
        2: 12,
        3: 12,
        4: 12
      }),
      AchieveState(4, {
        1: TrophyRarity.copper,
        2: TrophyRarity.silver,
        3: TrophyRarity.gold,
        4: TrophyRarity.rainbow
      }, {
        0: loc.achievement4level0,
        1: loc.achievement4level1,
        2: loc.achievement4level2,
        3: loc.achievement4level3,
        4: loc.achievement4level4,
      }, {
        for (int i = 0; i <= 4; i++) i: 10,
      }),
    ]);
    _updateAchieveState();

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
    achieveComponents.addAll([
      // 【実績】女の子を助ける
      AchieveComponents(
        _trophyComponent(TrophyRarity.copper),
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
        _trophyComponent(TrophyRarity.gold), // 金
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
        _trophyComponent(TrophyRarity.silver), // 銀
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
        _trophyComponent(TrophyRarity.copper), // 銅
        TextComponent(
          text: '1ゲームでブロック破壊率を20%にする',
          position: Vector2(70, 25),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
              style: const TextStyle(
                  fontFamily: Config.gameTextFamily,
                  color: Color(0xff000000),
                  fontSize: 10)),
        ),
      ),
    ]);
    Vector2 tilePos = Vector2(180, 205);
    for (final a in achieveComponents) {
      final adding = GameButton(
        position: tilePos.clone(),
        anchor: Anchor.center,
        size: Vector2(240, 70),
        child: PositionComponent(
          size: Vector2(220, 50),
          children: [
            a.trophyComponent,
            a.textComponent,
            a.levelDownButton,
            a.levelUpButton,
          ],
        ),
      );
      adding.enabledFrameColor = Colors.grey;
      adding.button.strokeWidth = 1;
      achievementTiles.add(adding);
      tilePos += Vector2(0, 90);
    }
    buttonGroup = GameButtonGroup(buttons: [
      backButton,
      ...achievementTiles,
    ]);

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

  void _updateAchieveState() {
    // 達成状況を反映
    achieveStates[0].achievedLevel =
        game.achievementData['hasHelpedGirl']! ? 1 : 0;
    achieveStates[1].achievedLevel =
        game.achievementData['maxJewelLevel']! >= 14 ? 1 : 0;
    achieveStates[2].achievedLevel =
        game.achievementData['maxFoundTreasureNum']! >= 9
            ? 4
            : game.achievementData['maxFoundTreasureNum']! >= 6
                ? 3
                : game.achievementData['maxFoundTreasureNum']! >= 3
                    ? 2
                    : game.achievementData['maxFoundTreasureNum']! >= 1
                        ? 1
                        : 0;
    achieveStates[3].achievedLevel =
        game.achievementData['maxBreakBlockRate']! >= 100
            ? 4
            : game.achievementData['maxBreakBlockRate']! >= 80
                ? 3
                : game.achievementData['maxBreakBlockRate']! >= 40
                    ? 2
                    : game.achievementData['maxBreakBlockRate']! >= 20
                        ? 1
                        : 0;
    // 現在の表示レベルを、達成済み+1に設定
    for (final state in achieveStates) {
      state.viewLevel = state.achievedLevel + 1 > state.maxLevel
          ? state.maxLevel
          : state.achievedLevel + 1;
    }
  }

  void _updateAchievementTile() {
    // 達成状況を画面に反映
    for (int i = 0; i < 4; i++) {
      int view = achieveStates[i].viewLevel;
      int achieve = achieveStates[i].achievedLevel;
      // 表示中のレベルに応じてトロフィー画像、テキスト、ボタンを変更する
      _trophyConfig(achieveComponents[i].trophyComponent,
          achieveStates[i].levelToRarityMap[view]!, achieve >= view);
      String desc = achieveStates[i]
          .levelToTextMap[view == 1 && achieve == 0 ? 0 : view]!;
      if (i == 2 && achieve != 0) {
        desc += '(${game.achievementData["maxFoundTreasureNum"]})';
      } else if (i == 3) {
        desc += '(${game.achievementData["maxBreakBlockRate"]}%)';
      }
      achieveComponents[i].textComponent
        ..text = desc
        ..textRenderer = TextPaint(
            style: TextStyle(
                fontFamily: Config.gameTextFamily,
                color: Colors.black,
                fontSize: achieveStates[i].levelToFontSizeMap[achieve]));
      // 右向きボタンについて
      if (view >= achieveStates[i].maxLevel || view > achieve) {
        ((achieveComponents[i].levelUpButton.button as AlignComponent).child
                as PolygonComponent)
            .paint
            .color = Colors.transparent;
        achieveComponents[i].levelUpButton.onPressed = null;
      } else {
        ((achieveComponents[i].levelUpButton.button as AlignComponent).child
                as PolygonComponent)
            .paint
            .color = Colors.grey;
        achieveComponents[i].levelUpButton.onPressed = () {
          achieveStates[i].viewLevel++;
          _updateAchievementTile();
        };
      }
      // 左向きボタンについて
      if (view <= 1) {
        ((achieveComponents[i].levelDownButton.button as AlignComponent).child
                as PolygonComponent)
            .paint
            .color = Colors.transparent;
        achieveComponents[i].levelDownButton.onPressed = null;
      } else {
        ((achieveComponents[i].levelDownButton.button as AlignComponent).child
                as PolygonComponent)
            .paint
            .color = Colors.grey;
        achieveComponents[i].levelDownButton.onPressed = () {
          achieveStates[i].viewLevel--;
          _updateAchievementTile();
        };
      }
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
    int? focusIdx = buttonGroup.focusIdx;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowLeft)) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      if (focusIdx != null && focusIdx > 0) {
        achieveComponents[focusIdx - 1].levelDownButton.onPressed?.call();
      }
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowRight)) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      if (focusIdx != null && focusIdx > 0) {
        achieveComponents[focusIdx - 1].levelUpButton.onPressed?.call();
      }
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
      _updateAchieveState();
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
    achieveStates[0].levelToTextMap = {
      0: loc.achievement1level0,
      1: loc.achievement1level1
    };
    achieveStates[1].levelToTextMap = {
      0: loc.achievement2level0,
      1: loc.achievement2level1
    };
    achieveStates[2].levelToTextMap = {
      0: loc.achievement3level0,
      1: loc.achievement3level1,
      2: loc.achievement3level2,
      3: loc.achievement3level3,
      4: loc.achievement3level4,
    };
    achieveStates[3].levelToTextMap = {
      0: loc.achievement4level0,
      1: loc.achievement4level1,
      2: loc.achievement4level2,
      3: loc.achievement4level3,
      4: loc.achievement4level4,
    };
    _updateAchievementTile();
  }
}
