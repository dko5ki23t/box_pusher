import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

class Swordsman extends StageObj {
  final EnemyMovePattern movePattern = EnemyMovePattern.followPlayerAttack;
  final SpriteAnimation leftAnimation;
  final SpriteAnimation rightAnimation;
  final SpriteAnimation upAnimation;
  final SpriteAnimation downAnimation;
  final SpriteAnimation leftAttackAnimation;
  final SpriteAnimation rightAttackAnimation;
  final SpriteAnimation upAttackAnimation;
  final SpriteAnimation downAttackAnimation;

  /// 向き
  Move _vector = Move.down;

  /// 向き
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    switch (_vector) {
      case Move.left:
        animation.animation = leftAnimation;
        break;
      case Move.right:
        animation.animation = rightAnimation;
        break;
      case Move.up:
        animation.animation = upAnimation;
        break;
      case Move.down:
      default:
        animation.animation = downAnimation;
        break;
    }
  }

  Swordsman({
    required super.animation,
    required this.leftAnimation,
    required this.rightAnimation,
    required this.upAnimation,
    required this.downAnimation,
    required this.leftAttackAnimation,
    required this.rightAttackAnimation,
    required this.upAttackAnimation,
    required this.downAttackAnimation,
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
        switch (vector) {
          case Move.left:
            animation.animation = leftAttackAnimation;
            animation.size = Vector2(64.0, 96.0);
            stage.objFactory.setPosition(this, offset: Vector2(-16.0, 0));
            break;
          case Move.right:
            animation.animation = rightAttackAnimation;
            animation.size = Vector2(64.0, 96.0);
            stage.objFactory.setPosition(this, offset: Vector2(16.0, 0));
            break;
          case Move.up:
            animation.animation = upAttackAnimation;
            animation.size = Vector2(96.0, 64.0);
            stage.objFactory.setPosition(this, offset: Vector2(0, -16.0));
            break;
          case Move.down:
          default:
            animation.animation = downAttackAnimation;
            animation.size = Vector2(96.0, 64.0);
            stage.objFactory.setPosition(this, offset: Vector2(0, 16.0));
            break;
        }
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
