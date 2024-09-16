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
import 'package:flutter/services.dart';

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

  /// メニューボタン領域(元に戻すボタン、ステージ名、メニューボタンの領域含む)
  static Vector2 get menuButtonAreaSize => Vector2(360.0, 40.0);

  /// 元に戻すボタン領域
  static Vector2 get undoButtonAreaSize => Vector2(40.0, 40.0);

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

  late final Image stageImg;
  late final Image playerControllArrowImg;
  late final Image undoImg;
  late final Image settingsImg;
  final List<String> stageStrs = [];

  @override
  Future<void> onLoad() async {
    stageImg = await Flame.images.load('stage_alpha.png');
    playerControllArrowImg =
        await Flame.images.load('player_controll_arrow.png');
    undoImg = await Flame.images.load('undo.png');
    settingsImg = await Flame.images.load('settings.png');
    for (int i = 0; i < 30; i++) {
      stageStrs
          .add(await rootBundle.loadString('assets/texts/stage${i + 1}_1.txt'));
    }
    initialize();
  }

  // 初期化（というよりリセット）
  void initialize() {
    removeAll(children);

    // フリック入力のトリガー状態をリセット
    game.resetTriggered();

    stage = Stage(stageImg);
    switch (game.gameMode) {
      case GameMode.quest:
        stage.setDefault(game.world, game.camera);
        break;
      case GameMode.endless:
        stage.setDefault(game.world, game.camera);
        break;
      case GameMode.debug:
        stage.setDefault(game.world, game.camera);
        break;
    }

    // 画面上の操作ボタン
    add(
      playerControllButton(
        onPressed: () => isPushingU = true,
        onReleased: () => isPushingU = false,
        onCanceled: () => isPushingU = false,
        size: yButtonAreaSize,
        position: Vector2(0, topPaddingSize.y),
        arrowAngle: 0.0,
      ),
    );
    // 画面下の操作ボタン
    add(
      playerControllButton(
        onPressed: () => isPushingD = true,
        onReleased: () => isPushingD = false,
        onCanceled: () => isPushingD = false,
        size: yButtonAreaSize,
        position: Vector2(0, 640.0 - menuButtonAreaSize.y - yButtonAreaSize.y),
        arrowAngle: pi,
      ),
    );
    // 画面左の操作ボタン
    add(
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
        position: Vector2(0, topPaddingSize.y + yButtonAreaSize.y),
        arrowAngle: -0.5 * pi,
      ),
    );
    // 画面右の操作ボタン
    add(
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
        position: Vector2(
            360.0 - xButtonAreaSize.x, topPaddingSize.y + yButtonAreaSize.y),
        arrowAngle: 0.5 * pi,
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
            child: TextComponent(
              text: "ステージX",
              textRenderer: TextPaint(
                style: const TextStyle(
                  fontFamily: 'Aboreto',
                  color: Color(0xff000000),
                ),
              ),
            ),
          ),
        ],
      ));
    }
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
    // クリア済みならに何もしない
    if (stage.isClear()) return;
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
    }
    stage.update(dt, moveInput, game.world, game.camera);
    // 今回のupdateでクリアしたらクリア画面に移行
    if (stage.isClear()) {
      game.router.pushNamed('clear');
    }
  }

  ButtonComponent playerControllButton({
    required Vector2 size,
    Vector2? position,
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
