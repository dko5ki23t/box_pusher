import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Wizard extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackStraight3,
    2: EnemyMovePattern.followPlayerAttackStraight5,
    3: EnemyMovePattern.followWarpPlayerAttackStraight5,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'wizard.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static List<String> get attackImageFileNames =>
      ['wizard_attack1.png', 'wizard_attack2.png', 'wizard_attack3.png'];

  /// 各レベルごとの魔法の画像のファイル名
  static String get magicImageFileName => 'magic.png';

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2.zero(),
    Move.down: Vector2.zero(),
    Move.left: Vector2.zero(),
    Move.right: Vector2.zero(),
  };

  /// 魔法のアニメーション
  final List<SpriteAnimation> magicAnimations;

  /// 攻撃時の1コマ時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 魔法アニメーションの1コマ時間
  static const double magicStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 魔法が飛ぶ時間
  static final magicMoveTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  /// ワープ中に変形する時間
  static final warpTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  Wizard({
    required Image wizardImg,
    required List<Image> attackImgs,
    required Image magicImg,
    required Image errorImg,
    required super.savedArg,
    required super.pos,
    int level = 1,
  })  : magicAnimations = [
          for (int i = 1; i <= 3; i++)
            SpriteAnimation.spriteList([
              Sprite(magicImg,
                  srcPosition: Vector2((i - 1) * 64 + 0, 0),
                  srcSize: Stage.cellSize),
              Sprite(magicImg,
                  srcPosition: Vector2((i - 1) * 64 + 32, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: magicStepTime)
        ],
        super(
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
            for (int i = 1; i <= 3; i++)
              i: {
                Move.left: SpriteAnimation.spriteList([
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 128, 0),
                      srcSize: Stage.cellSize),
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 160, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 192, 0),
                      srcSize: Stage.cellSize),
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 224, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 64, 0),
                      srcSize: Stage.cellSize),
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 96, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.down: SpriteAnimation.spriteList([
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 0, 0),
                      srcSize: Stage.cellSize),
                  Sprite(wizardImg,
                      srcPosition: Vector2((i - 1) * 256 + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          levelToAttackAnimations: {
            1: {
              0: {
                for (final move in MoveExtent.straights)
                  move: SpriteAnimation.spriteList([Sprite(errorImg)],
                      stepTime: 1.0),
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
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.wizard,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// 魔法の飛距離
  int get magicReach {
    int ret = 5;
    if (movePatterns[level]! == EnemyMovePattern.followPlayerAttackStraight3) {
      ret = 3;
    }
    return ret;
  }

  /// ワープ先座標
  Point? warpTo;

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
      if (ret.containsKey('warp')) {
        warpTo = ret['warp'] as Point;
        // ワープエフェクト追加
        animationComponent.add(SizeEffect.to(
            Vector2(Stage.cellSize.x / 3, Stage.cellSize.y),
            EffectController(duration: warpTime)));
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

      // 移動完了の半分時点を過ぎたら
      if (prevMovingAmount < Stage.cellSize.x / 2 &&
          movingAmount >= Stage.cellSize.x / 2) {
        if (attacking) {
          // 魔法のアニメーション追加
          gameWorld.add(SpriteAnimationComponent(
            animation: magicAnimations[level - 1],
            priority: Stage.movingPriority,
            children: [
              MoveEffect.by(
                Vector2(Stage.cellSize.x * vector.vector.x * magicReach,
                    Stage.cellSize.y * vector.vector.y * magicReach),
                EffectController(duration: magicMoveTime),
              ),
              RemoveEffect(delay: magicMoveTime),
            ],
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2,
          ));
        } else if (warpTo != null) {
          // 見かけ上の位置を変更
          stage.setObjectPosition(this,
              offset: (warpTo! - pos).toVector() * Stage.cellSize.x);
          // ワープ完了までのエフェクト追加
          animationComponent.add(SizeEffect.to(
              Stage.cellSize, EffectController(duration: warpTime)));
        }
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // ワープによる移動
        if (warpTo != null) {
          pos = warpTo!.copy();
          stage.setObjectPosition(this);
          warpTo = null;
        }
        // 移動後に関する処理
        endMoving(stage, gameWorld);
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        } else if (attacking) {
          // 前方直線に攻撃
          stage.addEnemyAttackDamage(level,
              PointLineRange(pos + vector.point, vector, magicReach).set);
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
  int get coins => (level * 2.5).floor();
}
