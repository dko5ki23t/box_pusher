import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class TreasureBox extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'treasure_box.png';

  /// 各レベルごとで得られるコイン
  static final Map<int, int> levelToCoins = {
    1: 50,
    2: 100,
    3: 200,
    4: 150,
    5: 80,
    6: 200,
    7: 200,
    8: 150,
    9: 300,
  };

  /// 各レベルごとで得られるスコア
  static final Map<int, int> levelToScore = {
    1: 5000,
    2: 50000,
    3: 50000,
    4: 100000,
    5: 8000,
    6: 100000,
    7: 100000,
    8: 75000,
    9: 200000,
  };

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
      for (int i = 1; i <= levelToCoins.keys.length; i++)
        i: {
          Move.none: SpriteAnimation.fromFrameData(
            baseImg,
            SpriteAnimationData.sequenced(
                amount: 2,
                stepTime: Stage.objectStepTime,
                textureSize: Stage.cellSize),
          ),
        },
    };
  }

  TreasureBox({
    required super.savedArg,
    required super.pos,
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
            type: StageObjType.treasureBox,
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
  bool get mergable => false;

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
  int get coins => levelToCoins[level]!;

  @override
  int get score => levelToScore[level]!;
}
