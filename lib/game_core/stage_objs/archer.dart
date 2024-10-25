import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Archer extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackStraight5,
    2: EnemyMovePattern.followPlayerAttackStraight5,
    3: EnemyMovePattern.followPlayerAttackStraight5,
  };

  /// 向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> vectorAnimation;

  /// 攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> attackAnimation;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset;

  /// 矢のアニメーション
  final SpriteAnimation arrowAnimation;

  /// 矢が飛ぶ時間
  static final arrowMoveTime = Stage.cellSize.x / 2 / Stage.playerSpeed;

  /// 向き
  Move _vector = Move.down;

  /// 向き
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    animation.animation = vectorAnimation[_vector];
  }

  Archer({
    required super.animation,
    required this.vectorAnimation,
    required this.attackAnimation,
    required this.attackAnimationOffset,
    required this.arrowAnimation,
    required super.pos,
    int level = 1,
  }) : super(
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
    List<Point> prohibitedPoints,
  ) {
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      playerStartMovingFlag = true;
      // 移動/攻撃を決定
      final ret = super.enemyMove(movePatterns[typeLevel.level]!, vector,
          stage.player, stage, prohibitedPoints);
      if (ret.containsKey('attack') && ret['attack']!) {
        attacking = true;
        // 攻撃中のアニメーションに変更
        animation.animation = attackAnimation[vector]!;
        animation.size = animation.animation!.frames.first.sprite.srcSize;
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
          animation: arrowAnimation,
          priority: Stage.dynamicPriority,
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
        // 攻撃中ならゲームオーバー判定
        if (attacking) {
          // 前方直線5マス
          if (PointRectRange(pos, pos + vector.point * 5)
              .contains(stage.player.pos)) {
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
          animation.size = Stage.cellSize;
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
  bool get mergable => typeLevel.level < maxLevel;

  @override
  int get maxLevel => 20;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;
}
