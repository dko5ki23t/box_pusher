import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Shop extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'shop.png';

  /// ショップの交換情報
  late final ShopInfo shopInfo;

  /// レベル1:たぬき,レベル2:葉っぱマーク,レベル3:矢印,レベル4:星マーク
  Shop({
    required Image shopImg,
    required Image errorImg,
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
            1: {
              Move.none: SpriteAnimation.spriteList(
                [
                  Sprite(shopImg,
                      srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                  Sprite(shopImg,
                      srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
                ],
                stepTime: Stage.objectStepTime,
              ),
            },
            2: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(shopImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize)
              ], stepTime: 1.0),
            },
            3: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(shopImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
              ], stepTime: 1.0),
            },
            4: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(shopImg,
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize)
              ], stepTime: 1.0),
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.shop,
            level: level,
          ),
        ) {
    // ショップ情報を取得
    for (final entry in Config().shopInfoMap.entries) {
      final shopPos = entry.key;
      if ([
        shopPos,
        shopPos + Point(-1, 1),
        shopPos + Point(0, 1),
        shopPos + Point(1, 1),
      ].contains(pos)) {
        shopInfo = entry.value;
      }
      return;
    }
    throw ('[Shop]位置に該当するショップ情報がありません');
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
  bool get pushable => false;

  @override
  bool get stopping => level == 1;

  @override
  bool get puttable => level > 1;

  @override
  bool get enemyMovable => level > 1;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 4;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => false;

  /// 支払いをする場所か
  bool get isPayPlace => level == 2;

  /// 交換で手に入るオブジェクトが出現する場所か
  bool get isItemPlace => level == 4;
}
