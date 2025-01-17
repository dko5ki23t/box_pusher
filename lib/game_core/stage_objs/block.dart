import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Block extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'block.png';

  /// ブロック破壊時アニメーション
  final Map<int, SpriteAnimation> breakingAnimations;

  Block({
    required Image blockImg,
    required Image errorImg,
    required super.savedArg,
    required super.pos,
    int level = 1,
  })  : breakingAnimations = {
          0: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
          for (int i = 0; i < 4; i++)
            i + 1: SpriteAnimation.spriteList([
              Sprite(blockImg,
                  srcPosition: Vector2(128 + i * 32, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: 1.0),
          // ここからは敵が生み出すブロック
          for (int i = 0; i < 3; i++)
            i + 101: SpriteAnimation.spriteList([
              Sprite(blockImg,
                  srcPosition: Vector2(352 + i * 32, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: 1.0),
        },
        super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.staticPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: {
            0: {
              Move.none:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            },
            for (int i = 0; i < 4; i++)
              i + 1: {
                Move.none: SpriteAnimation.spriteList([
                  Sprite(blockImg,
                      srcPosition: Vector2(i * 32, 0), srcSize: Stage.cellSize)
                ], stepTime: 1.0),
              },
            // ここからは敵が生み出すブロック
            for (int i = 0; i < 3; i++)
              i + 101: {
                Move.none: SpriteAnimation.spriteList([
                  Sprite(blockImg,
                      srcPosition: Vector2(256 + i * 32, 0),
                      srcSize: Stage.cellSize)
                ], stepTime: 1.0),
              },
          },
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
    bool playerEndMoving,
    Map<Point, Move> prohibitedPoints,
  ) {}

  SpriteAnimationComponent createBreakingBlock() {
    int key = breakingAnimations.containsKey(level) ? level : 0;
    final animation = breakingAnimations[key]!;
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
  bool get enemyMovable => false;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 103;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;

  @override
  bool get hasVector => false;
}
