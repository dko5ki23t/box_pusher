import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Swordsman extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackForward3,
    2: EnemyMovePattern.followPlayerAttackRound8,
    3: EnemyMovePattern.followPlayerAttackRound8,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'swordsman.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static String get attackDImageFileName => 'swordsman_attackD.png';
  static String get attackLImageFileName => 'swordsman_attackL.png';
  static String get attackRImageFileName => 'swordsman_attackR.png';
  static String get attackUImageFileName => 'swordsman_attackU.png';

  /// 各レベルごとの回転斬り時の画像のファイル名
  static String get roundAttackDImageFileName => 'swordsman_attack_roundD.png';
  static String get roundAttackLImageFileName => 'swordsman_attack_roundL.png';
  static String get roundAttackRImageFileName => 'swordsman_attack_roundR.png';
  static String get roundAttackUImageFileName => 'swordsman_attack_roundU.png';

  /// オブジェクトのレベル->向き->攻撃時アニメーションのマップ
  final Map<int, Map<Move, SpriteAnimation>> levelToAttackAnimations;

  /// オブジェクトのレベル->向き->回転斬り時アニメーションのマップ
  final Map<int, Map<Move, SpriteAnimation>> levelToRoundAttackAnimations;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2(0, -16.0),
    Move.down: Vector2(0, 16.0),
    Move.left: Vector2(-16.0, 0),
    Move.right: Vector2(16.0, 0)
  };

  /// 回転斬り攻撃時アニメーションのオフセット
  final Vector2 roundAttackAnimationOffset = Vector2.zero();

  /// 攻撃の1コマの時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 5;

  /// 回転斬りの1コマの時間
  static const double roundAttackStepTime = 32.0 / Stage.playerSpeed / 20;

  Swordsman({
    required Image swordsmanImg,
    required Image attackDImg,
    required Image attackLImg,
    required Image attackRImg,
    required Image attackUImg,
    required Image roundAttackDImg,
    required Image roundAttackLImg,
    required Image roundAttackRImg,
    required Image roundAttackUImg,
    required Image errorImg,
    required super.pos,
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
        levelToRoundAttackAnimations = {
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
              roundAttackDImg,
              SpriteAnimationData.sequenced(
                  amount: 20,
                  stepTime: roundAttackStepTime,
                  textureSize: Vector2.all(96.0)),
            ),
            Move.up: SpriteAnimation.fromFrameData(
              roundAttackUImg,
              SpriteAnimationData.sequenced(
                  amount: 20,
                  stepTime: roundAttackStepTime,
                  textureSize: Vector2.all(96.0)),
            ),
            Move.left: SpriteAnimation.fromFrameData(
              roundAttackLImg,
              SpriteAnimationData.sequenced(
                  amount: 20,
                  stepTime: roundAttackStepTime,
                  textureSize: Vector2.all(96.0)),
            ),
            Move.right: SpriteAnimation.fromFrameData(
              roundAttackRImg,
              SpriteAnimationData.sequenced(
                  amount: 20,
                  stepTime: roundAttackStepTime,
                  textureSize: Vector2.all(96.0)),
            ),
          },
        },
        super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.dynamicPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
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
                Sprite(swordsmanImg,
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
                Sprite(swordsmanImg,
                    srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.right: SpriteAnimation.spriteList([
                Sprite(swordsmanImg,
                    srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
                Sprite(swordsmanImg,
                    srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.up: SpriteAnimation.spriteList([
                Sprite(swordsmanImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(swordsmanImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.down: SpriteAnimation.spriteList([
                Sprite(swordsmanImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                Sprite(swordsmanImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.swordsman,
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
      // 移動/攻撃を決定
      final ret = super.enemyMove(
          movePatterns[level]!, vector, stage.player, stage, prohibitedPoints);
      if (ret.containsKey('attack') && ret['attack']!) {
        attacking = true;
        // 攻撃中のアニメーションに変更
        if (level <= 1) {
          int key = levelToAttackAnimations.containsKey(level) ? level : 0;
          animationComponent.animation = levelToAttackAnimations[key]![vector]!;
          animationComponent.size =
              animationComponent.animation!.frames.first.sprite.srcSize;
          stage.objFactory
              .setPosition(this, offset: attackAnimationOffset[vector]!);
        } else {
          int key = levelToRoundAttackAnimations.containsKey(level) ? level : 0;
          animationComponent.animation =
              levelToRoundAttackAnimations[key]![vector]!;
          animationComponent.size =
              animationComponent.animation!.frames.first.sprite.srcSize;
          stage.objFactory
              .setPosition(this, offset: roundAttackAnimationOffset);
        }
      }
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
        stage.objFactory.setPosition(this, offset: offset);
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 攻撃中ならゲームオーバー判定
        if (attacking) {
          if (level <= 1) {
            // 前方3マス
            final tmp = MoveExtent.straights;
            tmp.remove(vector);
            tmp.remove(vector.oppsite);
            final attackable = pos + vector.point;
            final attackables = [attackable];
            for (final v in tmp) {
              attackables.add(attackable + v.point);
            }
            if (attackables.contains(stage.player.pos)) {
              stage.isGameover = true;
            }
          } else if (PointRectRange((pos - Point(1, 1)), pos + Point(1, 1))
              .contains(stage.player.pos)) {
            // 回転斬りの場合は周囲8マス
            stage.isGameover = true;
          }
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
  bool get pushable => false;

  @override
  bool get stopping => true;

  @override
  bool get puttable => false;

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
}
