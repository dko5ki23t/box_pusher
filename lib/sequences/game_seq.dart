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

class SpriteComponentAndPoint {
  late final SpriteComponent sprite;
  Point initial;
  Point current;

  SpriteComponentAndPoint({
    required this.sprite,
    required this.initial,
    required this.current,
  });
}

class MoveHistory {
  final bool boxMoved;
  final Move move;

  MoveHistory({
    required this.boxMoved,
    required this.move,
  });
}

enum GameMode {
  quest,
  endless,
  debug,
}

class GameSeq extends Component
    with TapCallbacks, HasGameReference<BoxPusherGame> {
  /// プレイヤーの移動速度
  static const double playerSpeed = 96.0;

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

  /// プレイヤーが移動中かどうか
  bool isPlayerMoving = false;

  /// 一手戻している最中からどうか
  bool isUndoing = false;

  /// 箱が移動中かどうか
  bool isBoxMoving = false;

  /// 移動履歴
  List<MoveHistory> moveHistory = [];

  /// 移動中の箱
  SpriteComponentAndPoint? movingBox;

  /// 移動量
  double movingAmount = 0.0;

  /// 移動中の方向
  Move movingTo = Move.none;

  /// クリアしたかどうか
  bool isClear = false;

  /// 上下左右のボタンが押されているかどうか
  bool isPushingU = false;
  bool isPushingD = false;
  bool isPushingL = false;
  bool isPushingR = false;

  /// 一手戻すボタンが押されているかどうあk
  bool isPushUndo = false;

  late final Image stageImg;
  late final Image playerControllArrowImg;
  late final Image undoImg;
  late final Image settingsImg;
  final List<String> stageStrs = [];
  late SpriteComponent player;
  GameSpriteButton? undoButton;
  final List<SpriteComponentAndPoint> boxes = [];

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
    isPlayerMoving = false;
    isBoxMoving = false;
    movingAmount = 0;
    movingTo = Move.none;
    isClear = false;
    undoButton = null;
    boxes.clear();
    moveHistory.clear();
    removeAll(children);

    // フリック入力のトリガー状態をリセット
    game.resetTriggered();

//    if (info.stage_num <= 0 || info.stage_num > STAGE_NUM) {
//      GameLib::cout << "invalid stage number" << GameLib::endl;
//      setDefaultStage();
//      return;
//    }
//
    stage = Stage(stageImg);
    switch (game.gameMode) {
      case GameMode.quest:
        stage.setFromText(stageStrs[game.gameLevel - 1]);
        break;
      case GameMode.endless:
        stage.setRandom(7, 7, 3);
        break;
      case GameMode.debug:
        stage.setRandom(
            game.debugStageWidth, game.debugStageHeight, game.debugStageBoxNum);
        break;
    }

    // 描画
    for (int y = 0; y < stage.height; y++) {
      for (int x = 0; x < stage.width; x++) {
        StageObj obj = stage.get(Point(x, y));
        switch (obj) {
          case StageObj.none:
          case StageObj.box:
          case StageObj.player:
            add(stage.getCellSprite(StageObj.none, x, y, 0, 0));
            break;
          case StageObj.wall:
            add(stage.getCellSprite(StageObj.wall, x, y, 0, 0));
            break;
          case StageObj.goal:
          case StageObj.boxOnGoal:
          case StageObj.playerOnGoal:
            add(stage.getCellSprite(StageObj.goal, x, y, 0, 0));
            break;
          default:
            break;
        }
        if (obj == StageObj.box || obj == StageObj.boxOnGoal) {
          boxes.add(SpriteComponentAndPoint(
            sprite: stage.getCellSprite(StageObj.box, x, y, 0, 0),
            initial: Point(x, y),
            current: Point(x, y),
          ));
        }
      }
    }

    // 箱を描画
    for (final box in boxes) {
      add(box.sprite);
    }

    // プレイヤーを描画
    player = stage.getCellSprite(
        StageObj.player, stage.playerX, stage.playerY, 0, 0);
    add(player);

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
        text: "ステージをログに出力",
        onReleased: stage.logInitialStage,
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
    // 一手戻すボタン領域
    undoButton = GameSpriteButton(
      onPressed: () => isPushUndo = true,
      onReleased: () => isPushUndo = false,
      onCancelled: () => isPushUndo = false,
      enabled: moveHistory.isNotEmpty,
      size: undoButtonAreaSize,
      position: Vector2(xPaddingSize.x, 640.0 - menuButtonAreaSize.y),
      sprite: Sprite(undoImg),
    );
    add(undoButton!);
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
    // 荷物位置初期化
    for (final box in boxes) {
      box.current = box.initial;
      // 描画
      stage.setCellPosition(box.sprite, box.current.x, box.current.y, 0, 0);
    }
    // プレイヤー描画
    stage.setCellPosition(player, stage.playerX, stage.playerY, 0, 0);

    // 各種変数初期化
    movingBox = null;
    isClear = stage.isClear();
    moveHistory.clear();
    isPlayerMoving = false;
    isUndoing = false;
    isBoxMoving = false;
    movingAmount = 0;
    movingTo = Move.none;

    // 一手戻すボタンの有効/無効切り替え
    undoButton!.enabled = false;
    // 無効になったなら一手戻すボタン押されたかフラグをオフに
    isPushUndo = false;
  }

  @override
  void update(double dt) {
    // クリア済みなら何もしない
    if (isClear) return;
    if (!isPlayerMoving) {
      // 移動中でない場合
      int toX = stage.playerX;
      int toY = stage.playerY;
      int toToX = stage.playerX;
      int toToY = stage.playerY;
      Move move = Move.none;

      if (game.isTriggeredL || isPushingL) {
        toX--;
        toToX = toX - 1;
        move = Move.left;
      } else if (game.isTriggeredR || isPushingR) {
        toX++;
        toToX = toX + 1;
        move = Move.right;
      } else if (game.isTriggeredU || isPushingU) {
        toY--;
        toToY = toY - 1;
        move = Move.up;
      } else if (game.isTriggeredD || isPushingD) {
        toY++;
        toToY = toY + 1;
        move = Move.down;
      } else if (isPushUndo && moveHistory.isNotEmpty) {
        final lastMove = moveHistory.removeLast();
        final boxPos = Point(toX, toY);
        // 履歴の逆に動く
        switch (lastMove.move) {
          case Move.left:
            toX++;
            toToX = toX + 1;
            boxPos.x--;
            move = Move.right;
            break;
          case Move.right:
            toX--;
            toToX = toX - 1;
            boxPos.x++;
            move = Move.left;
            break;
          case Move.up:
            toY++;
            toToY = toY + 1;
            boxPos.y--;
            move = Move.down;
            break;
          case Move.down:
            toY--;
            toToY = toY - 1;
            boxPos.y++;
            move = Move.up;
            break;
          default:
            break;
        }
        isBoxMoving = lastMove.boxMoved;
        if (isBoxMoving) {
          for (final box in boxes) {
            if (box.current == boxPos) {
              movingBox = box;
              break;
            }
          }
        }
        isUndoing = true;
      } else {
        return;
      }

      // 一手戻す場合以外は移動に関して判定
      if (!isUndoing) {
        // ステージ外に飛び出さないか
        if (toX < 0 || toX >= stage.width || toY < 0 || toY >= stage.height) {
          return;
        }

        // 壁にぶつかるか
        if (stage.get(Point(toX, toY)) == StageObj.wall) {
          return;
        }

        // 荷物があるか
        if (stage.get(Point(toX, toY)) == StageObj.box ||
            stage.get(Point(toX, toY)) == StageObj.boxOnGoal) {
          // 押せるかどうか
          if (toToX < 0 ||
              toToX >= stage.width ||
              toToY < 0 ||
              toToY >= stage.height) {
            return;
          }
          if (stage.get(Point(toToX, toToY)) != StageObj.none &&
              stage.get(Point(toToX, toToY)) != StageObj.goal) {
            return;
          }
          for (final box in boxes) {
            if (box.current.x == toX && box.current.y == toY) {
              movingBox = box;
              break;
            }
          }
          isBoxMoving = true;
        }
      }

      isPlayerMoving = true;
      movingTo = move;
      movingAmount = 0.0;
    }
    if (isPlayerMoving) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      //movingAmount += playerSpeed;
      movingAmount += dt * playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      int px = 0;
      int py = 0;

      if (isPlayerMoving) {
        switch (movingTo) {
          case Move.left:
            px = (-1 * movingAmount).floor();
            break;
          case Move.right:
            px = (movingAmount).floor();
            break;
          case Move.up:
            py = (-1 * movingAmount).floor();
            break;
          case Move.down:
            py = (movingAmount).floor();
            break;
          default:
            break;
        }
        stage.setCellPosition(player, stage.playerX, stage.playerY, px, py);
        if (isBoxMoving) {
          stage.setCellPosition(movingBox!.sprite, movingBox!.current.x,
              movingBox!.current.y, px, py);
        }
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        int toX = stage.playerX;
        int toY = stage.playerY;
        int toToX = stage.playerX;
        int toToY = stage.playerY;

        switch (movingTo) {
          case Move.left:
            toX--;
            if (!isUndoing) toToX = toX - 1;
            break;
          case Move.right:
            toX++;
            if (!isUndoing) toToX = toX + 1;
            break;
          case Move.up:
            toY--;
            if (!isUndoing) toToY = toY - 1;
            break;
          case Move.down:
            toY++;
            if (!isUndoing) toToY = toY + 1;
            break;
          default:
            return;
        }

        // 荷物位置更新
        if (isBoxMoving) {
          switch (stage.get(Point(toToX, toToY))) {
            case StageObj.none:
              stage.set(Point(toToX, toToY), StageObj.box);
              break;
            case StageObj.goal:
              stage.set(Point(toToX, toToY), StageObj.boxOnGoal);
              break;
            default:
              // ありえない
              //HALT("fatal error");
              break;
          }
          if (isUndoing) {
            switch (stage.get(movingBox!.current)) {
              case StageObj.box:
                stage.set(movingBox!.current, StageObj.none);
                break;
              case StageObj.boxOnGoal:
                stage.set(movingBox!.current, StageObj.goal);
                break;
              default:
                // ありえない
                //HALT("fatal error");
                break;
            }
          } else {
            switch (stage.get(Point(toX, toY))) {
              case StageObj.box:
                stage.set(Point(toX, toY), StageObj.none);
                break;
              case StageObj.boxOnGoal:
                stage.set(Point(toX, toY), StageObj.goal);
                break;
              default:
                // ありえない
                //HALT("fatal error");
                break;
            }
          }
          movingBox!.current = Point(toToX, toToY);
          stage.setCellPosition(movingBox!.sprite, movingBox!.current.x,
              movingBox!.current.y, 0, 0);
          movingBox = null;
          isClear = stage.isClear();
        }

        // プレーヤー位置更新
        stage.playerX = toX;
        stage.playerY = toY;
        stage.setCellPosition(player, stage.playerX, stage.playerY, 0, 0);

        // 移動履歴に追加
        if (!isUndoing) {
          moveHistory.add(MoveHistory(boxMoved: isBoxMoving, move: movingTo));
        }

        // 一手戻すボタンの有効/無効切り替え
        undoButton!.enabled = moveHistory.isNotEmpty;
        // 無効になったなら一手戻すボタン押されたかフラグをオフに
        if (moveHistory.isEmpty) {
          isPushUndo = false;
        }

        // 各種移動中変数初期化
        isPlayerMoving = false;
        isUndoing = false;
        isBoxMoving = false;
        movingAmount = 0;
        movingTo = Move.none;

        if (isClear) {
          game.router.pushNamed('clear');
        }
      }
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
