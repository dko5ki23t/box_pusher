import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Trap extends StageObj {
  Trap({
    required super.sprite,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.trap,
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
    // このオブジェクトと同じ位置の敵を消す
    final killings =
        stage.enemies.where((element) => element.pos == pos).toList();
    for (final killing in killings) {
      gameWorld.remove(killing.sprite);
      stage.enemies.remove(killing);
    }
  }
}
