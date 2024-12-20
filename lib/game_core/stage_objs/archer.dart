import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Archer extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackStraight5,
    2: EnemyMovePattern.followPlayerAttackStraight5,
    3: EnemyMovePattern.followPlayerAttackStraight5,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'archer.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static List<String> get attackImageFileNames =>
      ['archer_attack1.png', 'archer_attack2.png', 'archer_attack3.png'];

  /// 各レベルごとの矢の画像のファイル名
  static String get arrowImageFileName => 'arrow.png';

  /// オブジェクトのレベル->向き->攻撃時アニメーションのマップ
  final Map<int, Map<Move, SpriteAnimation>> levelToAttackAnimations;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2.zero(),
    Move.down: Vector2.zero(),
    Move.left: Vector2.zero(),
    Move.right: Vector2.zero(),
  };

  /// 矢のアニメーション
  final List<SpriteAnimation> arrowAnimations;

  /// 攻撃時の1コマ時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 4;

  /// 矢が飛ぶ時間
  static final arrowMoveTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  Archer({
    required super.pos,
    required Image levelToAnimationImg,
    required List<Image> levelToAttackAnimationImgs,
    required Image arrowImg,
    required Image errorImg,
    int level = 1,
  })  : arrowAnimations = [
          for (int i = 1; i <= 3; i++)
            SpriteAnimation.spriteList([
              Sprite(arrowImg,
                  srcPosition: Vector2((i - 1) * 32, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: 1.0)
        ],
        levelToAttackAnimations = {
          0: {
            for (final move in MoveExtent.straights)
              move:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
          },
          for (int i = 1; i <= 3; i++)
            i: {
              Move.down: SpriteAnimation.spriteList([
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
              ], stepTime: attackStepTime),
              Move.up: SpriteAnimation.spriteList([
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
              ], stepTime: attackStepTime),
              Move.left: SpriteAnimation.spriteList([
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(256, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(288, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(320, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(352, 0), srcSize: Stage.cellSize),
              ], stepTime: attackStepTime),
              Move.right: SpriteAnimation.spriteList([
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(384, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(416, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
                    srcPosition: Vector2(448, 0), srcSize: Stage.cellSize),
                Sprite(levelToAttackAnimationImgs[i - 1],
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
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
            },
            for (int i = 1; i <= 3; i++)
              i: {
                Move.left: SpriteAnimation.spriteList([
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 128, 0),
                      srcSize: Stage.cellSize),
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 160, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 192, 0),
                      srcSize: Stage.cellSize),
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 224, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 64, 0),
                      srcSize: Stage.cellSize),
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 96, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.down: SpriteAnimation.spriteList([
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 0, 0),
                      srcSize: Stage.cellSize),
                  Sprite(levelToAnimationImg,
                      srcPosition: Vector2((i - 1) * 256 + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.archer,
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
    // 移動し始めのフレームの場合
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
        stage.setObjectPosition(this, offset: attackAnimationOffset[vector]!);
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
        stage.setObjectPosition(this, offset: offset);
        // ※※※画像の移動ここまで※※※
      }

      // 移動完了の半分時点を過ぎたら、矢のアニメーション追加
      if (attacking &&
          prevMovingAmount < Stage.cellSize.x / 2 &&
          movingAmount >= Stage.cellSize.x / 2) {
        double angle = 0;
        switch (vector) {
          case Move.left:
            angle = 0.5 * pi;
            break;
          case Move.right:
            angle = -0.5 * pi;
            break;
          case Move.up:
            angle = pi;
            break;
          default:
            break;
        }
        gameWorld.add(SpriteAnimationComponent(
          animation: arrowAnimations[level - 1],
          priority: Stage.movingPriority,
          children: [
            MoveEffect.by(
              Vector2(Stage.cellSize.x * vector.vector.x * 5,
                  Stage.cellSize.y * vector.vector.y * 5),
              EffectController(duration: arrowMoveTime),
            ),
            RemoveEffect(delay: arrowMoveTime),
          ],
          size: Stage.cellSize,
          anchor: Anchor.center,
          angle: angle,
          position:
              Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                  Stage.cellSize / 2,
        ));
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
          stage.setObjectPosition(this);
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
