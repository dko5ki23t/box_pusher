import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Drill extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'drill.png';

  Drill({
    required Image drillImg,
    required Image errorImg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  }) : super(
          vector: Move.up,
          animationComponent: SpriteAnimationComponent(
            priority: Stage.dynamicPriority,
            size: Stage.cellSize,
            scale: scale,
            anchor: Anchor.center,
            children: [scaleEffect],
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: {
            0: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
            },
            1: {
              for (final move in MoveExtent.straights)
                move: SpriteAnimation.spriteList([
                  Sprite(drillImg,
                      srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
                ], stepTime: 1.0),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.drill,
            level: level,
          ),
        ) {
    vectorToAnimationAngles = {
      Move.up: 0,
      Move.down: pi,
      Move.left: -0.5 * pi,
      Move.right: 0.5 * pi,
    };
  }

  @override
  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    bool playerEndMoving,
    Map<Point, Move> prohibitedPoints,
  ) {}

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get enemyMovable => false;

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

  @override
  bool get hasVector => true;
}
