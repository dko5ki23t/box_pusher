import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Spike extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.mergeWalkRandomOrStop,
    2: EnemyMovePattern.walkRandomOrStop,
    3: EnemyMovePattern.followPlayer,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'spike.png';

  bool _playerStartMovingFlag = false;

  Spike({
    required Image spikeImg,
    required Image errorImg,
    required super.savedArg,
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
              Move.none:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            },
            1: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(spikeImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                Sprite(spikeImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize)
              ], stepTime: Stage.objectStepTime),
            },
            2: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(spikeImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(spikeImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
              ], stepTime: Stage.objectStepTime),
            },
            3: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(spikeImg,
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
                Sprite(spikeImg,
                    srcPosition: Vector2(160, 0), srcSize: Stage.cellSize)
              ], stepTime: Stage.objectStepTime),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.spike,
            level: level,
          ),
        );

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
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      // 移動を決定する
      final ret = super.enemyMove(movePatterns[level]!, Move.none, stage.player,
          stage, prohibitedPoints);
      if (ret.containsKey('move')) {
        moving = ret['move'] as Move;
      }
      movingAmount = 0;
      _playerStartMovingFlag = true;
    }

    if (_playerStartMovingFlag) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      if (moving != Move.none) {
        Vector2 offset = moving.vector * movingAmount;
        stage.setObjectPosition(this, offset: offset);
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 移動後に関する処理
        endMoving(stage, gameWorld);
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        _playerStartMovingFlag = false;
      }
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get playerMovable => true;

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
  bool get hasVector => false;

  @override
  int get coins => level * 1;
}
