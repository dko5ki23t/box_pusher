import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Pusher extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.walkAndPushRandomOrStop,
    2: EnemyMovePattern.walkAndPushRandomOrStop,
    3: EnemyMovePattern.walkAndPushRandomOrStop,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'pusher.png';

  Pusher({
    required Image pusherImg,
    required Image errorImg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.movingPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: {
            0: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
            },
            for (int i = 0; i < 3; i++)
              i + 1: {
                Move.left: SpriteAnimation.spriteList([
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 128, 0),
                      srcSize: Stage.cellSize),
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 160, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 192, 0),
                      srcSize: Stage.cellSize),
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 224, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 64, 0),
                      srcSize: Stage.cellSize),
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 96, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.down: SpriteAnimation.spriteList([
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 0, 0),
                      srcSize: Stage.cellSize),
                  Sprite(pusherImg,
                      srcPosition: Vector2(i * 256 + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.builder,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// 一度にいくつのオブジェクトを押せるか(-1なら制限なし)
  int pushableNum = 1;

  @override
  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    bool playerEndMoving,
    Map<Point, Move> prohibitedPoints,
  ) {
    if (playerStartMoving) {
      playerStartMovingFlag = true;
      // ランダムに移動(オブジェクト押すこともできる)orその場で停止
      final ret = super.enemyMove(
        movePatterns[level]!,
        vector,
        stage.player,
        stage,
        prohibitedPoints,
        gameWorld: gameWorld,
        pushableNum: pushableNum,
      );
      if (ret.containsKey('move')) {
        moving = ret['move'] as Move;
      }
      if (ret.containsKey('vector')) {
        vector = ret['vector'] as Move;
      }
      movingAmount = 0;
    }

    if (playerStartMovingFlag) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      if (moving != Move.none) {
        // ※※※画像の移動ここから※※※
        // 移動中の場合は画素も考慮
        Vector2 offset = moving.vector * movingAmount;
        stage.setObjectPosition(this, offset: offset);
        for (final pushing in pushings) {
          // 押しているオブジェクトの位置変更
          stage.setObjectPosition(pushing, offset: offset);
          // 押しているオブジェクトの向き変更
          pushing.vector = moving.toStraightLR();
        }
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 押すオブジェクトに関する処理
        endPushing(stage, gameWorld);
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
      }
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => true;

  @override
  bool get puttable => false;

  @override
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => true;
}
