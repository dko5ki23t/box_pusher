import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Bomb extends StageObj {
  Bomb({
    required super.animationComponent,
    required super.levelToAnimations,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.bomb,
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
    // プレイヤー位置がボムの周囲5×5マスより遠い位置なら爆発
    if ((stage.player.pos.x < pos.x - 2) ||
        (stage.player.pos.x > pos.x + 2) ||
        (stage.player.pos.y < pos.y - 2) ||
        (stage.player.pos.y > pos.y + 2)) {
      // 爆発アニメ表示
      gameWorld.add(stage.objFactory.createExplodingBomb(pos));
      // 爆発
      stage.merge(
        pos,
        this,
        gameWorld,
        breakLeftOffset: -2,
        breakTopOffset: -2,
        breakRightOffset: 2,
        breakBottomOffset: 2,
        onlyDelete: true,
      );
    }
  }

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 20;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;
}
