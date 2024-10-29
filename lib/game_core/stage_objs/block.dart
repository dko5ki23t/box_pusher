import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Block extends StageObj {
  /// ブロック破壊時アニメーション
  final Map<int, SpriteAnimation> breakingAnimations;

  Block({
    required super.animationComponent,
    required super.levelToAnimations,
    required this.breakingAnimations,
    required super.pos,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.block,
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

  SpriteAnimationComponent createBreakingBlock() {
    // TODO:nullならエラー画像
    final animation = breakingAnimations[level];
    return SpriteAnimationComponent(
      animation: animation,
      priority: Stage.dynamicPriority,
      children: [
        OpacityEffect.by(
          -1.0,
          EffectController(duration: 0.5),
        ),
        RemoveEffect(delay: 1.0),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => true;

  @override
  bool get puttable => false;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;
}
