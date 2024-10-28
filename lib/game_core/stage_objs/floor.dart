import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Floor extends StageObj {
  Floor({
    required super.animationComponent,
    required super.levelToAnimations,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.none,
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
  ) {}

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => true;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;
}
