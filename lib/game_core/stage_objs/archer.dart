import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Archer extends StageObj {
  /// 各レベルに対応する動きのパターン
  static final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackStraight3,
    2: EnemyMovePattern.followPlayerAttackStraight5,
    3: EnemyMovePattern.followPlayerAttack3Straight5,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'archer.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static List<String> get attackImageFileNames =>
      ['archer_attack1.png', 'archer_attack2.png', 'archer_attack3.png'];

  /// 各レベルごとの矢の画像のファイル名
  static String get arrowImageFileName => 'arrow.png';

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// チャンネル->オブジェクトのレベル->向き->攻撃時アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<int, Map<Move, SpriteAnimation>>>
      levelToAttackAnimationsS = {};

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  static final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2.zero(),
    Move.down: Vector2.zero(),
    Move.left: Vector2.zero(),
    Move.right: Vector2.zero(),
  };

  /// 矢のアニメーション
  static List<SpriteAnimation> arrowAnimations = [];

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    final arrowImg = await Flame.images.load(arrowImageFileName);
    final List<Image> attackImgs = [
      for (final name in attackImageFileNames) await Flame.images.load(name)
    ];
    levelToAnimationsS = {
      0: {
        for (final move in MoveExtent.straights)
          move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      for (int i = 1; i <= 3; i++)
        i: {
          Move.left: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 128, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 160, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.right: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 192, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 224, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.up: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 64, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 96, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.down: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 0, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2((i - 1) * 256 + 32, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
        },
    };
    levelToAttackAnimationsS = {
      1: {
        0: {
          for (final move in MoveExtent.straights)
            move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
        },
        for (int i = 1; i <= 3; i++)
          i: {
            Move.down: SpriteAnimation.spriteList([
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.up: SpriteAnimation.spriteList([
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.left: SpriteAnimation.spriteList([
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(256, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(288, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(320, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(352, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.right: SpriteAnimation.spriteList([
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(384, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(416, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(448, 0), srcSize: Stage.cellSize),
              Sprite(attackImgs[i - 1],
                  srcPosition: Vector2(480, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
          },
      },
    };
    arrowAnimations = [
      for (int i = 1; i <= 3; i++)
        SpriteAnimation.spriteList([
          Sprite(arrowImg,
              srcPosition: Vector2((i - 1) * 32, 0), srcSize: Stage.cellSize),
        ], stepTime: 1.0)
    ];
  }

  /// 攻撃時の1コマ時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 矢が飛ぶ時間
  double arrowMoveTime(int dist) =>
      Stage.cellSize.x / 2 / Stage.playerSpeed * (dist / arrowReach);

  Archer({
    required super.pos,
    required super.savedArg,
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
          levelToAnimations: levelToAnimationsS,
          levelToAttackAnimations: levelToAttackAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.archer,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// 矢の飛距離
  int get arrowReach {
    int ret = 5;
    if (movePatterns[level]! == EnemyMovePattern.followPlayerAttackStraight3) {
      ret = 3;
    }
    return ret;
  }

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
      playerStartMovingFlag = true;
      // 移動/攻撃を決定
      final ret = super.enemyMove(
          movePatterns[level]!, vector, stage.player, stage, prohibitedPoints);
      if (ret.containsKey('attack') && ret['attack']!) {
        attacking = true;
        // 攻撃中のアニメーションに変更
        animationComponent.size =
            animationComponent.animation!.frames.first.sprite.srcSize;
        stage.setObjectPosition(this, offset: attackAnimationOffset[vector]!);
        vector = vector;
      }
      if (ret.containsKey('move')) {
        moving = ret['move'] as Move;
      }
      if (ret.containsKey('vector')) {
        vector = ret['vector'] as Move;
      }
      if (forceMoving != Move.none) {
        moving = forceMoving;
        forceMoving = Move.none;
      }
      movingAmount = 0;
    }

    if (playerStartMovingFlag) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      double prevMovingAmount = movingAmount;
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

      // 移動完了の半分時点を過ぎたら、矢のアニメーション追加
      if (attacking &&
          prevMovingAmount < Stage.cellSize.x / 2 &&
          movingAmount >= Stage.cellSize.x / 2) {
        List<Move> arrowVectors = [vector];
        if (movePatterns[level]! ==
            EnemyMovePattern.followPlayerAttack3Straight5) {
          arrowVectors.addAll(vector.neighbors);
        }
        for (final v in arrowVectors) {
          double angle = 0;
          angle = v.angle(base: Move.down);
          // 矢がオブジェクトに当たる場合、矢の飛距離はそこまでとなる
          int dist = arrowReach;
          if (!Config().isArrowPathThrough) {
            for (dist = 1; dist < arrowReach + 1; dist++) {
              final obj = stage.getAfterPush(pos + v.point * dist);
              if (!obj.isEnemy && !obj.enemyMovable) {
                break;
              }
            }
            --dist;
          }
          if (dist > 0) {
            gameWorld.add(SpriteAnimationComponent(
              animation: arrowAnimations[level - 1],
              priority: Stage.movingPriority,
              children: [
                MoveEffect.by(
                  Vector2(Stage.cellSize.x * v.vector.x * dist,
                      Stage.cellSize.y * v.vector.y * dist),
                  EffectController(duration: arrowMoveTime(dist)),
                ),
                RemoveEffect(delay: arrowMoveTime(dist)),
              ],
              size: Stage.cellSize,
              anchor: Anchor.center,
              angle: angle,
              position:
                  Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                      Stage.cellSize / 2,
            ));
          }
        }
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 移動後に関する処理
        endMoving(stage, gameWorld);
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        } else if (attacking) {
          // 矢による直線攻撃
          List<Move> arrowVectors = [vector];
          if (movePatterns[level]! ==
              EnemyMovePattern.followPlayerAttack3Straight5) {
            arrowVectors.addAll(vector.neighbors);
          }
          for (final v in arrowVectors) {
            // 矢がオブジェクトに当たる場合、矢の飛距離はそこまでとなる
            int dist = arrowReach;
            if (!Config().isArrowPathThrough) {
              for (dist = 0; dist < arrowReach; dist++) {
                final obj = stage.get(pos + v.point * dist);
                if (!obj.isEnemy && !obj.enemyMovable && !obj.isAlly) {
                  break;
                }
              }
              if (0 < dist && dist < arrowReach) {
                --dist;
              }
            }
            // 攻撃情報を追加
            stage.addEnemyAttackDamage(
                level, PointLineRange(pos + v.point, v, dist).set);
          }
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
        if (attacking) {
          attacking = false;
          // アニメーションを元に戻す
          vector = vector;
          animationComponent.size = Stage.cellSize;
          stage.setObjectPosition(this);
        }
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
  bool get hasVector => true;

  @override
  int get coins => level * 2;
}
