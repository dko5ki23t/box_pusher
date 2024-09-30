import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

class Spike extends StageObj {
  final EnemyMovePattern movePattern = EnemyMovePattern.walkRandomOrStop;

  Spike({
    required super.animation,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.spike,
            level: level,
          ),
        );

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
      // 移動を決定する
      final List<Move> cand = [];
      // 今プレイヤーの移動先にいるなら移動しない
      if (pos == stage.player.pos + stage.player.moving.point) {
        cand.add(Move.none);
      } else {
        for (final move in Move.values) {
          Point eTo = pos + move.point;
          if (move == Move.none) {
            if (movePattern == EnemyMovePattern.walkRandomOrStop) {
              cand.add(move);
            }
            continue;
          }
          final eToObj = stage.get(eTo);
          if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
              stage.player.pushings.isNotEmpty &&
              stage.player.pushings.first.pos == eTo) {
            // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
          } else if (eToObj.type == StageObjType.wall ||
              eToObj.type == StageObjType.box ||
              (eToObj.type == StageObjType.spike &&
                  eToObj.level != typeLevel.level)) {
            continue;
          }
          if (prohibitedPoints.contains(eTo)) {
            continue;
          }
          cand.add(move);
        }
      }
      if (cand.isNotEmpty) {
        moving = cand.sample(1).first;
        // 自身の移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints.add(pos + moving.point);
      }
      movingAmount = 0;
    }

    if (moving != Move.none) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      Vector2 offset = moving.vector * movingAmount;
      stage.objFactory.setPosition(this, offset: offset);
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
      }
    }
  }
}
