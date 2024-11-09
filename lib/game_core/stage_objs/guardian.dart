import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Guardian extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'guardian.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static String get attackDImageFileName => 'guardian_attackD.png';
  static String get attackLImageFileName => 'guardian_attackL.png';
  static String get attackRImageFileName => 'guardian_attackR.png';
  static String get attackUImageFileName => 'guardian_attackU.png';

  /// オブジェクトのレベル->向き->攻撃時アニメーションのマップ
  final Map<int, Map<Move, SpriteAnimation>> levelToAttackAnimations;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2(0, -16.0),
    Move.down: Vector2(0, 16.0),
    Move.left: Vector2(-16.0, 0),
    Move.right: Vector2(16.0, 0)
  };

  /// 攻撃の1コマの時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 5;

  Guardian({
    required super.pos,
    required Image guardianImg,
    required Image attackDImg,
    required Image attackLImg,
    required Image attackRImg,
    required Image attackUImg,
    required Image errorImg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    int level = 1,
  })  : levelToAttackAnimations = {
          0: {
            Move.left:
                SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            Move.right:
                SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            Move.down:
                SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            Move.up:
                SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
          },
          1: {
            Move.down: SpriteAnimation.fromFrameData(
              attackDImg,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.up: SpriteAnimation.fromFrameData(
              attackUImg,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.left: SpriteAnimation.fromFrameData(
              attackLImg,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
            Move.right: SpriteAnimation.fromFrameData(
              attackRImg,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
          },
        },
        super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.dynamicPriority,
            size: Stage.cellSize,
            scale: scale,
            anchor: Anchor.center,
            children: [scaleEffect],
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: {
            0: {
              Move.left:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
              Move.right:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
              Move.down:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
              Move.up:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            },
            1: {
              Move.left: SpriteAnimation.spriteList([
                Sprite(guardianImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.right: SpriteAnimation.spriteList([
                Sprite(guardianImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.up: SpriteAnimation.spriteList([
                Sprite(guardianImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.down: SpriteAnimation.spriteList([
                Sprite(guardianImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.guardian,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// 攻撃中か
  bool attacking = false;

  @override
  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    List<Point> prohibitedPoints,
  ) {
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      playerStartMovingFlag = true;
      // 周囲8マスに敵がいる場合、そちらを向いて攻撃を始める
      final enemyCounts = {
        Move.up: 0,
        Move.down: 0,
        Move.left: 0,
        Move.right: 0,
      };
      // TODO:この動きもstageObj.enemyMove()に追加？
      for (final move in MoveExtent.straights) {
        // 該当向きの3マスにいる敵の数をカウントする
        final t = pos + move.point;
        final tmps = MoveExtent.straights;
        tmps.remove(move);
        tmps.remove(move.oppsite);
        List<Point> attackPoints = [t];
        for (final tmp in tmps) {
          attackPoints.add(t + tmp.point);
        }
        for (final attackPoint in attackPoints) {
          final obj = stage.get(attackPoint);
          if (obj.isEnemy && obj.killable) {
            enemyCounts[move] = enemyCounts[move]! + 1;
          }
        }
      }
      // 最も敵が多い向きの中からランダムに1つを選ぶ
      List<Move> bestVectors = [];
      int bestEnemyCount = 1;
      for (final entry in enemyCounts.entries) {
        if (entry.value > bestEnemyCount) {
          bestEnemyCount = entry.value;
          bestVectors = [entry.key];
        } else if (entry.value == bestEnemyCount) {
          bestVectors.add(entry.key);
        }
      }
      if (bestVectors.isNotEmpty) {
        vector = bestVectors.sample(1).first;
        attacking = true;
        // 攻撃中のアニメーションに変更
        //if (typeLevel.level <= 1) {
        int key = levelToAttackAnimations.containsKey(level) ? level : 0;
        animationComponent.animation = levelToAttackAnimations[key]![vector]!;
        animationComponent.size =
            animationComponent.animation!.frames.first.sprite.srcSize;
        stage.objFactory
            .setPosition(this, offset: attackAnimationOffset[vector]!);
        //} else {
        //  animation.animation = roundAttackAnimation[vector]!;
        //  animation.size = animation.animation!.frames.first.sprite.srcSize;
        //  stage.objFactory
        //      .setPosition(this, offset: roundAttackAnimationOffset);
        //}
      }
      movingAmount = 0;
    }

    if (playerStartMovingFlag) {
      // 移動中（攻撃中）の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      //if (moving != Move.none) {
      //  // ※※※画像の移動ここから※※※
      //  // 移動中の場合は画素も考慮
      //  Vector2 offset = moving.vector * movingAmount;
      //  stage.objFactory.setPosition(this, offset: offset);
      //  // ※※※画像の移動ここまで※※※
      //}

      // 攻撃終了
      if (movingAmount >= Stage.cellSize.x) {
        // 前方3マスの敵のレベルを、ガーディアンのレベル分だけ下げる
        // レベルが0以下になった敵は消す
        if (attacking) {
          //if (typeLevel.level <= 1) {
          final tmp = MoveExtent.straights;
          tmp.remove(vector);
          tmp.remove(vector.oppsite);
          final attackable = pos + vector.point;
          final attackables = [attackable];
          for (final v in tmp) {
            attackables.add(attackable + v.point);
          }
          for (final p in attackables) {
            final obj = stage.get(p);
            if (obj.isEnemy && obj.killable) {
              obj.level -= level;
              if (obj.level <= 0) {
                gameWorld.remove(obj.animationComponent);
                stage.enemies.remove(obj);
              }
            }
          }
          //} else if (PointRectRange((pos - Point(1, 1)), pos + Point(1, 1))
          //    .contains(stage.player.pos)) {
          //  // 回転斬りの場合は周囲8マス
          //  stage.isGameover = true;
          //}
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
        if (attacking) {
          // アニメーションを元に戻す
          vector = vector;
          animationComponent.size = Stage.cellSize;
          stage.objFactory.setPosition(this);
          attacking = false;
        }
      }
    }
  }

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 20;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;
}
