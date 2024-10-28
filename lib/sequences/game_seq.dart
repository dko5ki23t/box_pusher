import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flame/palette.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart' hide Image;

class GameSeq extends Sequence
    with TapCallbacks, HasGameReference<BoxPusherGame> {
  /// 画面上部の余白
  static Vector2 get topPaddingSize => Vector2(360.0, 40.0);

  /// 画面上下の余白(上部はtopPaddingSizeに追加)
  static Vector2 get yPaddingSize => Vector2(360.0, 20.0);

  /// 画面左右の余白
  static Vector2 get xPaddingSize => Vector2(20.0, 640.0);

  /// 画面上下の操作ボタン領域(yPadding領域と重複。この領域下にはステージ描画もされる)
  static Vector2 get yButtonAreaSize => Vector2(360.0, 50.0);

  /// 画面上下の操作ボタン領域(xPadding領域と重複。この領域下にはステージ描画もされる。y方向サイズはあとで計算する)
  static Vector2 get xButtonAreaSize => Vector2(50.0, 560.0);

  /// 画面斜めの操作ボタン領域(xPadding領域と重複。この領域下にはステージ描画もされる。)
  static Vector2 get dButtonAreaSize => Vector2(300.0, 120.0);

  /// メニューボタン領域(各種能力ボタン、ステージ名、メニューボタンの領域含む)
  static Vector2 get menuButtonAreaSize => Vector2(360.0, 40.0);

  /// 手の能力ボタン領域
  static Vector2 get handAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// 足の能力ボタン領域
  static Vector2 get legAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// コインのアイコン領域
  static Vector2 get coinIconAreaSize => Vector2(40.0, 40.0);

  /// コイン数領域
  static Vector2 get coinNumAreaSize => Vector2(40.0, 40.0);

  /// 能力ボタン間の余白
  static double get paddingAbilityButtons => 10.0;

  /// メニューボタン領域
  static Vector2 get settingsButtonAreaSize => Vector2(40.0, 40.0);

  /// 【テストモード】現在位置表示領域
  static Vector2 get currentPosAreaSize => Vector2(40.0, 40.0);

  /// ステージ領域
  static Vector2 get stageViewSize => Vector2(360.0 - xPaddingSize.x * 2,
      640.0 - menuButtonAreaSize.y - topPaddingSize.y - yPaddingSize.y * 2);

  /// ステージオブジェクト
  late Stage stage;

  /// 現在押されている移動ボタンの移動方向
  Move pushingMoveButton = Move.none;

  late final Image stageImg;
  late final Image jewelImg;
  late final Image playerImg;
  late final Image spikeImg;
  late final Image blockImg;
  late final Image bombImg;
  late final Image beltImg;
  late final Image guardianImg;
  late final Image guardianAttackDImg;
  late final Image guardianAttackUImg;
  late final Image guardianAttackLImg;
  late final Image guardianAttackRImg;
  late final Image swordsmanImg;
  late final Image swordsmanAttackDImg;
  late final Image swordsmanAttackUImg;
  late final Image swordsmanAttackLImg;
  late final Image swordsmanAttackRImg;
  late final Image swordsmanRoundAttackDImg;
  late final Image swordsmanRoundAttackUImg;
  late final Image swordsmanRoundAttackLImg;
  late final Image swordsmanRoundAttackRImg;
  late final Image archerImg;
  late final Image archerAttackImg;
  late final Image arrowImg;
  late final Image wizardImg;
  late final Image wizardAttackImg;
  late final Image magicImg;
  late final Image coinImg;
  late final Image playerControllArrowImg;
  late final Image handAbilityImg;
  late final Image legAbilityImg;
  late final Image settingsImg;
  late TextComponent currentPosText;
  late TextComponent scoreText;
  late TextComponent coinNumText;
  ClipComponent? playerControllButtonsArea;
  ClipComponent? clipByDiagonalMoveButton;
  List<ButtonComponent>? playerStraightMoveButtons;
  List<ClipComponent>? playerDiagonalMoveButtons;

  @override
  Future<void> onLoad() async {
    stageImg = await Flame.images.load('stage_alpha.png');
    jewelImg = await Flame.images.load('jewels.png');
    playerImg = await Flame.images.load('player.png');
    spikeImg = await Flame.images.load('spike.png');
    blockImg = await Flame.images.load('block.png');
    bombImg = await Flame.images.load('bomb.png');
    beltImg = await Flame.images.load('belt.png');
    guardianImg = await Flame.images.load('guardian.png');
    guardianAttackDImg = await Flame.images.load('guardian_attackD.png');
    guardianAttackUImg = await Flame.images.load('guardian_attackU.png');
    guardianAttackLImg = await Flame.images.load('guardian_attackL.png');
    guardianAttackRImg = await Flame.images.load('guardian_attackR.png');
    swordsmanImg = await Flame.images.load('swordsman.png');
    swordsmanAttackDImg = await Flame.images.load('swordsman_attackD.png');
    swordsmanAttackUImg = await Flame.images.load('swordsman_attackU.png');
    swordsmanAttackLImg = await Flame.images.load('swordsman_attackL.png');
    swordsmanAttackRImg = await Flame.images.load('swordsman_attackR.png');
    swordsmanRoundAttackDImg =
        await Flame.images.load('swordsman_attack_roundD.png');
    swordsmanRoundAttackUImg =
        await Flame.images.load('swordsman_attack_roundU.png');
    swordsmanRoundAttackLImg =
        await Flame.images.load('swordsman_attack_roundL.png');
    swordsmanRoundAttackRImg =
        await Flame.images.load('swordsman_attack_roundR.png');
    archerImg = await Flame.images.load('archer.png');
    archerAttackImg = await Flame.images.load('archer_attack.png');
    arrowImg = await Flame.images.load('arrow.png');
    wizardImg = await Flame.images.load('wizard.png');
    wizardAttackImg = await Flame.images.load('wizard_attack.png');
    magicImg = await Flame.images.load('magic.png');
    coinImg = await Flame.images.load('coin.png');
    playerControllArrowImg =
        await Flame.images.load('player_controll_arrow.png');
    handAbilityImg = await Flame.images.load('hand_ability.png');
    legAbilityImg = await Flame.images.load('leg_ability.png');
    settingsImg = await Flame.images.load('settings.png');
    // BGM再生
    FlameAudio.bgm.play('maou_bgm_8bit29.mp3');
    initialize();
  }

  @override
  void onFocus(String? before) {
    if (before == 'menu') {
      // BGM再開
      FlameAudio.bgm.resume();
    } else {
      // BGM再生
      FlameAudio.bgm.play('maou_bgm_8bit29.mp3');
    }
  }

  @override
  void onUnFocus() {
    // BGM中断
    FlameAudio.bgm.pause();
  }

  @override
  void onRemove() {
    // BGM停止
    FlameAudio.bgm.stop();
  }

  // 初期化（というよりリセット）
  void initialize() {
    removeAll(children);
    game.world.removeAll(game.world.children);

    stage = Stage(
      stageImg: stageImg,
      jewelImg: jewelImg,
      playerImg: playerImg,
      spikeImg: spikeImg,
      blockImg: blockImg,
      bombImg: bombImg,
      beltImg: beltImg,
      guardianImg: guardianImg,
      guardianAttackDImg: guardianAttackDImg,
      guardianAttackUImg: guardianAttackUImg,
      guardianAttackLImg: guardianAttackLImg,
      guardianAttackRImg: guardianAttackRImg,
      swordsmanImg: swordsmanImg,
      swordsmanAttackDImg: swordsmanAttackDImg,
      swordsmanAttackUImg: swordsmanAttackUImg,
      swordsmanAttackLImg: swordsmanAttackLImg,
      swordsmanAttackRImg: swordsmanAttackRImg,
      swordsmanRoundAttackDImg: swordsmanRoundAttackDImg,
      swordsmanRoundAttackUImg: swordsmanRoundAttackUImg,
      swordsmanRoundAttackLImg: swordsmanRoundAttackLImg,
      swordsmanRoundAttackRImg: swordsmanRoundAttackRImg,
      archerImg: archerImg,
      archerAttackImg: archerAttackImg,
      arrowImg: arrowImg,
      wizardImg: wizardImg,
      wizardAttackImg: wizardAttackImg,
      magicImg: magicImg,
    );
    stage.initialize(game.world, game.camera, game.stageData);

    // プレイヤーの操作ボタン群
    final clipSize = Vector2(
        yButtonAreaSize.x, 640.0 - topPaddingSize.y - menuButtonAreaSize.y);
    final tv = Vector2(0.3, 0.3 * 9 / 16);
    playerControllButtonsArea ??=
        playerControllButtonsArea = ClipComponent.rectangle(
      position: Vector2(0, topPaddingSize.y),
      size: clipSize,
    );
    // 上下左右の移動ボタン
    playerStraightMoveButtons ??= [
      // 画面上の操作ボタン
      playerControllButton(
        size: yButtonAreaSize,
        position: Vector2(0, 0),
        arrowAngle: 0.0,
        move: Move.up,
      ),
      // 画面下の操作ボタン
      playerControllButton(
        size: yButtonAreaSize,
        position: Vector2(
            0,
            640.0 -
                topPaddingSize.y -
                menuButtonAreaSize.y -
                yButtonAreaSize.y),
        arrowAngle: pi,
        move: Move.down,
      ),
      // 画面左の操作ボタン
      playerControllButton(
        size: Vector2(
            xButtonAreaSize.x,
            640.0 -
                topPaddingSize.y -
                yButtonAreaSize.y * 2 -
                menuButtonAreaSize.y),
        position: Vector2(0, yButtonAreaSize.y),
        arrowAngle: -0.5 * pi,
        move: Move.left,
      ),
      // 画面右の操作ボタン
      playerControllButton(
        size: Vector2(
            xButtonAreaSize.x,
            640.0 -
                topPaddingSize.y -
                yButtonAreaSize.y * 2 -
                menuButtonAreaSize.y),
        position: Vector2(360.0 - xButtonAreaSize.x, yButtonAreaSize.y),
        arrowAngle: 0.5 * pi,
        move: Move.right,
      ),
    ];
    // 斜めの移動ボタン
    playerDiagonalMoveButtons ??= [
      // 画面左上の操作ボタン
      ClipComponent.polygon(
        points: [
          Vector2(0, 0),
          Vector2(tv.x, 0),
          Vector2(0, tv.y),
          Vector2(0, 0),
        ],
        size: clipSize,
        children: [
          playerControllButton(
            size: dButtonAreaSize,
            position: Vector2(xButtonAreaSize.x * 0.5, yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: -0.25 * pi,
            move: Move.upLeft,
          ),
        ],
      ),
      // 画面右上の操作ボタン
      ClipComponent.polygon(
        points: [
          Vector2(1, 0),
          Vector2(1 - tv.x, 0),
          Vector2(1, tv.y),
          Vector2(1, 0),
        ],
        size: clipSize,
        children: [
          playerControllButton(
            size: dButtonAreaSize,
            position: Vector2(
                clipSize.x - xButtonAreaSize.x * 0.5, yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: 0.25 * pi,
            move: Move.upRight,
          ),
        ],
      ),
      // 画面左下の操作ボタン
      ClipComponent.polygon(
        points: [
          Vector2(0, 1 - tv.y),
          Vector2(tv.x, 1),
          Vector2(0, 1),
          Vector2(0, 1 - tv.y),
        ],
        size: clipSize,
        children: [
          playerControllButton(
            size: dButtonAreaSize,
            position: Vector2(
                xButtonAreaSize.x * 0.5, clipSize.y - yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: -0.75 * pi,
            move: Move.downLeft,
          ),
        ],
      ),
      // 画面右下の操作ボタン
      ClipComponent.polygon(
        points: [
          Vector2(1, 1 - tv.y),
          Vector2(1, 1),
          Vector2(1 - tv.x, 1),
          Vector2(1, 1 - tv.y),
        ],
        size: clipSize,
        children: [
          playerControllButton(
            size: dButtonAreaSize,
            position: Vector2(clipSize.x - xButtonAreaSize.x * 0.5,
                clipSize.y - yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: 0.75 * pi,
            move: Move.downRight,
          ),
        ],
      ),
    ];
    // 上下左右の操作ボタン領域(斜めボタンの領域は削る)
    clipByDiagonalMoveButton ??= ClipComponent.polygon(
      points: [
        Vector2(tv.x, 0),
        Vector2(1 - tv.x, 0),
        Vector2(1, tv.y),
        Vector2(1, 1 - tv.y),
        Vector2(1 - tv.x, 1),
        Vector2(tv.x, 1),
        Vector2(0, 1 - tv.y),
        Vector2(0, tv.y),
        Vector2(tv.x, 0),
      ],
      size: clipSize,
    );

    // 斜め移動可能かどうかで操作ボタンの表示を変える
    playerControllButtonsArea!.removeAll(playerControllButtonsArea!.children);
    if (stage.getLegAbility()) {
      clipByDiagonalMoveButton!.addAll(playerStraightMoveButtons!);
      playerControllButtonsArea!.add(clipByDiagonalMoveButton!);
      playerControllButtonsArea!.addAll(playerDiagonalMoveButtons!);
    } else {
      playerControllButtonsArea!.addAll(playerStraightMoveButtons!);
    }

    add(playerControllButtonsArea!);
    // 画面上部、ボタンではない領域
    add(
      ButtonComponent(
        button: RectangleComponent(
            size: topPaddingSize,
            paint: Paint()
              ..color = const Color(0x80000000)
              ..style = PaintingStyle.fill),
      ),
    );
    // メニュー領域
    scoreText = TextComponent(
      text: "${stage.scoreVisual}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Aboreto',
          color: Color(0xff000000),
        ),
      ),
    );
    add(RectangleComponent(
      size: menuButtonAreaSize,
      position: Vector2(0, 640.0 - menuButtonAreaSize.y),
      paint: Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      children: [
        RectangleComponent(
          size: menuButtonAreaSize,
          paint: Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        ),
        AlignComponent(
          alignment: Anchor.center,
          child: scoreText,
        ),
      ],
    ));
    // 手の能力ボタン領域
    add(GameSpriteOnOffButton(
      isOn: stage.getHandAbility(),
      onChanged: (bool isOn) => stage.setHandAbility(isOn),
      size: handAbilityButtonAreaSize,
      position: Vector2(xPaddingSize.x, 640.0 - menuButtonAreaSize.y),
      sprite: Sprite(handAbilityImg),
    ));
    // 足の能力ボタン領域
    add(GameSpriteOnOffButton(
      isOn: stage.getLegAbility(),
      onChanged: (bool isOn) {
        stage.setLegAbility(isOn);
        playerControllButtonsArea!
            .removeAll(playerControllButtonsArea!.children);
        if (stage.getLegAbility()) {
          clipByDiagonalMoveButton!.addAll(playerStraightMoveButtons!);
          playerControllButtonsArea!.add(clipByDiagonalMoveButton!);
          playerControllButtonsArea!.addAll(playerDiagonalMoveButtons!);
        } else {
          playerControllButtonsArea!.addAll(playerStraightMoveButtons!);
        }
      },
      size: legAbilityButtonAreaSize,
      position: Vector2(
          xPaddingSize.x + handAbilityButtonAreaSize.x + paddingAbilityButtons,
          640.0 - menuButtonAreaSize.y),
      sprite: Sprite(legAbilityImg),
    ));
    // コインのアイコン領域
    add(RectangleComponent(
      size: coinIconAreaSize,
      position: Vector2(
          360.0 -
              xPaddingSize.x -
              settingsButtonAreaSize.x -
              paddingAbilityButtons * 2 -
              coinNumAreaSize.x -
              coinIconAreaSize.x,
          640.0 - menuButtonAreaSize.y),
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: SpriteComponent.fromImage(coinImg),
        ),
      ],
    ));
    // コイン数領域
    coinNumText = TextComponent(
      text: "${stage.coinNum}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Aboreto',
          color: Color(0xff000000),
        ),
      ),
    );
    add(RectangleComponent(
      size: coinNumAreaSize,
      position: Vector2(
          360.0 -
              xPaddingSize.x -
              settingsButtonAreaSize.x -
              paddingAbilityButtons -
              coinNumAreaSize.x,
          640.0 - menuButtonAreaSize.y),
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: coinNumText,
        ),
      ],
    ));
    // メニューボタン領域
    add(GameSpriteButton(
      size: settingsButtonAreaSize,
      position: Vector2(360.0 - xPaddingSize.x - settingsButtonAreaSize.x,
          640.0 - menuButtonAreaSize.y),
      sprite: Sprite(settingsImg),
      onReleased: () => game.pushSeqNamed("menu"),
    ));

    // 【テストモード時】現在座標表示領域
    currentPosText = TextComponent(
      size: currentPosAreaSize,
      position: Vector2(0, yPaddingSize.y),
      text: "pos:(${stage.player.pos.x},${stage.player.pos.y})",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Aboreto',
          color: Color(0xffffffff),
        ),
      ),
    );
    if (game.testMode) {
      add(currentPosText);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // クリア済みなら何もしない
    if (stage.isClear()) return;
    // ゲームオーバー済みなら何もしない
    if (stage.isGameover) return;
    stage.update(dt, pushingMoveButton, game.world, game.camera);
    // スコア表示更新
    scoreText.text = "${stage.scoreVisual}";
    // スコア加算表示
    int addedScore = stage.addedScore;
    if (addedScore > 0) {
      final addingScoreText = CaTextComponent(
        text: "+$addedScore",
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Aboreto',
            color: Color(0xff000000),
          ),
        ),
      );
      add(RectangleComponent(
        size: menuButtonAreaSize,
        position: Vector2(0, 640.0 - menuButtonAreaSize.y),
        paint: Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill,
        children: [
          RectangleComponent(
            size: menuButtonAreaSize,
            paint: Paint()
              ..color = Colors.transparent
              ..style = PaintingStyle.fill,
          ),
          AlignComponent(
            alignment: Anchor.center,
            child: addingScoreText,
          ),
          SequenceEffect([
            MoveEffect.by(
                Vector2(0, -10.0),
                EffectController(
                  duration: 0.3,
                )),
            OpacityEffect.fadeOut(EffectController(duration: 0.5),
                target: addingScoreText),
            RemoveEffect(),
          ]),
        ],
      ));
    }
    // コイン数表示更新
    coinNumText.text = "${stage.coinNum}";
    // 【テストモード】
    if (game.testMode) {
      currentPosText.text = "pos:(${stage.player.pos.x},${stage.player.pos.y})";
    }
    // 今回のupdateでクリアしたらクリア画面に移行
    if (stage.isClear()) {
      game.pushSeqNamed('clear');
    }
    // 今回のupdateでゲームオーバーになったらゲームオーバー画面に移行
    if (stage.isGameover) {
      // ハイスコア更新
      if (stage.score > game.highScore) {
        game.setAndSaveHighScore(stage.score);
      }
      game.pushSeqNamed('gameover');
    }
  }

  ButtonComponent playerControllButton({
    required Vector2 size,
    Vector2? position,
    Anchor? anchor,
    double? angle,
    double? arrowAngle,
    required Move move,
  }) {
    return ButtonComponent(
      onPressed: () {
        if (pushingMoveButton == Move.none) {
          pushingMoveButton = move;
        }
      },
      onReleased: () {
        if (pushingMoveButton == move) {
          pushingMoveButton = Move.none;
        }
      },
      onCancelled: () {
        if (pushingMoveButton == move) {
          pushingMoveButton = Move.none;
        }
      },
      size: size,
      anchor: anchor,
      angle: angle,
      position: position,
      button: RectangleComponent(
        size: size,
        paint: Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(playerControllArrowImg),
              size: Vector2(24.0, 24.0),
              anchor: Anchor.center,
              angle: arrowAngle,
            ),
          ),
        ],
      ),
      buttonDown: RectangleComponent(
        size: size,
        paint: Paint()
          ..color = const Color(0xC0000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(playerControllArrowImg),
              size: Vector2(24.0, 24.0),
              anchor: Anchor.center,
              angle: arrowAngle,
            ),
          ),
        ],
      ),
    );
  }

  // TapCallbacks実装時には必要(PositionComponentでは不要)
  @override
  bool containsLocalPoint(Vector2 point) => true;
}

// TextComponentにOpacityEffectを適用させるためのワークアラウンド
// https://github.com/flame-engine/flame/issues/1013
mixin HasOpacityProvider on Component implements OpacityProvider {
  double _opacity = 1;
  Paint _paint = BasicPalette.white.paint();

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    if (value == _opacity) return;
    _opacity = value;
    _paint = Paint()..color = Colors.white.withOpacity(value);
  }

  @override
  void renderTree(Canvas canvas) {
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.srcOver);
    super.renderTree(canvas);
    canvas.drawPaint(_paint..blendMode = BlendMode.modulate);
    canvas.restore();
  }
}

class CaTextComponent extends TextComponent with HasOpacityProvider {
  CaTextComponent(
      {super.anchor,
      super.angle,
      super.children,
      super.position,
      super.priority,
      super.scale,
      super.size,
      super.text,
      super.textRenderer});
}
