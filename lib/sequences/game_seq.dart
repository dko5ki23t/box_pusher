import 'dart:math';

import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

enum GameMode {
  quest,
  endless,
  debug,
}

class GameSeq extends Component
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

  /// ステージ領域
  static Vector2 get stageViewSize => Vector2(360.0 - xPaddingSize.x * 2,
      640.0 - menuButtonAreaSize.y - topPaddingSize.y - yPaddingSize.y * 2);

  /// ステージオブジェクト
  late Stage stage;

  /// 上下左右のボタンが押されているかどうか
  bool isPushingU = false;
  bool isPushingD = false;
  bool isPushingL = false;
  bool isPushingR = false;
  // 各斜めのボタンが押されているかどうか
  bool isPushingUL = false;
  bool isPushingUR = false;
  bool isPushingDL = false;
  bool isPushingDR = false;

  late final Image stageImg;
  late final Image playerImg;
  late final Image spikeImg;
  late final Image blockImg;
  late final Image coinImg;
  late final Image playerControllArrowImg;
  late final Image handAbilityImg;
  late final Image legAbilityImg;
  late final Image settingsImg;
  late TextComponent scoreText;
  late TextComponent coinNumText;
  ClipComponent? playerControllButtonsArea;
  ClipComponent? clipByDiagonalMoveButton;
  List<ButtonComponent>? playerStraightMoveButtons;
  List<ClipComponent>? playerDiagonalMoveButtons;

  @override
  Future<void> onLoad() async {
    stageImg = await Flame.images.load('stage_alpha.png');
    playerImg = await Flame.images.load('player.png');
    spikeImg = await Flame.images.load('spike.png');
    blockImg = await Flame.images.load('block.png');
    coinImg = await Flame.images.load('coin.png');
    playerControllArrowImg =
        await Flame.images.load('player_controll_arrow.png');
    handAbilityImg = await Flame.images.load('hand_ability.png');
    legAbilityImg = await Flame.images.load('leg_ability.png');
    settingsImg = await Flame.images.load('settings.png');
    initialize();
  }

  // 初期化（というよりリセット）
  void initialize() {
    removeAll(children);
    game.world.removeAll(game.world.children);

    // フリック入力のトリガー状態をリセット
    game.resetTriggered();

    stage = Stage(stageImg, playerImg, spikeImg, blockImg);
    switch (game.gameMode) {
      case GameMode.quest:
        stage.setDefault(game.world, game.camera, game.stageData);
        break;
      case GameMode.endless:
        stage.setDefault(game.world, game.camera, game.stageData);
        break;
      case GameMode.debug:
        stage.setDefault(game.world, game.camera, game.stageData);
        break;
    }

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
        onPressed: () => isPushingU = true,
        onReleased: () => isPushingU = false,
        onCanceled: () => isPushingU = false,
        size: yButtonAreaSize,
        position: Vector2(0, 0),
        arrowAngle: 0.0,
      ),
      // 画面下の操作ボタン
      playerControllButton(
        onPressed: () => isPushingD = true,
        onReleased: () => isPushingD = false,
        onCanceled: () => isPushingD = false,
        size: yButtonAreaSize,
        position: Vector2(
            0,
            640.0 -
                topPaddingSize.y -
                menuButtonAreaSize.y -
                yButtonAreaSize.y),
        arrowAngle: pi,
      ),
      // 画面左の操作ボタン
      playerControllButton(
        onPressed: () => isPushingL = true,
        onReleased: () => isPushingL = false,
        onCanceled: () => isPushingL = false,
        size: Vector2(
            xButtonAreaSize.x,
            640.0 -
                topPaddingSize.y -
                yButtonAreaSize.y * 2 -
                menuButtonAreaSize.y),
        position: Vector2(0, yButtonAreaSize.y),
        arrowAngle: -0.5 * pi,
      ),
      // 画面右の操作ボタン
      playerControllButton(
        onPressed: () => isPushingR = true,
        onReleased: () => isPushingR = false,
        onCanceled: () => isPushingR = false,
        size: Vector2(
            xButtonAreaSize.x,
            640.0 -
                topPaddingSize.y -
                yButtonAreaSize.y * 2 -
                menuButtonAreaSize.y),
        position: Vector2(360.0 - xButtonAreaSize.x, yButtonAreaSize.y),
        arrowAngle: 0.5 * pi,
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
            onPressed: () => isPushingUL = true,
            onReleased: () => isPushingUL = false,
            onCanceled: () => isPushingUL = false,
            size: dButtonAreaSize,
            position: Vector2(xButtonAreaSize.x * 0.5, yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: -0.25 * pi,
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
            onPressed: () => isPushingUR = true,
            onReleased: () => isPushingUR = false,
            onCanceled: () => isPushingUR = false,
            size: dButtonAreaSize,
            position: Vector2(
                clipSize.x - xButtonAreaSize.x * 0.5, yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: 0.25 * pi,
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
            onPressed: () => isPushingDL = true,
            onReleased: () => isPushingDL = false,
            onCanceled: () => isPushingDL = false,
            size: dButtonAreaSize,
            position: Vector2(
                xButtonAreaSize.x * 0.5, clipSize.y - yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: -0.75 * pi,
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
            onPressed: () => isPushingDR = true,
            onReleased: () => isPushingDR = false,
            onCanceled: () => isPushingDR = false,
            size: dButtonAreaSize,
            position: Vector2(clipSize.x - xButtonAreaSize.x * 0.5,
                clipSize.y - yButtonAreaSize.y * 0.5),
            anchor: Anchor.center,
            angle: 0.75 * pi,
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
    if (game.gameMode == GameMode.debug) {
      add(GameTextButton(
        size: menuButtonAreaSize,
        position: Vector2(0, 640.0 - menuButtonAreaSize.y),
        text: "現在の状態をログに出力",
        onReleased: stage.logCurrentStage,
      ));
    } else {
      scoreText = TextComponent(
        text: "${stage.score}",
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
    }
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
      onReleased: () => game.router.pushNamed("menu"),
    ));
  }

  void reset() {
    // ステージ情報初期化
    stage.reset();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // クリア済みなら何もしない
    if (stage.isClear()) return;
    // ゲームオーバー済みなら何もしない
    if (stage.isGameover) return;
    Move moveInput = Move.none;
    //bool inputUndo = false;
    if (game.isTriggeredL || isPushingL) {
      moveInput = Move.left;
    } else if (game.isTriggeredR || isPushingR) {
      moveInput = Move.right;
    } else if (game.isTriggeredU || isPushingU) {
      moveInput = Move.up;
    } else if (game.isTriggeredD || isPushingD) {
      moveInput = Move.down;
    } else if (isPushingUL) {
      moveInput = Move.upLeft;
    } else if (isPushingUR) {
      moveInput = Move.upRight;
    } else if (isPushingDL) {
      moveInput = Move.downLeft;
    } else if (isPushingDR) {
      moveInput = Move.downRight;
    }
    stage.update(dt, moveInput, game.world, game.camera);
    // スコア表示更新
    scoreText.text = "${stage.score}";
    // コイン数表示更新
    coinNumText.text = "${stage.coinNum}";
    // 今回のupdateでクリアしたらクリア画面に移行
    if (stage.isClear()) {
      game.router.pushNamed('clear');
    }
    // 今回のupdateでゲームオーバーになったらゲームオーバー画面に移行
    if (stage.isGameover) {
      // ハイスコア更新
      if (stage.score > game.highScore) {
        game.setAndSaveHighScore(stage.score);
      }
      game.router.pushNamed('gameover');
    }
  }

  ButtonComponent playerControllButton({
    required Vector2 size,
    Vector2? position,
    Anchor? anchor,
    double? angle,
    double? arrowAngle,
    void Function()? onPressed,
    void Function()? onReleased,
    void Function()? onCanceled,
  }) {
    return ButtonComponent(
      onPressed: onPressed,
      onReleased: onReleased,
      onCancelled: onCanceled,
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
