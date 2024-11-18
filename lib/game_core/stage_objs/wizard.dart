import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Wizard extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackStraight5,
    2: EnemyMovePattern.followPlayerAttackStraight5,
    3: EnemyMovePattern.followPlayerAttackStraight5,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'wizard.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static String get attackImageFileName => 'wizard_attack.png';

  /// 各レベルごとの魔法の画像のファイル名
  static String get magicImageFileName => 'magic.png';

  /// オブジェクトのレベル->向き->攻撃時アニメーションのマップ
  final Map<int, Map<Move, SpriteAnimation>> levelToAttackAnimations;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2.zero(),
    Move.down: Vector2.zero(),
    Move.left: Vector2.zero(),
    Move.right: Vector2.zero(),
  };

  /// 魔法のアニメーション
  final SpriteAnimation magicAnimation;

  /// 攻撃時の1コマ時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 魔法アニメーションの1コマ時間
  static const double magicStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 魔法が飛ぶ時間
  static final magicMoveTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  Wizard({
    required Image wizardImg,
    required Image attackImg,
    required Image magicImg,
    required Image errorImg,
    required super.pos,
    int level = 1,
  })  : magicAnimation = SpriteAnimation.spriteList([
          Sprite(magicImg, srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
          Sprite(magicImg,
              srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
        ], stepTime: magicStepTime),
        levelToAttackAnimations = {
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
            Move.down: SpriteAnimation.spriteList([
              Sprite(attackImg,
                  srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.up: SpriteAnimation.spriteList([
              Sprite(attackImg,
                  srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.left: SpriteAnimation.spriteList([
              Sprite(attackImg,
                  srcPosition: Vector2(256, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(288, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(320, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(352, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
            Move.right: SpriteAnimation.spriteList([
              Sprite(attackImg,
                  srcPosition: Vector2(384, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(416, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(448, 0), srcSize: Stage.cellSize),
              Sprite(attackImg,
                  srcPosition: Vector2(480, 0), srcSize: Stage.cellSize),
            ], stepTime: attackStepTime),
          },
        },
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
                Sprite(wizardImg,
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
                Sprite(wizardImg,
                    srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.right: SpriteAnimation.spriteList([
                Sprite(wizardImg,
                    srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
                Sprite(wizardImg,
                    srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.up: SpriteAnimation.spriteList([
                Sprite(wizardImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(wizardImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.down: SpriteAnimation.spriteList([
                Sprite(wizardImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                Sprite(wizardImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.wizard,
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
        int key = levelToAttackAnimations.containsKey(level) ? level : 0;
        animationComponent.animation = levelToAttackAnimations[key]![vector]!;
        animationComponent.size =
            animationComponent.animation!.frames.first.sprite.srcSize;
        stage.objFactory
            .setPosition(this, offset: attackAnimationOffset[vector]!);
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
        stage.objFactory.setPosition(this, offset: offset);
        // ※※※画像の移動ここまで※※※
      }

      // 移動完了の半分時点を過ぎたら、矢のアニメーション追加
      if (attacking &&
          prevMovingAmount < Stage.cellSize.x / 2 &&
          movingAmount >= Stage.cellSize.x / 2) {
        gameWorld.add(SpriteAnimationComponent(
          animation: magicAnimation,
          priority: Stage.movingPriority,
          children: [
            MoveEffect.by(
              Vector2(Stage.cellSize.x * vector.vector.x * 5,
                  Stage.cellSize.y * vector.vector.y * 5),
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
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        } else if (attacking) {
          // 前方直線5マスに攻撃
          if (PointRectRange(pos, pos + vector.point * 5)
              .contains(stage.player.pos)) {
            stage.isGameover = stage.player.hit();
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
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 20;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;
}
