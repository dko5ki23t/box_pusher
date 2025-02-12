import 'package:box_pusher/components/rounded_component.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';

class Shop extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'shop.png';

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
        Move.none: SpriteAnimation.spriteList(
          [
            Sprite(baseImg,
                srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
          ],
          stepTime: Stage.objectStepTime,
        ),
      },
      2: {
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(64, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
      },
      3: {
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
      },
      4: {
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(128, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
      },
    };
  }

  /// ショップの交換情報
  late final ShopInfo shopInfo;

  /// ショップ情報の吹き出し
  RoundedComponent? infoBubble;

  /// レベル1:たぬき,レベル2:葉っぱマーク,レベル3:矢印,レベル4:星マーク
  Shop({
    required super.savedArg,
    required super.pos,
    required Image coinImg,
    required SpriteAnimation Function(StageObjTypeLevel) getAnimeFunc,
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
            type: StageObjType.shop,
            level: level,
          ),
        ) {
    // ショップ情報を取得
    bool foundInfo = false;
    for (final entry in Config().shopInfoMap.entries) {
      final shopPos = entry.key;
      if ([
        shopPos,
        shopPos + Point(-1, 1),
        shopPos + Point(0, 1),
        shopPos + Point(1, 1),
      ].contains(pos)) {
        shopInfo = entry.value;
        foundInfo = true;
        break;
      }
    }
    assert(foundInfo, '[Shop]位置に該当するショップ情報がありません');

    if (level == 1) {
      // たぬきなら、吹き出しを持つ
      // 払うアイテムについて
      PositionComponent payTile = PositionComponent(
        size: Vector2(Stage.cellSize.x * 1.4, Stage.cellSize.y * 0.8),
      );
      PositionComponent payTileContents = PositionComponent(
        size: Vector2(Stage.cellSize.x * 1.4, Stage.cellSize.y * 0.8),
      );
      Vector2 offset = Vector2(0, 2);
      if (shopInfo.payCoins > 0) {
        payTileContents.add(SpriteComponent.fromImage(coinImg,
            position: offset,
            srcSize: Stage.cellSize,
            scale: Vector2.all(0.7)));
        offset += Vector2(Stage.cellSize.x * 0.7, 0) + Vector2(3, 0);
        payTileContents.add(TextComponent(
          text: shopInfo.payCoins.toString(),
          position: offset,
          textRenderer: TextPaint(
            style: Config.gameTextStyle,
          ),
        ));
      }
      payTile.add(
          AlignComponent(alignment: Anchor.center, child: payTileContents));
      PositionComponent itemTile = PositionComponent(
        size: Vector2(Stage.cellSize.x * 1.4, Stage.cellSize.y * 0.8),
      );
      PositionComponent itemTileContents = PositionComponent(
        size: Vector2(Stage.cellSize.x * 0.7, Stage.cellSize.y * 0.8),
      );
      offset = Vector2(0, 2);
      itemTileContents.add(SpriteAnimationComponent(
          animation: getAnimeFunc(shopInfo.getObj),
          position: offset,
          scale: Vector2.all(0.7)));
      itemTile.add(
          AlignComponent(alignment: Anchor.center, child: itemTileContents));
      infoBubble = RoundedComponent(
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
                text: '->',
                textRenderer: TextPaint(
                  style: Config.gameTextStyle,
                ),
              )),
          AlignComponent(alignment: Anchor.centerLeft, child: payTile),
          AlignComponent(alignment: Anchor.centerRight, child: itemTile),
        ],
      );
    }
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
    if (playerEndMoving) {
      // 吹き出しに関して
      if (infoBubble != null) {
        bool alreadyContains = gameWorld.contains(infoBubble!);
        bool isNear = PointRectRange(pos + Point(-2, -1), pos + Point(2, 2))
            .contains(stage.player.pos);
        if (!alreadyContains && isNear) {
          // 周囲8マスにプレイヤーが来たら吹き出し表示
          gameWorld.add(infoBubble!);
        } else if (alreadyContains && !isNear) {
          // 周囲8マスにいないなら吹き出し非表示
          gameWorld.remove(infoBubble!);
        }
      }
    }
  }

  @override
  void onRemove(World gameWorld) {
    if (infoBubble != null) {
      gameWorldRemove(gameWorld, infoBubble!);
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => level == 1;

  @override
  bool get puttable => level > 1;

  @override
  bool get playerMovable => !stopping;

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

  @override
  bool get isAnimals => true;
}
