import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Boneman extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayer,
    2: EnemyMovePattern.followPlayer,
    3: EnemyMovePattern.followPlayer,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'boneman.png';

  /// 復活に要するターン数(死んでいる期間)
  int get deadPeriod {
    switch (level) {
      case 3:
        return 6;
      case 2:
        return 8;
      default:
        return 10;
    }
  }

  /// 倒されてからの経過ターン数(0は生きている)
  int deadTurns = 0;

  Boneman({
    required Image boneImg,
    required Image errorImg,
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
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
                    stepTime: 1.0)
            },
            for (int i = 0; i < 3; i++)
              i + 1: {
                Move.left: SpriteAnimation.spriteList([
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 128, 0),
                      srcSize: Stage.cellSize),
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 160, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 192, 0),
                      srcSize: Stage.cellSize),
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 224, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 64, 0),
                      srcSize: Stage.cellSize),
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 96, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.down: SpriteAnimation.spriteList([
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 0, 0),
                      srcSize: Stage.cellSize),
                  Sprite(boneImg,
                      srcPosition: Vector2(i * 256 + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          levelToAttackAnimations: {
            // 骨になったときのアニメーション
            1: {
              0: {
                Move.none: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
              },
              for (int i = 1; i <= 3; i++)
                i: {
                  Move.none: SpriteAnimation.spriteList([
                    Sprite(boneImg,
                        srcPosition: Vector2(64 * (i - 1) + 768, 0),
                        srcSize: Stage.cellSize),
                  ], stepTime: 1.0),
                },
            },
            // あと2ターンで復活アニメーション
            2: {
              0: {
                Move.none: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
              },
              for (int i = 1; i <= 3; i++)
                i: {
                  Move.none: SpriteAnimation.spriteList([
                    Sprite(boneImg,
                        srcPosition: Vector2(64 * (i - 1) + 768, 0),
                        srcSize: Stage.cellSize),
                    Sprite(boneImg,
                        srcPosition: Vector2(64 * (i - 1) + 800, 0),
                        srcSize: Stage.cellSize),
                  ], stepTime: Stage.objectStepTime),
                },
            },
            // あと1ターンで復活アニメーション
            3: {
              0: {
                Move.none: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
              },
              for (int i = 1; i <= 3; i++)
                i: {
                  Move.none: SpriteAnimation.spriteList([
                    Sprite(boneImg,
                        srcPosition: Vector2(64 * (i - 1) + 768, 0),
                        srcSize: Stage.cellSize),
                    Sprite(boneImg,
                        srcPosition: Vector2(64 * (i - 1) + 800, 0),
                        srcSize: Stage.cellSize),
                  ], stepTime: Stage.objectStepTime / 2),
                },
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.boneman,
            level: level,
          ),
        ) {
    // 復元された、倒されてからのターン数に応じてアニメーション変更
    attacking = deadTurns > 0;
    _setAttackCh();
    if (attacking) {
      if (scale != null) {
        animationComponent.scale = scale;
      }
      animationComponent.add(scaleEffect);
    }
    vector = vector;
  }

  bool playerStartMovingFlag = false;

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
      if (deadTurns == 0) {
        // 死んでないなら
        // 移動を決定
        final ret = super.enemyMove(movePatterns[level]!, vector, stage.player,
            stage, prohibitedPoints);
        if (ret.containsKey('move')) {
          moving = ret['move'] as Move;
        }
        if (ret.containsKey('vector')) {
          vector = ret['vector'] as Move;
        }
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
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        // 死んでないなら
        if (deadTurns == 0) {
          pos += moving.point;
          // 移動後に関する処理
          endMoving(stage, gameWorld);
          // ゲームオーバー判定
          if (stage.player.pos == pos) {
            // 同じマスにいる場合はアーマー関係なくゲームオーバー
            stage.isGameover = true;
          }
        } else {
          // 死んでいるなら
          ++deadTurns;
          if (deadTurns >= deadPeriod) {
            // 復活
            deadTurns = 0;
            attacking = false;
            // スケールエフェクト削除
            animationComponent.removeAll(animationComponent.children);
            vector = Move.down;
            stage.boxes.forceRemove(this);
            stage.enemies.add(this);
          } else {
            _setAttackCh();
            vector = vector;
          }
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
      }
    }
  }

  void _setAttackCh() {
    if (deadTurns >= deadPeriod - 1) {
      attackCh = 3;
    } else if (deadTurns >= deadPeriod - 2) {
      attackCh = 2;
    } else {
      attackCh = 1;
    }
  }

  /// 攻撃を受ける
  /// やられたかどうかを返す
  @override
  bool hit(int damageLevel, Stage stage) {
    if (!killable) return false;
    // レベルは下がらない
    // level = (level - damageLevel).clamp(0, maxLevel);
    if (damageLevel >= level) {
      deadTurns = 1;
      stage.enemies.forceRemove(this);
      stage.boxes.add(this);
      // 倒されたアニメーションに切り替える
      attacking = true;
      _setAttackCh();
      stage.setScaleEffects(this);
      vector = vector;
    }
    return false;
  }

  @override
  bool get pushable => deadTurns > 0;

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
  bool get isEnemy => deadTurns == 0;

  @override
  bool get killable => deadTurns == 0;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => deadTurns == 0;

  @override
  int get coins => level * 2;

  // deadTurnsの保存/読み込み
  @override
  int get arg => deadTurns;

  @override
  void loadArg(int val) {
    deadTurns = val;
  }
}
