import 'package:box_pusher/components/rounded_component.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';

class Girl extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'girl.png';

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
      1: {
        Move.none: SpriteAnimation.fromFrameData(
          baseImg,
          SpriteAnimationData.sequenced(
              amount: 2,
              stepTime: Stage.objectStepTime,
              textureSize: girlImgSize),
        ),
      },
    };
  }

  /// 「Help」の吹き出し
  late final RoundedComponent talkBubble;

  final Blink bubbleBlink = Blink(showDuration: 1.5, hideDuration: 1.5);

  static Vector2 girlImgSize = Vector2(40, 40);

  Girl({
    required super.pos,
    required super.savedArg,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.staticPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.girl,
            level: level,
          ),
        ) {
    talkBubble = RoundedComponent(
      size: Vector2(Stage.cellSize.x * 3, Stage.cellSize.y * 0.8),
      cornerRadius: 25,
      color: const Color(0xc0ffffff),
      position: Vector2(pos.x * Stage.cellSize.x + Stage.cellSize.x * 0.5,
          (pos.y - 1) * Stage.cellSize.y + Stage.cellSize.y * 0.5),
      anchor: Anchor.center,
      priority: Stage.frontPriority,
      children: [
        AlignComponent(
            alignment: Anchor.center,
            child: TextComponent(
              text: 'HELP!',
              textRenderer: TextPaint(
                style: Config.gameTextStyle,
              ),
            )),
      ],
    );
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
    bubbleBlink.update(dt);
    bool alreadyContains = gameWorld.contains(talkBubble);
    if (!alreadyContains && bubbleBlink.isShowTime) {
      gameWorld.add(talkBubble);
    } else if (alreadyContains && !bubbleBlink.isShowTime) {
      gameWorld.remove(talkBubble);
    }
  }

  @override
  void onRemove(World gameWorld) {
    if (gameWorld.contains(talkBubble)) {
      gameWorld.remove(talkBubble);
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get playerMovable => true;

  @override
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => false;

  @override
  bool get isAnimals => true;
}
