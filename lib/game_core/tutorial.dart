import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/opacity_effect_text_component.dart';
import 'package:push_and_merge/components/rounded_component.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/girl.dart';
import 'package:push_and_merge/game_core/stage_objs/player.dart';
import 'package:push_and_merge/game_core/stage_objs/swordsman.dart';
import 'package:push_and_merge/sequences/game_seq.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

/// チュートリアル
enum TutorialState {
  /// 移動
  move,

  /// プッシュ
  push,

  /// マージ
  merge,

  /// 動物
  animals,

  /// 女の子を助けよう
  girl,

  /// 敵に触れるとゲームオーバー
  enemy,

  /// その他操作
  other,

  /// 手の能力
  handAbility,

  /// 足の能力
  legAbility,

  /// ポケットの能力
  pocketAbility,

  /// アーマーの能力
  armerAbility,

  /// 予知能力
  eyeAbility,

  /// マージの能力
  mergeAbility,

  /// 宝箱を開けた
  openTreasureBox,
}

/// チュートリアルを管理するclass
class Tutorial {
  /// 現在のチュートリアル
  TutorialState? current = TutorialState.move;

  /// 前フレームのチュートリアル
  TutorialState? _prev;

  double _countForTutorial = 0.0;

  /// マージチュートリアルが画面に表示されているか
  bool isMergeVisible = false;

  /// 移動チュートリアルで移動した向き
  Move _firstMoving = Move.none;

  /// 「タップまたはスペースキーで次へ」の領域
  PositionComponent tapOrSpaceToNextComponent(
    Vector2 position,
    BoxPusherGame game,
  ) {
    final tapOrSpaceToNextSize = game.lang == Language.japanese
        ? (kIsWeb ? Vector2(250, 40) : Vector2(110, 40))
        : (kIsWeb ? Vector2(200, 40) : Vector2(120, 40));
    const tapOrSpaceToNextTextStyle = TextStyle(
      fontFamily: Config.gameTextFamily,
      color: Colors.white,
      fontSize: 20,
    );
    final tapOrSpaceToNextPosList = game.lang == Language.japanese
        ? [
            Vector2(0, 0),
            Vector2(125, 0),
            Vector2(190, 0),
          ]
        : [
            Vector2(0, 0),
            Vector2(68, 0),
            Vector2(140, 0),
          ];
    SequenceEffect tapOrSpaceToNextEffect() => SequenceEffect(
          [
            OpacityEffect.fadeIn(
              EffectController(duration: 1.0),
            ),
            OpacityEffect.fadeOut(
              EffectController(duration: 1.0),
            ),
          ],
          infinite: true,
        );

    // web(キーボードが使える)場合とそれ以外で表示内容変えてる
    return PositionComponent(
      position: position,
      size: tapOrSpaceToNextSize,
      anchor: Anchor.center,
      children: [
        OpacityEffectTextComponent(
          text: kIsWeb ? game.localization.tapOr : game.localization.tapToNext,
          textRenderer: TextPaint(
            style: tapOrSpaceToNextTextStyle,
          ),
          children: [tapOrSpaceToNextEffect()],
        ),
        if (kIsWeb)
          SpriteAnimationComponent.fromFrameData(
            spaceKeyImg,
            SpriteAnimationData.sequenced(
                amount: 2,
                stepTime: Stage.objectStepTime,
                textureSize: Vector2(34, 15)),
            position: tapOrSpaceToNextPosList[1],
            size: Vector2(60, 30),
            children: [tapOrSpaceToNextEffect()],
          ),
        if (kIsWeb)
          OpacityEffectTextComponent(
            text: game.localization.toNext,
            textRenderer: TextPaint(
              style: tapOrSpaceToNextTextStyle,
            ),
            position: tapOrSpaceToNextPosList[2],
            children: [tapOrSpaceToNextEffect()],
          ),
      ],
    );
  }

  /// 「タップまたはスペースキーでゲームに戻る」の領域
  PositionComponent tapOrSpaceToReturnComponent(
    Vector2 position,
    BoxPusherGame game,
  ) {
    final tapOrSpaceToReturnSize = game.lang == Language.japanese
        ? (kIsWeb ? Vector2(250, 80) : Vector2(200, 80))
        : (kIsWeb ? Vector2(200, 80) : Vector2(180, 80));
    const tapOrSpaceToReturnTextStyle = TextStyle(
      fontFamily: Config.gameTextFamily,
      color: Colors.white,
      fontSize: 20,
    );
    final tapOrSpaceToReturnPosList = game.lang == Language.japanese
        ? [
            kIsWeb ? Vector2(20, 0) : Vector2(0, 40),
            Vector2(145, 0),
            Vector2(210, 0),
          ]
        : [
            kIsWeb ? Vector2(40, 0) : Vector2(0, 40),
            Vector2(108, 0),
            Vector2(140, 0),
          ];
    SequenceEffect tapOrSpaceToReturnEffect() => SequenceEffect(
          [
            OpacityEffect.fadeIn(
              EffectController(duration: 1.0),
            ),
            OpacityEffect.fadeOut(
              EffectController(duration: 1.0),
            ),
          ],
          infinite: true,
        );

    return PositionComponent(
      position: position,
      size: tapOrSpaceToReturnSize,
      anchor: Anchor.center,
      children: [
        OpacityEffectTextComponent(
          text: kIsWeb
              ? game.localization.tapOr
              : game.localization.tapToReturnGame,
          position: tapOrSpaceToReturnPosList[0],
          textRenderer: TextPaint(
            style: tapOrSpaceToReturnTextStyle,
          ),
          children: [tapOrSpaceToReturnEffect()],
        ),
        if (kIsWeb)
          SpriteAnimationComponent.fromFrameData(
            spaceKeyImg,
            SpriteAnimationData.sequenced(
                amount: 2,
                stepTime: Stage.objectStepTime,
                textureSize: Vector2(34, 15)),
            position: tapOrSpaceToReturnPosList[1],
            size: Vector2(60, 30),
            children: [tapOrSpaceToReturnEffect()],
          ),
        if (kIsWeb)
          OpacityEffectTextComponent(
            text: game.localization.to,
            textRenderer: TextPaint(
              style: tapOrSpaceToReturnTextStyle,
            ),
            position: tapOrSpaceToReturnPosList[2],
            children: [tapOrSpaceToReturnEffect()],
          ),
        if (kIsWeb)
          OpacityEffectTextComponent(
            text: game.localization.returnGame,
            textRenderer: TextPaint(
              style: tapOrSpaceToReturnTextStyle,
            ),
            position: tapOrSpaceToReturnSize * 0.5,
            anchor: Anchor.topCenter,
            children: [tapOrSpaceToReturnEffect()],
          ),
      ],
    );
  }

  /// 能力習得画面コンポーネント
  ButtonComponent gotAbilityScreen({
    required BoxPusherGame game,
    required PlayerAbility ability,
    required Image animalImg,
    required List<Component> descriptions,
    Vector2? imgTextureSize,
  }) {
    return ButtonComponent(
      onReleased: () {
        current = null;
      },
      size: BoxPusherGame.baseSize,
      button: CustomPainterComponent(
        size: BoxPusherGame.baseSize,
        painter: TutorialCircleHolePainter(
          radius: GameSeq.abilityButtonAreaSize.x,
          center: gameSeq.getAbilityButtonPos(ability) +
              GameSeq.abilityButtonAreaSize * 0.5,
        ),
        children: [
          SpriteComponent.fromImage(
            gotAbilityImg,
            size: Vector2(280, 50),
            position: Vector2(BoxPusherGame.baseSize.x * 0.5, 150),
            anchor: Anchor.center,
          ),
          RoundedComponent(
            size: Vector2(Stage.cellSize.x * 3, Stage.cellSize.y * 0.8),
            cornerRadius: 25,
            color: const Color(0xc0ffffff),
            position: Vector2(BoxPusherGame.baseSize.x * 0.5, 210),
            anchor: Anchor.center,
            priority: Stage.frontPriority,
            children: [
              AlignComponent(
                  alignment: Anchor.center,
                  child: TextComponent(
                    text: 'THANK YOU',
                    textRenderer: TextPaint(
                      style: Config.gameTextStyle,
                    ),
                  )),
            ],
          ),
          CircleComponent(
            position: Vector2(BoxPusherGame.baseSize.x * 0.5, 260),
            anchor: Anchor.center,
            scale: Vector2.all(1.4),
            radius: 20,
            paint: Paint()..color = const Color(0xc0ffffff),
          ),
          SpriteAnimationComponent.fromFrameData(
            animalImg,
            SpriteAnimationData.sequenced(
              amount: 2,
              stepTime: Stage.objectStepTime,
              textureSize: imgTextureSize ?? Stage.cellSize,
            ),
            position: Vector2(BoxPusherGame.baseSize.x * 0.5, 260),
            anchor: Anchor.center,
            scale: Vector2.all(1.4),
          ),
          ...descriptions,
          tapOrSpaceToReturnComponent(
            Vector2(BoxPusherGame.baseSize.x * 0.5, 530),
            game,
          ),
        ],
      ),
    );
  }

  late final Image tutorial1Img;
  late final Image longTapImg;
  late final Image tutorial2Img;
  late final Image tutorial3Img;
  late final Image spaceKeyImg;
  late final Image girlImg;
  late final Image spikeImg;
  late final Image swordsmanImg;
  late final Image swordsmanAttackImg;
  late final Image pinchInOutImg;
  late final Image mouseWheelImg;
  late final Image gotAbilityImg;
  late final Image gorillaImg;
  late final Image rabbitImg;
  late final Image kangarooImg;
  late final Image turtleImg;
  late final Image treasureBoxImg;
  late final Image shiftKeyImg;
  late final Image upKeyImg;
  late final Image downKeyImg;
  late final Image leftKeyImg;
  late final Image rightKeyImg;
  late final Image pKeyImg;
  late final SpriteAnimation tutorial1KeyboardAnimation;
  late final Sprite tutorial1OrSprite;
  late final Sprite tutorial1OrAndArrowSprite;
  late final Sprite tutorial1ToMoveSprite;
  late final Sprite tutorial1TapToMoveSprite;

  late final PositionComponent tutorialArea;

  final GameSeq gameSeq;

  Tutorial({required this.gameSeq});

  Future<void> onLoad() async {
    tutorial1Img = await Flame.images.load('tutorial1.png');
    longTapImg = await Flame.images.load('long_tap.png');
    tutorial2Img = await Flame.images.load('tutorial2.png');
    tutorial3Img = await Flame.images.load('tutorial3.png');
    spaceKeyImg = await Flame.images.load('space_key_icon.png');
    girlImg = await Flame.images.load('girl_org.png');
    spikeImg = await Flame.images.load('spike.png');
    swordsmanImg = await Flame.images.load('swordsman.png');
    swordsmanAttackImg = await Flame.images.load('swordsman_attackD1.png');
    pinchInOutImg = await Flame.images.load('pinch_inout.png');
    mouseWheelImg = await Flame.images.load('mouse_wheel.png');
    gotAbilityImg = await Flame.images.load('tutorial_ability.png');
    gorillaImg = await Flame.images.load('gorilla_org.png');
    rabbitImg = await Flame.images.load('rabbit_org.png');
    kangarooImg = await Flame.images.load('kangaroo_org.png');
    turtleImg = await Flame.images.load('turtle_org.png');
    treasureBoxImg = await Flame.images.load('treasure_box_opened.png');
    shiftKeyImg = await Flame.images.load('shift_key_icon.png');
    upKeyImg = await Flame.images.load('up_key_icon.png');
    downKeyImg = await Flame.images.load('down_key_icon.png');
    leftKeyImg = await Flame.images.load('left_key_icon.png');
    rightKeyImg = await Flame.images.load('right_key_icon.png');
    pKeyImg = await Flame.images.load('p_key_icon.png');
    tutorial1KeyboardAnimation = SpriteAnimation.fromFrameData(
        tutorial1Img,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: Stage.objectStepTime,
          texturePosition: Vector2.zero(),
          textureSize: Vector2(203, 40),
        ));
    tutorial1OrSprite = Sprite(
      tutorial1Img,
      srcPosition: Vector2(285, 50),
      srcSize: Vector2(32, 16),
    );
    tutorial1OrAndArrowSprite = Sprite(
      tutorial1Img,
      srcPosition: Vector2(75, 50),
      srcSize: Vector2(50, 65),
    );
    tutorial1ToMoveSprite = Sprite(
      tutorial1Img,
      srcPosition: Vector2(75, 120),
      srcSize: Vector2(110, 20),
    );
    tutorial1TapToMoveSprite = Sprite(
      tutorial1Img,
      srcPosition: Vector2(75, 150),
      srcSize: Vector2(150, 22),
    );

    // チュートリアル表示領域
    tutorialArea = PositionComponent(
      position: Vector2.zero(),
      size: BoxPusherGame.baseSize,
    );
  }

  /// チュートリアル表示の更新、戻り値は、以降のupdate()を停止するかどうか
  bool updateTutorial(
    double dt,
    Move playerMoving,
    BoxPusherGame game,
  ) {
    final loc = game.localization;
    // チュートリアル変更時
    if (_prev != current) {
      tutorialArea.removeAll(tutorialArea.children);
      switch (current) {
        case TutorialState.move:
          updateMoveTutorial();
          _countForTutorial = 0.0;
          break;
        case TutorialState.push:
          break;
        case TutorialState.merge:
          break;
        case TutorialState.animals:
          // カメラをステージの原点位置に移動
          game.camera.moveTo(Vector2(Stage.cellSize.x * 0.5, 0),
              speed: Stage.cellSize.x * 3);
          // ゴリラとうさぎの場所取得
          // (0, 0)
          final original = (Vector2(
                          BoxPusherGame.baseSize.x,
                          640.0 -
                              GameSeq.topPaddingSize.y -
                              GameSeq.menuButtonAreaSize.y +
                              44) -
                      Stage.cellSize) *
                  0.5 +
              Vector2(-4, 28);

          final gorilaPos = original + Vector2(-4, -4) * Stage.cellSize.x;
          final bunnyPos = original + Vector2(4, 4) * Stage.cellSize.x;
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = TutorialState.girl;
                },
                size: BoxPusherGame.baseSize,
                button: CustomPainterComponent(
                    size: BoxPusherGame.baseSize,
                    painter: TutorialMultiRRectHolePainter(
                      ltToWh: {
                        gorilaPos: Vector2.all(40),
                        bunnyPos: Vector2.all(40),
                      },
                      radius: 8,
                    )),
              ),
              TextComponent(
                text: game.localization.animalTutorial1,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 40),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.animalTutorial2,
                position: Vector2(
                        BoxPusherGame.baseSize.x,
                        640.0 -
                            GameSeq.topPaddingSize.y -
                            GameSeq.menuButtonAreaSize.y) *
                    0.5,
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              tapOrSpaceToNextComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 550),
                game,
              ),
            ],
          );
          break;
        case TutorialState.girl:
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = TutorialState.enemy;
                },
                size: BoxPusherGame.baseSize,
                button: RectangleComponent(
                    size: BoxPusherGame.baseSize,
                    paint: Paint()..color = const Color(0x80000000)),
              ),
              CircleComponent(
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.4),
                radius: 20,
                paint: Paint()..color = const Color(0xc0ffffff),
              ),
              SpriteAnimationComponent.fromFrameData(
                girlImg,
                SpriteAnimationData.sequenced(
                    amount: 2,
                    stepTime: Stage.objectStepTime,
                    textureSize: Girl.girlImgSize),
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.2),
              ),
              TextComponent(
                text: game.localization.girlTutorial1,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 40),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.girlTutorial2,
                position: Vector2(
                        BoxPusherGame.baseSize.x,
                        640.0 -
                            GameSeq.topPaddingSize.y -
                            GameSeq.menuButtonAreaSize.y) *
                    0.5,
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              tapOrSpaceToNextComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 550),
                game,
              ),
            ],
          );
          break;
        case TutorialState.enemy:
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = TutorialState.other;
                },
                size: BoxPusherGame.baseSize,
                button: RectangleComponent(
                    size: BoxPusherGame.baseSize,
                    paint: Paint()..color = const Color(0x80000000)),
              ),
              CircleComponent(
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(40, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.4),
                radius: 20,
                paint: Paint()..color = const Color(0xc0ffffff),
              ),
              SpriteAnimationComponent.fromFrameData(
                spikeImg,
                SpriteAnimationData.sequenced(
                    amount: 2,
                    stepTime: Stage.objectStepTime,
                    textureSize: Stage.cellSize),
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(40, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.2),
              ),
              CircleComponent(
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(-40, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.4),
                radius: 30,
                paint: Paint()..color = const Color(0xc0ffffff),
              ),
              SpriteAnimationComponent(
                animation: SpriteAnimation.spriteList(
                  [
                    for (int i = 0; i < 5; i++)
                      Sprite(swordsmanAttackImg,
                          srcPosition: Vector2(i * 96, 0),
                          srcSize: Vector2(96, 64)),
                    for (int i = 0; i < 3; i++) ...[
                      for (int j = 0; j < 3; j++)
                        Sprite(swordsmanImg, srcSize: Stage.cellSize),
                      for (int j = 0; j < 3; j++)
                        Sprite(swordsmanImg,
                            srcPosition: Vector2(32, 0),
                            srcSize: Stage.cellSize),
                    ],
                  ],
                  stepTime: Swordsman.attackStepTime,
                ),
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(-38, 124),
                anchor: Anchor.topCenter,
                scale: Vector2.all(1.2),
              ),
              TextComponent(
                text: game.localization.caution,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 20),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.enemyTutorial1,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 +
                    Vector2(0, 20),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.enemyTutorial2,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 +
                    Vector2(0, 60),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              if (Config().mergeDamageFromBeginning)
                TextComponent(
                  text: game.localization.enemyTutorial3,
                  position: Vector2(
                              BoxPusherGame.baseSize.x,
                              640.0 -
                                  GameSeq.topPaddingSize.y -
                                  GameSeq.menuButtonAreaSize.y) *
                          0.5 +
                      Vector2(0, 120),
                  anchor: Anchor.center,
                  textRenderer: TextPaint(
                    style: const TextStyle(
                      fontFamily: Config.gameTextFamily,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              if (Config().mergeDamageFromBeginning)
                TextComponent(
                  text: game.localization.enemyTutorial4,
                  position: Vector2(
                              BoxPusherGame.baseSize.x,
                              640.0 -
                                  GameSeq.topPaddingSize.y -
                                  GameSeq.menuButtonAreaSize.y) *
                          0.5 +
                      Vector2(0, 160),
                  anchor: Anchor.center,
                  textRenderer: TextPaint(
                    style: const TextStyle(
                      fontFamily: Config.gameTextFamily,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              tapOrSpaceToNextComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 550),
                game,
              ),
            ],
          );
          break;
        case TutorialState.other:
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () async {
                  current = null;
                  Config().showTutorial = false;
                  await game.saveUserConfigData();
                },
                size: BoxPusherGame.baseSize,
                button: CustomPainterComponent(
                    size: BoxPusherGame.baseSize,
                    painter: TutorialMultiRRectHolePainter(
                      ltToWh: {
                        Vector2(10, 5): Vector2(110, 40),
                        Vector2(135, 5): Vector2(90, 40),
                        Vector2(290, 5): Vector2(60, 40),
                        Vector2(300, 600): Vector2(40, 40),
                      },
                      radius: 8,
                    )),
              ),
              TextComponent(
                text: game.localization.otherTutorial1,
                position: Vector2(5, 55),
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.otherTutorial2,
                position: Vector2(5, 70),
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.otherTutorial3,
                position: Vector2(5, 85),
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.otherTutorial4,
                position: Vector2(BoxPusherGame.baseSize.x * 0.5, 55),
                anchor: Anchor.topCenter,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.otherTutorial5,
                position: Vector2(BoxPusherGame.baseSize.x - 5, 55),
                anchor: Anchor.topRight,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.otherTutorial7,
                position: Vector2(290, 580),
                anchor: Anchor.topRight,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              SpriteComponent.fromImage(
                pinchInOutImg,
                size: Vector2(32, 45),
                position: Vector2(BoxPusherGame.baseSize.x * 0.5 - 45, 290),
              ),
              SpriteComponent.fromImage(
                mouseWheelImg,
                size: Vector2(32, 45),
                position: Vector2(BoxPusherGame.baseSize.x * 0.5 + 13, 290),
              ),
              TextComponent(
                text: game.localization.otherTutorial6,
                position: Vector2(BoxPusherGame.baseSize.x * 0.5, 350),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              tapOrSpaceToReturnComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 530),
                game,
              ),
            ],
          );
          break;
        case TutorialState.handAbility:
          tutorialArea.add(
            gotAbilityScreen(
                game: game,
                ability: PlayerAbility.hand,
                animalImg: gorillaImg,
                descriptions: [
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 340),
                    anchor: Anchor.center,
                    text: loc.handAbilityTutorial1,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 18),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 370),
                    anchor: Anchor.center,
                    text: loc.handAbilityTutorial2,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 18),
                    ),
                  ),
                ]),
          );
          break;
        case TutorialState.legAbility:
          tutorialArea.add(
            gotAbilityScreen(
                game: game,
                ability: PlayerAbility.leg,
                animalImg: rabbitImg,
                descriptions: [
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 340),
                    anchor: Anchor.center,
                    text: loc.legAbilityTutorial1,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 370),
                    anchor: Anchor.center,
                    text: loc.legAbilityTutorial2,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                  if (kIsWeb)
                    PositionComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 410),
                      size: Vector2(234, 34),
                      anchor: Anchor.center,
                      children: [
                        SpriteAnimationComponent.fromFrameData(
                          shiftKeyImg,
                          SpriteAnimationData.sequenced(
                              amount: 2,
                              stepTime: Stage.objectStepTime,
                              textureSize: Vector2(34, 17)),
                          size: Vector2(68, 34),
                        ),
                        TextComponent(
                          text: '+',
                          position: Vector2(74, 0),
                          textRenderer: TextPaint(
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Config.gameTextFamily,
                                fontSize: 20),
                          ),
                        ),
                        SpriteAnimationComponent.fromFrameData(
                          upKeyImg,
                          position: Vector2(92, 0),
                          SpriteAnimationData.sequenced(
                              amount: 2,
                              stepTime: Stage.objectStepTime,
                              textureSize: Vector2(21, 20)),
                          size: Vector2(34, 34),
                        ),
                        SpriteAnimationComponent.fromFrameData(
                          downKeyImg,
                          position: Vector2(128, 0),
                          SpriteAnimationData.sequenced(
                              amount: 2,
                              stepTime: Stage.objectStepTime,
                              textureSize: Vector2(21, 20)),
                          size: Vector2(34, 34),
                        ),
                        SpriteAnimationComponent.fromFrameData(
                          leftKeyImg,
                          position: Vector2(164, 0),
                          SpriteAnimationData.sequenced(
                              amount: 2,
                              stepTime: Stage.objectStepTime,
                              textureSize: Vector2(21, 20)),
                          size: Vector2(34, 34),
                        ),
                        SpriteAnimationComponent.fromFrameData(
                          rightKeyImg,
                          position: Vector2(200, 0),
                          SpriteAnimationData.sequenced(
                              amount: 2,
                              stepTime: Stage.objectStepTime,
                              textureSize: Vector2(21, 20)),
                          size: Vector2(34, 34),
                        ),
                      ],
                    ),
                ]),
          );
          break;
        case TutorialState.pocketAbility:
          if (game.lang == Language.japanese) {
            tutorialArea.add(
              gotAbilityScreen(
                  game: game,
                  ability: PlayerAbility.pocket,
                  animalImg: kangarooImg,
                  descriptions: [
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 330),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial1,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 360),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial2,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 390),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial3,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    PositionComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 440),
                      size: Vector2(300, 60),
                      anchor: Anchor.center,
                      children: [
                        if (kIsWeb)
                          SpriteAnimationComponent.fromFrameData(
                            pKeyImg,
                            SpriteAnimationData.sequenced(
                                amount: 2,
                                stepTime: Stage.objectStepTime,
                                textureSize: Vector2(21, 20)),
                            size: Vector2(34, 34),
                          ),
                        TextComponent(
                          text: kIsWeb
                              ? loc.pocketAbilityTutorial4
                              : loc.pocketAbilityTutorial4_2,
                          position: kIsWeb ? Vector2(40, 5) : Vector2(50, 5),
                          textRenderer: TextPaint(
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Config.gameTextFamily,
                                fontSize: 15),
                          ),
                        ),
                        TextComponent(
                          text: loc.pocketAbilityTutorial5,
                          position: Vector2(90, 35),
                          textRenderer: TextPaint(
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Config.gameTextFamily,
                                fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ]),
            );
          } else if (game.lang == Language.english) {
            tutorialArea.add(
              gotAbilityScreen(
                  game: game,
                  ability: PlayerAbility.pocket,
                  animalImg: kangarooImg,
                  descriptions: [
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 330),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial1,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 360),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial2,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    TextComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 390),
                      anchor: Anchor.center,
                      text: loc.pocketAbilityTutorial3,
                      textRenderer: TextPaint(
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: Config.gameTextFamily,
                            fontSize: 15),
                      ),
                    ),
                    PositionComponent(
                      position: Vector2(BoxPusherGame.baseSize.x * 0.5, 440),
                      size: Vector2(300, 60),
                      anchor: Anchor.center,
                      children: [
                        if (kIsWeb)
                          SpriteAnimationComponent.fromFrameData(
                            pKeyImg,
                            SpriteAnimationData.sequenced(
                                amount: 2,
                                stepTime: Stage.objectStepTime,
                                textureSize: Vector2(21, 20)),
                            position: Vector2(210, 0),
                            size: Vector2(34, 34),
                          ),
                        TextComponent(
                          text: loc.pocketAbilityTutorial4,
                          position: kIsWeb ? Vector2(28, 5) : Vector2(60, 5),
                          textRenderer: TextPaint(
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Config.gameTextFamily,
                                fontSize: 15),
                          ),
                        ),
                        if (kIsWeb)
                          TextComponent(
                            text: "or",
                            position: Vector2(250, 5),
                            textRenderer: TextPaint(
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: Config.gameTextFamily,
                                  fontSize: 15),
                            ),
                          ),
                        TextComponent(
                          text: loc.pocketAbilityTutorial5,
                          position: Vector2(150, 45),
                          anchor: Anchor.center,
                          textRenderer: TextPaint(
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: Config.gameTextFamily,
                                fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ]),
            );
          }
          break;
        case TutorialState.armerAbility:
          tutorialArea.add(
            gotAbilityScreen(
                game: game,
                ability: PlayerAbility.armer,
                animalImg: turtleImg,
                descriptions: [
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 340),
                    anchor: Anchor.center,
                    text: loc.armerAbilityTutorial1,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 15),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 370),
                    anchor: Anchor.center,
                    text: loc.armerAbilityTutorial2,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 15),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 400),
                    anchor: Anchor.center,
                    text: loc.armerAbilityTutorial3,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 15),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 430),
                    anchor: Anchor.center,
                    text: loc.armerAbilityTutorial4,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 15),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 460),
                    anchor: Anchor.center,
                    text: loc.armerAbilityTutorial5,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 12),
                    ),
                  ),
                ]),
          );
          break;
        case TutorialState.eyeAbility:
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = null;
                },
                size: BoxPusherGame.baseSize,
                button: RectangleComponent(
                    size: BoxPusherGame.baseSize,
                    paint: Paint()..color = const Color(0x80000000)),
              ),
              tapOrSpaceToReturnComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 530),
                game,
              ),
            ],
          );
          break;
        case TutorialState.mergeAbility:
          tutorialArea.add(
            gotAbilityScreen(
                game: game,
                ability: PlayerAbility.merge,
                animalImg: girlImg,
                imgTextureSize: Girl.girlImgSize,
                descriptions: [
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 340),
                    anchor: Anchor.center,
                    text: loc.mergeAbilityTutorial1,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 370),
                    anchor: Anchor.center,
                    text: loc.mergeAbilityTutorial2,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 400),
                    anchor: Anchor.center,
                    text: Config().mergeDamageFromBeginning
                        ? loc.mergeAbilityTutorial3_2
                        : loc.mergeAbilityTutorial3,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                  TextComponent(
                    position: Vector2(BoxPusherGame.baseSize.x * 0.5, 430),
                    anchor: Anchor.center,
                    text: Config().mergeDamageFromBeginning
                        ? loc.mergeAbilityTutorial4_2
                        : loc.mergeAbilityTutorial4,
                    textRenderer: TextPaint(
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: Config.gameTextFamily,
                          fontSize: 20),
                    ),
                  ),
                ]),
          );
          break;
        case TutorialState.openTreasureBox:
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = null;
                },
                size: BoxPusherGame.baseSize,
                button: RectangleComponent(
                    size: BoxPusherGame.baseSize,
                    paint: Paint()..color = const Color(0x80000000)),
              ),
              CircleComponent(
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.4),
                radius: 20,
                paint: Paint()..color = const Color(0xc0ffffff),
              ),
              SpriteAnimationComponent.fromFrameData(
                treasureBoxImg,
                SpriteAnimationData.sequenced(
                    amount: 2,
                    stepTime: Stage.objectStepTime,
                    textureSize: Stage.cellSize),
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 90),
                anchor: Anchor.center,
                scale: Vector2.all(1.2),
              ),
              TextComponent(
                text: game.localization.treasureBoxTutorial1,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 -
                    Vector2(0, 40),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.treasureBoxTutorial2,
                position: Vector2(
                        BoxPusherGame.baseSize.x,
                        640.0 -
                            GameSeq.topPaddingSize.y -
                            GameSeq.menuButtonAreaSize.y) *
                    0.5,
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.treasureBoxTutorial3,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 +
                    Vector2(0, 50),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.treasureBoxTutorial4,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 +
                    Vector2(0, 90),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              TextComponent(
                text: game.localization.treasureBoxTutorial5,
                position: Vector2(
                            BoxPusherGame.baseSize.x,
                            640.0 -
                                GameSeq.topPaddingSize.y -
                                GameSeq.menuButtonAreaSize.y) *
                        0.5 +
                    Vector2(0, 130),
                anchor: Anchor.center,
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: Config.gameTextFamily,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              tapOrSpaceToReturnComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 550),
                game,
              ),
            ],
          );
          break;
        default:
          break;
      }
      if (_prev == TutorialState.move) {
        current = TutorialState.push;
        _prev = current;
        _countForTutorial = 0.0;
        return false;
      }
    }
    _prev = current;
    switch (current) {
      case TutorialState.push:
        double prevMovingAmount = _countForTutorial * Stage.playerSpeed;
        _countForTutorial += dt;
        double movingAmount = _countForTutorial * Stage.playerSpeed;
        if (movingAmount < Stage.cellSize.x / 2) {
          return false;
        } else
        // 初めてマスの半分移動したら
        if (prevMovingAmount < Stage.cellSize.x) {
          _firstMoving = playerMoving;
          tutorialArea.removeAll(tutorialArea.children);
          final holePosition = Vector2(
                  BoxPusherGame.baseSize.x * 0.5 - 30,
                  (640.0 -
                              GameSeq.topPaddingSize.y -
                              GameSeq.menuButtonAreaSize.y) *
                          0.5 +
                      15) +
              Vector2(15 * _firstMoving.vector.x, 15 * _firstMoving.vector.y);
          final imgPosition = Vector2(
              BoxPusherGame.baseSize.x * 0.5,
              (640.0 -
                          GameSeq.topPaddingSize.y -
                          GameSeq.menuButtonAreaSize.y) *
                      0.5 +
                  -30);
          tutorialArea.addAll(
            [
              ButtonComponent(
                size: BoxPusherGame.baseSize,
                button: CustomPainterComponent(
                    size: BoxPusherGame.baseSize,
                    painter: TutorialRRectHolePainter(
                      lt: holePosition,
                      w: 60,
                      h: 60,
                      radius: 8,
                    )),
              ),
              SpriteComponent.fromImage(
                tutorial2Img,
                size: Vector2(150, 70),
                position: imgPosition,
                anchor: Anchor.center,
              ),
            ],
          );
        } else if (_countForTutorial > 2.0) {
          current = TutorialState.merge;
          _countForTutorial = 0.0;
          return false;
        }
        return true;
      case TutorialState.merge:
        double prevMovingAmount = _countForTutorial * Stage.playerSpeed;
        _countForTutorial += dt;
        double movingAmount = _countForTutorial * Stage.playerSpeed;
        if (movingAmount < Stage.cellSize.x * 0.5) {
          return false;
        } else
        // 初めてマス半分移動したら
        if (prevMovingAmount < Stage.cellSize.x * 0.5) {
          tutorialArea.removeAll(tutorialArea.children);
          final holePosition = Vector2(
                  BoxPusherGame.baseSize.x * 0.5 - 50,
                  (640.0 -
                              GameSeq.topPaddingSize.y -
                              GameSeq.menuButtonAreaSize.y) *
                          0.5 -
                      12) +
              Vector2(30 * _firstMoving.vector.x, 30 * _firstMoving.vector.y);
          final imgPosition = Vector2(
              BoxPusherGame.baseSize.x * 0.5,
              (640.0 -
                          GameSeq.topPaddingSize.y -
                          GameSeq.menuButtonAreaSize.y) *
                      0.5 -
                  100);
          tutorialArea.addAll(
            [
              ButtonComponent(
                onReleased: () {
                  current = TutorialState.animals;
                  _countForTutorial = 0;
                },
                size: BoxPusherGame.baseSize,
                button: CustomPainterComponent(
                    size: BoxPusherGame.baseSize,
                    painter: TutorialRRectHolePainter(
                      lt: holePosition,
                      w: 100,
                      h: 100,
                      radius: 8,
                    )),
              ),
              SpriteComponent.fromImage(
                tutorial3Img,
                size: Vector2(180, 76),
                position: imgPosition,
                anchor: Anchor.center,
              ),
              tapOrSpaceToNextComponent(
                Vector2(BoxPusherGame.baseSize.x * 0.5, 550),
                game,
              ),
            ],
          );
          isMergeVisible = true;
        }
        return true;
      case TutorialState.animals:
      case TutorialState.girl:
      case TutorialState.enemy:
      case TutorialState.other:
      case TutorialState.handAbility:
      case TutorialState.legAbility:
      case TutorialState.pocketAbility:
      case TutorialState.armerAbility:
      case TutorialState.mergeAbility:
      case TutorialState.eyeAbility:
      case TutorialState.openTreasureBox:
        return true;
      default:
        break;
    }
    return false;
  }

  /// 「次へ進む」に対応するキー(=spaceキー)を押したときの処理を行う
  /// 処理を行った場合はtrueを返す(ゲーム本編の操作は禁止する)
  bool onNextKey() {
    switch (current) {
      case TutorialState.move:
      case TutorialState.push:
        return true;
      case TutorialState.merge:
        if (isMergeVisible) {
          current = TutorialState.animals;
          _countForTutorial = 0;
          return true;
        }
        break;
      case TutorialState.animals:
        current = TutorialState.girl;
        return true;
      case TutorialState.girl:
        current = TutorialState.enemy;
        return true;
      case TutorialState.enemy:
        current = TutorialState.other;
        return true;
      case TutorialState.other:
      case TutorialState.handAbility:
      case TutorialState.legAbility:
      case TutorialState.pocketAbility:
      case TutorialState.armerAbility:
      case TutorialState.eyeAbility:
      case TutorialState.mergeAbility:
      case TutorialState.openTreasureBox:
        current = null;
        return true;
      default:
        break;
    }
    return false;
  }

  /// 操作ボタン変更時、操作ボタンに合わせて移動チュートリアル変更
  void updateMoveTutorial() {
    if (current == TutorialState.move) {
      tutorialArea.removeAll(tutorialArea.children);
      CustomPainter? painter;
      // キーボード表示はwebのみ
      List<Component> components = [
        if (kIsWeb)
          SpriteAnimationComponent(
              animation: tutorial1KeyboardAnimation,
              position: Vector2(180, 345),
              anchor: Anchor.topCenter)
      ];
      switch (Config().playerControllButtonType) {
        case PlayerControllButtonType.joyStick:
          painter = TutorialCircleHolePainter(
            radius: GameSeq.joyStickFieldRadius * 1.2,
            center:
                Vector2(0, GameSeq.topPaddingSize.y) + GameSeq.joyStickPosition,
          );
          components.addAll([
            if (kIsWeb)
              SpriteComponent(
                  sprite: tutorial1OrAndArrowSprite,
                  position: Vector2(180, 395),
                  anchor: Anchor.topCenter),
            CircleComponent(
              radius: GameSeq.joyStickRadius,
              anchor: Anchor.center,
              position: Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.joyStickPosition,
              paint: Paint()..color = const Color(0x80ffffff),
              children: [
                SequenceEffect(
                  [
                    for (final move in MoveExtent.straights) ...[
                      OpacityEffect.fadeIn(
                        EffectController(duration: 0.5),
                      ),
                      MoveEffect.by(
                        move.vector * GameSeq.joyStickFieldRadius,
                        EffectController(
                          duration: 1.0,
                          curve: Curves.decelerate,
                        ),
                      ),
                      OpacityEffect.fadeOut(
                        EffectController(duration: 0.5),
                      ),
                      MoveEffect.to(
                        Vector2(0, GameSeq.topPaddingSize.y) +
                            GameSeq.joyStickPosition,
                        EffectController(
                          duration: 0.1,
                        ),
                      ),
                    ]
                  ],
                  infinite: true,
                ),
              ],
            ),
            SpriteComponent.fromImage(
              longTapImg,
              size: Vector2(35, 50),
              position: Vector2(-15, GameSeq.topPaddingSize.y - 10) +
                  GameSeq.joyStickPosition,
              children: [
                SequenceEffect(
                  [
                    for (final move in MoveExtent.straights) ...[
                      OpacityEffect.fadeIn(
                        EffectController(duration: 0.5),
                      ),
                      MoveEffect.by(
                        move.vector * GameSeq.joyStickFieldRadius,
                        EffectController(
                          duration: 1.0,
                          curve: Curves.decelerate,
                        ),
                      ),
                      OpacityEffect.fadeOut(
                        EffectController(duration: 0.5),
                      ),
                      MoveEffect.to(
                        Vector2(-15, GameSeq.topPaddingSize.y - 10) +
                            GameSeq.joyStickPosition,
                        EffectController(
                          duration: 0.1,
                        ),
                      ),
                    ]
                  ],
                  infinite: true,
                ),
              ],
            ),
            SpriteComponent(
                sprite: tutorial1ToMoveSprite,
                position: Vector2(180, 570),
                anchor: Anchor.topCenter),
          ]);
          break;
        case PlayerControllButtonType.onScreenBottom:
        case PlayerControllButtonType.onScreenBottom2:
          painter = TutorialRRectHolePainter(
            lt: Vector2(0, GameSeq.topPaddingSize.y) +
                GameSeq.moveButtonPosMap[
                    PlayerControllButtonType.onScreenBottom]![Move.upLeft]! -
                Vector2.all(10),
            w: GameSeq
                        .moveButtonSizeMap[PlayerControllButtonType
                            .onScreenBottom]![Move.upLeft]!
                        .x *
                    3 +
                20,
            h: GameSeq
                        .moveButtonSizeMap[PlayerControllButtonType
                            .onScreenBottom]![Move.upLeft]!
                        .y *
                    3 +
                20,
            radius: 3,
          );
          components.addAll([
            if (kIsWeb)
              SpriteComponent(
                  sprite: tutorial1OrSprite,
                  position: Vector2(180, 405),
                  anchor: Anchor.topCenter),
            SpriteComponent(
                sprite: tutorial1TapToMoveSprite,
                position: Vector2(180, 600),
                anchor: Anchor.topCenter),
          ]);
          break;
        case PlayerControllButtonType.onScreenEdge:
          painter = TutorialMultiRRectHolePainter(
            ltToWh: {
              Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.moveButtonPosMap[PlayerControllButtonType
                      .onScreenEdge]![Move.up]!: GameSeq.moveButtonSizeMap[
                  PlayerControllButtonType.onScreenEdge]![Move.up]!,
              Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.moveButtonPosMap[PlayerControllButtonType
                      .onScreenEdge]![Move.left]!: GameSeq.moveButtonSizeMap[
                  PlayerControllButtonType.onScreenEdge]![Move.left]!,
              Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.moveButtonPosMap[PlayerControllButtonType
                      .onScreenEdge]![Move.right]!: GameSeq.moveButtonSizeMap[
                  PlayerControllButtonType.onScreenEdge]![Move.right]!,
              Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.moveButtonPosMap[PlayerControllButtonType
                      .onScreenEdge]![Move.down]!: GameSeq.moveButtonSizeMap[
                  PlayerControllButtonType.onScreenEdge]![Move.down]!,
            },
            radius: 3,
          );
          components.addAll([
            if (kIsWeb)
              SpriteComponent(
                  sprite: tutorial1OrSprite,
                  position: Vector2(180, 405),
                  anchor: Anchor.topCenter),
            SpriteComponent(
                sprite: tutorial1TapToMoveSprite,
                position: Vector2(180, 440),
                anchor: Anchor.topCenter),
            SpriteComponent.fromImage(
              longTapImg,
              size: Vector2(35, 50),
              position: Vector2(0, GameSeq.topPaddingSize.y) +
                  GameSeq.moveButtonPosMap[
                      PlayerControllButtonType.onScreenEdge]![Move.up]! +
                  GameSeq.moveButtonSizeMap[
                          PlayerControllButtonType.onScreenEdge]![Move.up]! /
                      2,
              anchor: Anchor.topCenter,
              children: [
                SequenceEffect(
                  [
                    for (final move in MoveExtent.straights) ...[
                      MoveToEffect(
                          Vector2(0, GameSeq.topPaddingSize.y) +
                              GameSeq.moveButtonPosMap[PlayerControllButtonType
                                  .onScreenEdge]![move]! +
                              GameSeq.moveButtonSizeMap[PlayerControllButtonType
                                      .onScreenEdge]![move]! /
                                  2,
                          EffectController(duration: 0)),
                      OpacityEffect.fadeIn(
                        EffectController(duration: 0.5, startDelay: 0.5),
                      ),
                      OpacityEffect.fadeOut(
                        EffectController(duration: 0.5, startDelay: 0.5),
                      ),
                    ],
                  ],
                  infinite: true,
                ),
              ],
            ),
          ]);
          break;
        case PlayerControllButtonType.noButton:
          painter = TutorialRRectHolePainter(
              lt: Vector2.zero(), w: 0, h: 0, radius: 0);
          components.addAll([
            SpriteComponent(
                sprite: tutorial1ToMoveSprite,
                position: Vector2(180, 405),
                anchor: Anchor.topCenter),
          ]);
          break;
      }
      tutorialArea.addAll(
        [
          CustomPainterComponent(
              size: BoxPusherGame.baseSize, painter: painter),
          ...components,
        ],
      );
    }
  }
}

class TutorialCircleHolePainter extends CustomPainter {
  final Vector2 center;
  final double radius;

  TutorialCircleHolePainter({
    required this.radius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x80000000);

    double x = center.x - radius;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, center.y)
      ..lineTo(x, center.y)
      ..arcTo(Rect.fromCircle(center: center.toOffset(), radius: radius), pi,
          pi * 0.5, false)
      ..arcTo(Rect.fromCircle(center: center.toOffset(), radius: radius),
          pi * 1.5, pi * 0.5, false)
      ..arcTo(Rect.fromCircle(center: center.toOffset(), radius: radius), 0,
          pi * 0.5, false)
      ..arcTo(Rect.fromCircle(center: center.toOffset(), radius: radius),
          pi * 0.5, pi * 0.5, false)
      ..lineTo(x, center.y)
      ..lineTo(0, center.y)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TutorialRRectHolePainter extends CustomPainter {
  final Vector2 lt;
  final double w;
  final double h;
  final double radius;

  TutorialRRectHolePainter({
    required this.lt,
    required this.w,
    required this.h,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x80000000);
    double diameter = radius * 2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, lt.y + radius)
      ..arcTo(
          Rect.fromLTWH(lt.x, lt.y, diameter, diameter), pi, pi * 0.5, false)
      ..arcTo(Rect.fromLTWH(lt.x + w - diameter, lt.y, diameter, diameter),
          pi * 1.5, pi * 0.5, false)
      ..arcTo(
          Rect.fromLTWH(
              lt.x + w - diameter, lt.y + h - diameter, diameter, diameter),
          0,
          pi * 0.5,
          false)
      ..arcTo(Rect.fromLTWH(lt.x, lt.y + h - diameter, diameter, diameter),
          pi * 0.5, pi * 0.5, false)
      ..lineTo(lt.x, lt.y + radius)
      ..lineTo(0, lt.y + radius)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TutorialMultiRRectHolePainter extends CustomPainter {
  /// 左上座標->幅・高さ それぞれの四角形はy座標上で重ならないとする
  final Map<Vector2, Vector2> ltToWh;
  final double radius;

  TutorialMultiRRectHolePainter({
    required this.ltToWh,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x80000000);
    double diameter = radius * 2;

    final path = Path()..moveTo(0, 0);

    for (final e in ltToWh.entries) {
      final lt = e.key;
      double w = e.value.x;
      double h = e.value.y;

      path
        ..lineTo(0, lt.y + radius)
        ..arcTo(
            Rect.fromLTWH(lt.x, lt.y, diameter, diameter), pi, pi * 0.5, false)
        ..arcTo(Rect.fromLTWH(lt.x + w - diameter, lt.y, diameter, diameter),
            pi * 1.5, pi * 0.5, false)
        ..arcTo(
            Rect.fromLTWH(
                lt.x + w - diameter, lt.y + h - diameter, diameter, diameter),
            0,
            pi * 0.5,
            false)
        ..arcTo(Rect.fromLTWH(lt.x, lt.y + h - diameter, diameter, diameter),
            pi * 0.5, pi * 0.5, false)
        ..lineTo(lt.x, lt.y + radius)
        ..lineTo(0, lt.y + radius);
    }
    path
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
