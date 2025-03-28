import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Block extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'block.png';

  /// 破壊不能ブロックのレベル
  static const int unbreakableLevel = 50;

  /// ブロック破壊時アニメーション（staticにして唯一つ保持、メモリ節約）
  static Map<int, SpriteAnimation> breakingAnimations = {};

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    levelToAnimationsS = {
      0: {
        Move.none:
            SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      for (int i = 0; i < 4; i++)
        i + 1: {
          Move.none: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(i * 32, 0), srcSize: Stage.cellSize)
          ], stepTime: 1.0),
        },
      // ここからは敵が生み出すブロック
      for (int i = 0; i < 3; i++)
        i + 101: {
          Move.none: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(256 + i * 32, 0), srcSize: Stage.cellSize)
          ], stepTime: 1.0),
        },
    };
    breakingAnimations = {
      0: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      for (int i = 0; i < 4; i++)
        i + 1: SpriteAnimation.spriteList([
          Sprite(baseImg,
              srcPosition: Vector2(128 + i * 32, 0), srcSize: Stage.cellSize),
        ], stepTime: 1.0),
      // ここからは敵が生み出すブロック
      for (int i = 0; i < 3; i++)
        i + 101: SpriteAnimation.spriteList([
          Sprite(baseImg,
              srcPosition: Vector2(352 + i * 32, 0), srcSize: Stage.cellSize),
        ], stepTime: 1.0),
    };
  }

  Block({
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            key: GameUniqueKey('Block'),
            priority: Stage.staticPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
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
  bool get playerMovable => false;

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
