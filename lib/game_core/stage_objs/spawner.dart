import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Spawner extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'spawner.png';

  static StageObjTypeLevel tl(StageObjType type, int level) =>
      StageObjTypeLevel(type: type, level: level);

  /// 各レベルごとに出現する敵
  static final Map<int, List<StageObjTypeLevel>> spawnEnemies = {
    1: [
      tl(StageObjType.spike, 1),
      tl(StageObjType.archer, 1),
      tl(StageObjType.wizard, 1),
    ],
  };

  /// 敵を生み出すまでの間隔
  static final spawnTurn = {
    1: 5,
  };

  Spawner({
    required Image spawnerImg,
    required Image errorImg,
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
          levelToAnimations: {
            0: {
              Move.none:
                  SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
            },
            for (int i = 1; i <= spawnEnemies.keys.length; i++)
              i: {
                Move.none: SpriteAnimation.fromFrameData(
                  spawnerImg,
                  SpriteAnimationData.sequenced(
                      amount: 2,
                      stepTime: Stage.objectStepTime,
                      textureSize: Stage.cellSize),
                ),
              },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.spawner,
            level: level,
          ),
        );

  /// 最後に敵を生み出してからの経過ターン数
  int turns = 0;

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
    if (playerEndMoving) {
      if (++turns >= spawnTurn[level]!) {
        // この場所が空いているなら
        if (stage.get(pos) == this) {
          // 敵を生み出す
          final spawnTL = spawnEnemies[level]!.sample(1).first;
          stage.enemies.add(stage.createObject(typeLevel: spawnTL, pos: pos));
          turns = 0;
        }
      }
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
  bool get enemyMovable => true;

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

  @override
  bool get hasVector => false;

  // turnsの保存/読み込み
  @override
  int get arg => turns;

  @override
  void loadArg(int val) {
    turns = val;
  }
}
