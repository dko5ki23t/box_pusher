import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Swordsman extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackForward3,
    2: EnemyMovePattern.followPlayerAttackRound8,
    3: EnemyMovePattern.followPlayerAttackRound8,
  };

  /// 向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> vectorAnimation;

  /// 攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> attackAnimation;

  /// 回転斬り攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> roundAttackAnimation;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset;

  /// 回転斬り攻撃時アニメーションのオフセット
  final Vector2 roundAttackAnimationOffset;

  /// 向き
  Move _vector = Move.down;

  /// 向き
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    animationComponent.animation = vectorAnimation[_vector];
  }

  Swordsman({
    required super.animationComponent,
    required this.vectorAnimation,
    required this.attackAnimation,
    required this.roundAttackAnimation,
    required this.attackAnimationOffset,
    required this.roundAttackAnimationOffset,
    required super.levelToAnimations,
    required super.pos,
    int level = 1,
  }) : super(
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
          animationComponent.animation = attackAnimation[vector]!;
          animationComponent.size =
              animationComponent.animation!.frames.first.sprite.srcSize;
          stage.objFactory
              .setPosition(this, offset: attackAnimationOffset[vector]!);
        } else {
          animationComponent.animation = roundAttackAnimation[vector]!;
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
