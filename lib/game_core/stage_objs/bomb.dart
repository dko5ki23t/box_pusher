import 'package:box_pusher/audio.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

class Bomb extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'bomb.png';

  /// 爆発のアニメーション
  final SpriteAnimation explodingBombAnimation;

  /// 爆発寸前エフェクト
  final redEffect = ColorEffect(
    const Color(0xffff0000),
    EffectController(
      duration: 0.5,
      reverseDuration: 0.5,
      infinite: true,
    ),
    opacityFrom: 0.2,
    opacityTo: 0.8,
  );

  bool isRedEffectUsed = false;

  Bomb({
    required Image bombImg,
    required Image errorImg,
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  })  : explodingBombAnimation = SpriteAnimation.spriteList([
          Sprite(bombImg, srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
        super(
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
            for (int i = 1; i <= 3; i++)
              i: {
                Move.none: SpriteAnimation.spriteList([
                  Sprite(bombImg,
                      srcPosition: Vector2(32 * (i - 1), 0),
                      srcSize: Stage.cellSize)
                ], stepTime: 1.0)
              },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.bomb,
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
  ) {
    int n = ((Config().bombNotStartAreaWidth - 1) / 2).floor();
    // プレイヤー位置がボムの周囲非起爆範囲より遠い位置なら爆発
    if (!PointRectRange(pos + Point(-n, -n), pos + Point(n, n))
        .contains(stage.player.pos)) {
      // 爆発アニメ表示
      final explodingAnimation = SpriteAnimationComponent(
        animation: explodingBombAnimation,
        priority: Stage.dynamicPriority,
        children: [
          OpacityEffect.by(
            -1.0,
            EffectController(duration: 0.8),
          ),
          ScaleEffect.by(
            Vector2.all(Stage.bombZoomRate),
            EffectController(
              duration: Stage.bombZoomDuration,
              reverseDuration: Stage.bombZoomDuration,
              infinite: true,
            ),
          ),
          RemoveEffect(delay: 1.0),
        ],
        size: Stage.cellSize,
        anchor: Anchor.center,
        position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2),
      );
      gameWorld.add(explodingAnimation);
      // 爆発
      int m = ((Config().bombExplodingAreaWidth - 1) / 2).floor();
      int mergePow = level;
      final affect = MergeAffect(
        basePoint: pos,
        range: PointRectRange(pos + Point(-m, -m), pos + Point(m, m)),
        canBreakBlockFunc: (block) =>
            Config.canBreakBlock(block, mergePow), // 爆弾のレベル分のパワーで周囲を破壊
        enemyDamage: Config().debugEnemyDamageInExplosion,
      );
      stage.merge(
        pos,
        this,
        gameWorld,
        affect,
        onlyDelete: true,
        countMerge: false,
        addScore: false,
      );
      // 効果音を鳴らす
      Audio().playSound(Sound.explode);
      return;
    }
    // 非起爆範囲ギリギリにいる場合は赤く点滅
    else if (!PointRectRange(
            pos + Point(-n + 1, -n + 1), pos + Point(n - 1, n - 1))
        .contains(stage.player.pos)) {
      if (!isRedEffectUsed) {
        animationComponent.add(redEffect);
        isRedEffectUsed = true;
      }
    } else {
      // 赤い点滅エフェクト削除
      if (isRedEffectUsed) {
        redEffect.reset();
        animationComponent.remove(redEffect);
        isRedEffectUsed = false;
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
  bool get playerMovable => true;

  @override
  bool get enemyMovable => false;

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

  @override
  bool get hasVector => false;
}
