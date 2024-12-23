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

  Bomb({
    required Image bombImg,
    required Image errorImg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  })  : explodingBombAnimation = SpriteAnimation.spriteList([
          Sprite(bombImg, srcPosition: Vector2(32, 0), srcSize: Stage.cellSize)
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
            1: {
              Move.none: SpriteAnimation.spriteList([
                Sprite(bombImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
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
    // プレイヤー位置がボムの周囲非起爆範囲より遠い位置なら爆発
    int n = ((Config().bombNotStartAreaWidth - 1) / 2).floor();
    if ((stage.player.pos.x < pos.x - n) ||
        (stage.player.pos.x > pos.x + n) ||
        (stage.player.pos.y < pos.y - n) ||
        (stage.player.pos.y > pos.y + n)) {
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
      stage.merge(
        pos,
        this,
        gameWorld,
        breakLeftOffset: -m,
        breakTopOffset: -m,
        breakRightOffset: m,
        breakBottomOffset: m,
        onlyDelete: true,
        enemyDamage: Config().debugEnemyDamageInExplosion,
      );
      // 効果音を鳴らす
      Audio().playSound(Sound.explode);
    }
  }

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
  bool get hasVector => false;
}
