import 'package:box_pusher/config.dart';
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
  static List<Map<Move, String>> get swordFowardAttackImageFileNames => [
        {
          Move.down: 'guardian_attackD1.png',
          Move.left: 'guardian_attackL1.png',
          Move.right: 'guardian_attackR1.png',
          Move.up: 'guardian_attackU1.png',
        }
      ];
  static Map<int, String> get swordRoundAttackImageFileNames => {
        for (int i = 2; i <= 3; i++) i: 'guardian_attack_round$i.png',
      };
  static Map<int, String> get subAttackImageFileNames => {
        2: 'guardian_attack_bow2.png',
        3: 'guardian_attack_magic3.png',
      };
  static Map<int, String> get arrowMagicImageFileNames => {
        2: 'guardian_arrow.png',
        3: 'guardian_magic.png',
      };

  /// 前方3マスへの斬撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2(0, -16.0),
    Move.down: Vector2(0, 16.0),
    Move.left: Vector2(-16.0, 0),
    Move.right: Vector2(16.0, 0)
  };

  final Map<int, Map<Move, SpriteAnimation>> swordForwardAttackAnimations;
  final Map<int, Map<Move, SpriteAnimation>> swordRoundAttackAnimations;
  final Map<int, Map<Move, SpriteAnimation>> subAttackAnimations;
  final Map<int, SpriteAnimation> arrowMagicAnimations;

  /// 前方3マスへの斬撃の1コマの時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 5;

  /// 回転斬りの1コマの時間
  static const double roundAttackStepTime = 32.0 / Stage.playerSpeed / 20;

  /// 弓矢/魔法攻撃時の1コマ時間
  static const double subAttackStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 飛び道具が飛ぶ時間
  static final arrowMagicMoveTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  Guardian({
    required super.pos,
    required Image guardianImg,
    required List<Map<Move, Image>> swordForwardAttackImgs,
    required Map<int, Image> swordRoundAttackImgs,
    required Map<int, Image> subAttackImgs,
    required Map<int, Image> arrowMagicImgs,
    required Image errorImg,
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    int level = 1,
  })  : swordForwardAttackAnimations = {
          for (int i in [0, 2, 3])
            i: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0)
            },
          1: {
            Move.down: SpriteAnimation.fromFrameData(
              swordForwardAttackImgs[0][Move.down]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.up: SpriteAnimation.fromFrameData(
              swordForwardAttackImgs[0][Move.up]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.left: SpriteAnimation.fromFrameData(
              swordForwardAttackImgs[0][Move.left]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
            Move.right: SpriteAnimation.fromFrameData(
              swordForwardAttackImgs[0][Move.right]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
          },
        },
        swordRoundAttackAnimations = {
          for (int i = 0; i <= 1; i++)
            i: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0)
            },
          for (int i = 2; i <= 3; i++)
            i: {
              Move.down: SpriteAnimation.fromFrameData(
                swordRoundAttackImgs[i]!,
                SpriteAnimationData.sequenced(
                    amount: 20,
                    stepTime: roundAttackStepTime,
                    textureSize: Vector2.all(96.0)),
              ),
              Move.up: SpriteAnimation.spriteList(
                [
                  for (int j = 10; j < 30; j++)
                    Sprite(swordRoundAttackImgs[i]!,
                        srcPosition: Vector2((j % 20) * 96, 0),
                        srcSize: Vector2.all(96.0))
                ],
                stepTime: roundAttackStepTime,
              ),
              Move.left: SpriteAnimation.spriteList(
                [
                  for (int j = 5; j < 25; j++)
                    Sprite(swordRoundAttackImgs[i]!,
                        srcPosition: Vector2((j % 20) * 96, 0),
                        srcSize: Vector2.all(96.0))
                ],
                stepTime: roundAttackStepTime,
              ),
              Move.right: SpriteAnimation.spriteList(
                [
                  for (int j = 15; j < 35; j++)
                    Sprite(swordRoundAttackImgs[i]!,
                        srcPosition: Vector2((j % 20) * 96, 0),
                        srcSize: Vector2.all(96.0))
                ],
                stepTime: roundAttackStepTime,
              ),
            },
        },
        subAttackAnimations = {
          for (int i = 0; i <= 1; i++)
            i: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0)
            },
          for (int i = 2; i <= 3; i++)
            i: {
              Move.down: SpriteAnimation.spriteList(
                [
                  for (int j = 0; j < 4; j++)
                    Sprite(subAttackImgs[i]!,
                        srcPosition: Vector2(j * 32, 0),
                        srcSize: Stage.cellSize)
                ],
                stepTime: subAttackStepTime,
              ),
              Move.up: SpriteAnimation.spriteList(
                [
                  for (int j = 4; j < 8; j++)
                    Sprite(subAttackImgs[i]!,
                        srcPosition: Vector2(j * 32, 0),
                        srcSize: Stage.cellSize)
                ],
                stepTime: subAttackStepTime,
              ),
              Move.left: SpriteAnimation.spriteList(
                [
                  for (int j = 8; j < 12; j++)
                    Sprite(subAttackImgs[i]!,
                        srcPosition: Vector2(j * 32, 0),
                        srcSize: Stage.cellSize)
                ],
                stepTime: subAttackStepTime,
              ),
              Move.right: SpriteAnimation.spriteList(
                [
                  for (int j = 12; j < 16; j++)
                    Sprite(subAttackImgs[i]!,
                        srcPosition: Vector2(j * 32, 0),
                        srcSize: Stage.cellSize)
                ],
                stepTime: subAttackStepTime,
              ),
            },
        },
        arrowMagicAnimations = {
          for (int i = 0; i <= 1; i++)
            i: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
          2: SpriteAnimation.spriteList([
            Sprite(arrowMagicImgs[2]!, srcSize: Stage.cellSize),
          ], stepTime: 1.0),
          3: SpriteAnimation.spriteList([
            Sprite(arrowMagicImgs[3]!,
                srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
            Sprite(arrowMagicImgs[3]!,
                srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
          ], stepTime: 1.0)
        },
        super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.movingPriority,
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
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
            },
            for (int i = 0; i < 3; i++)
              i + 1: {
                Move.left: SpriteAnimation.spriteList([
                  Sprite(guardianImg,
                      srcPosition: Vector2(i * 128 + 64, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(guardianImg,
                      srcPosition: Vector2(i * 128 + 96, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(guardianImg,
                      srcPosition: Vector2(i * 128 + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.down: SpriteAnimation.spriteList([
                  Sprite(guardianImg,
                      srcPosition: Vector2(i * 128, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          levelToAttackAnimations: {},
          typeLevel: StageObjTypeLevel(
            type: StageObjType.guardian,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// 攻撃中のマス
  Set<Point> attackingPoints = {};

  /// 弓矢や魔法による攻撃かどうか
  bool isBowMagicAttacking = false;

  /// 攻撃中飛び道具の飛距離
  int attackingReach = 5;

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
    // プレイヤー移動し始めのフレームの場合
    if (playerStartMoving) {
      // プレイヤーが移動中であるフラグをオン
      playerStartMovingFlag = true;
      // TODO:この動きもstageObj.enemyMove()に追加？
      // 1.攻撃範囲に敵がいる場合、その方向に攻撃する
      if (level == 1) {
        // 前方3マスへの斬撃
        List<Point> attackPoints = [
          pos + vector.point,
          for (final move in vector.neighbors) pos + move.point,
        ];
        for (final attackPoint in attackPoints) {
          final obj = stage.get(attackPoint);
          if (obj.isEnemy && obj.killable) {
            attacking = true;
            // アニメーション変更
            levelToAttackAnimations = swordForwardAttackAnimations;
            vector = vector;
            animationComponent.size =
                animationComponent.animation!.frames.first.sprite.srcSize;
            stage.setObjectPosition(this,
                offset: attackAnimationOffset[vector]!);
            attackingPoints.addAll(attackPoints);
            break;
          }
        }
      } else if (level > 1) {
        // 周囲8マスへの回転斬り
        for (final attackPoint
            in PointRectRange(pos + Point(-1, -1), pos + Point(1, 1)).set) {
          final obj = stage.get(attackPoint);
          if (obj.isEnemy && obj.killable) {
            attacking = true;
            // アニメーション変更
            levelToAttackAnimations = swordRoundAttackAnimations;
            vector = vector;
            animationComponent.size =
                animationComponent.animation!.frames.first.sprite.srcSize;
            attackingPoints.addAll(
                PointRectRange(pos + Point(-1, -1), pos + Point(1, 1)).set);
            break;
          }
        }
        if (!attacking) {
          // 前方直線5マスへの飛び道具
          attackingReach = 5;
          for (final attackPoint
              in PointLineRange(pos + vector.point, vector, attackingReach)
                  .set) {
            final obj = stage.get(attackPoint);
            if (obj.isEnemy && obj.killable) {
              attacking = true;
              isBowMagicAttacking = true;
              // アニメーション変更
              levelToAttackAnimations = subAttackAnimations;
              vector = vector;
              if (level == 2 && !Config().isArrowPathThrough) {
                // 矢がオブジェクトに当たる場合は飛距離はそこまで
                for (attackingReach = 0; attackingReach < 5; attackingReach++) {
                  final obj =
                      stage.getAfterPush(pos + vector.point * attackingReach);
                  if (obj.type != StageObjType.guardian &&
                      !obj.isEnemy &&
                      !obj.enemyMovable) {
                    break;
                  }
                }
                if (0 < attackingReach && attackingReach < 5) {
                  --attackingReach;
                }
              }
              attackingPoints.addAll(
                  PointLineRange(pos + vector.point, vector, attackingReach)
                      .set);
              break;
            }
          }
        }
      }
      // 2.攻撃範囲に敵を含められる向きがあるならそちらを向く
      if (!attacking) {
        final enemyCounts = {};
        for (final move in MoveExtent.straights) {
          if (move == vector) continue;
          enemyCounts[move] = 0;
          // 攻撃範囲にいる敵をカウントする
          List<Point> attackPoints = [];
          if (level == 1) {
            attackPoints.addAll([
              (pos + move.point),
              for (final m in move.neighbors) pos + m.point
            ]);
          } else {
            attackPoints.addAll(
                PointLineRange(pos + move.point, move, attackingReach).set);
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
        }
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

      // 移動完了の半分時点を過ぎたら、飛び道具のアニメーション追加
      if (isBowMagicAttacking &&
          prevMovingAmount < Stage.cellSize.x / 2 &&
          movingAmount >= Stage.cellSize.x / 2) {
        double angle = 0;
        angle = vector.angle(base: Move.down);
        gameWorld.add(SpriteAnimationComponent(
          animation: arrowMagicAnimations[level]!,
          priority: Stage.movingPriority,
          children: [
            MoveEffect.by(
              Vector2(Stage.cellSize.x * vector.vector.x * attackingReach,
                  Stage.cellSize.y * vector.vector.y * attackingReach),
              EffectController(duration: arrowMagicMoveTime),
            ),
            RemoveEffect(delay: arrowMagicMoveTime),
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

    // プレイヤー移動終了フレームの場合
    if (playerEndMoving) {
      playerStartMovingFlag = false;
      // 攻撃終了
      // 攻撃範囲にいる敵のレベルを、ガーディアンのレベル分だけ下げる
      // レベルが0以下になった敵は消す
      if (attacking) {
        for (final p in attackingPoints) {
          final obj = stage.get(p);
          // hit()でレベルを下げる前にコイン数を取得
          int gettableCoins = obj.coins;
          if (obj.isEnemy && obj.hit(level)) {
            // 敵側の処理が残ってるかもしれないので、フレーム処理終了後に消す
            obj.removeAfterFrame();
            // コイン獲得
            stage.coins.actual += gettableCoins;
            stage.showGotCoinEffect(gettableCoins, obj.pos);
          }
        }
        attackingPoints.clear();
      }
      moving = Move.none;
      movingAmount = 0;
      pushings.clear();
      if (attacking) {
        attacking = false;
        isBowMagicAttacking = false;
        attackingReach = 5;
        // アニメーションを元に戻す
        vector = vector;
        animationComponent.size = Stage.cellSize;
        stage.setObjectPosition(this);
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
  int get maxLevel => 3;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => true;
}
