import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Jewel extends StageObj {
  Jewel({
    required super.animationComponent,
    required super.levelToAnimations,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.jewel,
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

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'jewels.png';

  /// レベル->アニメーションのマップ
  static Map<int, SpriteAnimation> levelToAnimation(Image img) {
    final Map<int, SpriteAnimation> ret = {};
    for (int i = 0; i < 14; i++) {
      ret[i + 1] = SpriteAnimation.spriteList([
        Sprite(img, srcPosition: Vector2(i * 32, 0), srcSize: Stage.cellSize)
      ], stepTime: 1.0);
    }
    return ret;
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
