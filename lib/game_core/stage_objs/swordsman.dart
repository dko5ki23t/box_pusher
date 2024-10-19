import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

class Swordsman extends StageObj {
  final EnemyMovePattern movePattern = EnemyMovePattern.followPlayerAttack;

  /// 向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> vectorAnimation;

  /// 攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> attackAnimation;

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> attackAnimationOffset;

  /// 向き
  Move _vector = Move.down;

  /// 向き
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    animation.animation = vectorAnimation[_vector];
  }

  Swordsman({
    required super.animation,
    required this.vectorAnimation,
    required this.attackAnimation,
    required this.attackAnimationOffset,
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
          movePattern, vector, stage.player, stage, prohibitedPoints);
      if (ret.containsKey('attack') && ret['attack']!) {
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

    if (playerStartMoving) {
      // 移動し始めのフレームの場合
      playerStartMovingFlag = true;
      // 向いている方向の3マスにプレイヤーがいるなら攻撃
      final tmp = MoveExtent.straights;
      tmp.remove(vector);
      tmp.remove(vector.oppsite);
      final attackable = pos + vector.point;
      final attackables = [attackable];
      for (final v in tmp) {
        attackables.add(attackable + v.point);
      }
      if (attackables.contains(stage.player.pos)) {
        attacking = true;
        // 攻撃中のアニメーションに変更
        animation.animation = attackAnimation[vector]!;
        animation.size = animation.animation!.frames.first.sprite.srcSize;
        stage.objFactory
            .setPosition(this, offset: attackAnimationOffset[vector]!);
      } else {
        // 今プレイヤーの移動先にいるなら移動しない
        if (pos == stage.player.pos + stage.player.moving.point) {
          moving = Move.none;
        } else {
          // プレイヤーの方へ移動する/向きを変える
          final delta = stage.player.pos - pos;
          final List<Move> tmpCand = [];
          if (delta.x > 0) {
            tmpCand.add(Move.right);
          } else if (delta.x < 0) {
            tmpCand.add(Move.left);
          }
          if (delta.y > 0) {
            tmpCand.add(Move.down);
          } else if (delta.y < 0) {
            tmpCand.add(Move.up);
          }
          final List<Move> cand = [];
          for (final move in tmpCand) {
            Point eTo = pos + move.point;
            final eToObj = stage.getObject(eTo);
            if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
                stage.player.pushings.isNotEmpty &&
                stage.player.pushings.first.pos == eTo) {
              // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
            } else if (!eToObj.puttable && eToObj.typeLevel != typeLevel) {
              continue;
            }
            if (prohibitedPoints.contains(eTo)) {
              continue;
            }
            cand.add(move);
          }
          if (cand.isNotEmpty) {
            moving = cand.sample(1).first;
            // 向きも変更
            vector = moving;
            // 自身の移動先は、他のオブジェクトの移動先にならないようにする
            prohibitedPoints.add(pos + moving.point);
          } else if (tmpCand.isNotEmpty) {
            // 向きだけ変更
            vector = tmpCand.sample(1).first;
          }
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
        stage.objFactory.setPosition(this, offset: offset);
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 攻撃中ならゲームオーバー判定
        if (attacking &&
            stage.player.pos.x >= pos.x - 1 &&
            stage.player.pos.x <= pos.x + 1 &&
            stage.player.pos.y >= pos.y - 1 &&
            stage.player.pos.y <= pos.y + 1) {
          stage.isGameover = true;
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
