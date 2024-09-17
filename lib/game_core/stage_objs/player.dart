import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Player extends StageObj {
  Player({
    required super.sprite,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.player,
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
    if (moving == Move.none) {
      // 移動中でない場合
      // 移動先の座標
      Point to = pos + moveInput.point;
      // 押すオブジェクトの移動先の座標
      Point toTo = to + moveInput.point;
      if (moveInput == Move.none) {
        return;
      }
      final toObj = stage.get(to);
      final toToObj = stage.get(toTo);

      // 壁にぶつかるか
      if (toObj.type == StageObjType.wall) {
        return;
      }

      // 荷物があるか
      if (toObj.type == StageObjType.box ||
          toObj.type == StageObjType.boxOnGoal) {
        if (toToObj.type != StageObjType.none &&
            toToObj.type != StageObjType.goal &&
            toToObj.type != StageObjType.box) {
          return;
        }
        if (toToObj.type == StageObjType.box && toToObj.level != toObj.level) {
          return;
        }
        pushing = stage.boxes.firstWhere((element) => element.pos == to);
        // 箱の移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints.add(toTo);
      }
      moving = moveInput;
      movingAmount = 0.0;
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
      // プレイヤー位置変更
      stage.objFactory.setPosition(this, offset: offset);
      // TODO: 箱の方に実装？
      if (pushing != null) {
        // 押している箱の位置変更
        stage.objFactory.setPosition(pushing!, offset: offset);
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        Point to = pos + moving.point;
        Point toTo = to + moving.point;
        // プレーヤー位置更新
        // ※explode()より前で更新することで、敵出現位置を、プレイヤーの目前にさせない
        pos = to.copy();
        stage.objFactory.setPosition(this);

        // 荷物位置更新
        // TODO:箱の方に実装？
        if (pushing != null) {
          switch (stage.get(toTo).type) {
            case StageObjType.none:
              stage.setType(toTo, StageObjType.box,
                  level: pushing!.typeLevel.level);
              break;
            case StageObjType.goal:
              stage.setType(toTo, StageObjType.boxOnGoal,
                  level: pushing!.typeLevel.level);
              break;
            case StageObjType.box:
              stage.explode(toTo, pushing!, gameWorld);
              stage.setType(toTo, StageObjType.box,
                  level: pushing!.typeLevel.level);
              break;
            default:
              // ありえない
              //HALT("fatal error");
              break;
          }
          switch (stage.get(to).type) {
            case StageObjType.box:
              stage.setType(to, StageObjType.none);
              break;
            case StageObjType.boxOnGoal:
              stage.setType(to, StageObjType.goal);
              break;
            default:
              // ありえない
              //HALT("fatal error");
              break;
          }
          pushing!.pos = toTo;
          stage.objFactory.setPosition(pushing!);
          pushing = null;
        }

        // 各種移動中変数初期化
        moving = Move.none;
        pushing = null;
        movingAmount = 0;
      }
    }
  }
}
