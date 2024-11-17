import 'package:box_pusher/audio.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Trap extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'trap.png';

  Trap({
    required Image trapImg,
    required Image errorImg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  }) : super(
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
              Move.none:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            },
            1: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(trapImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
              ], stepTime: 1.0)
            },
            2: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(trapImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize)
              ], stepTime: 1.0)
            },
            3: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(trapImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(trapImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
              ], stepTime: Stage.objectStepTime)
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.trap,
            level: level,
          ),
        ) {
    vector = Move.none;
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
  ) {
    // このオブジェクトと同じ位置の、罠レベル以下の敵を消す
    if (playerEndMoving) {
      final killings = stage.enemies
          .where((element) => element.pos == pos && element.level <= level)
          .toList();
      for (final killing in killings) {
        gameWorld.remove(killing.animationComponent);
        stage.enemies.remove(killing);
        // 効果音を鳴らす
        switch (level) {
          default:
            Audio.playSound(Sound.trap1);
            break;
        }
      }
    }
  }

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get enemyMovable => true;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;
}
