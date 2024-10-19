import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Guardian extends StageObj {
  Guardian({
    required super.animation,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.guardian,
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
    // 周囲8マスに敵がいる場合、ガーディアンのレベル分だけその敵のレベルを下げる(ただし1体だけ)
    // レベルが0以下になった敵は消す
    bool attacked = false;
    for (int y = pos.y - 1; y <= pos.y + 1; y++) {
      for (int x = pos.x - 1; x <= pos.x + 1; x++) {
        final obj = stage.getObject(Point(x, y));
        if (obj.isEnemy && obj.killable) {
          obj.typeLevel.level -= typeLevel.level;
          if (obj.typeLevel.level <= 0) {
            gameWorld.remove(obj.animation);
            stage.enemies.remove(obj);
            attacked = true;
            break;
          }
        }
      }
      if (attacked) break;
    }
  }

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get mergable => typeLevel.level < maxLevel;

  @override
  int get maxLevel => 20;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;
}
