import 'package:push_and_merge/audio.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Trap extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'trap.png';

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
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0)
      },
      2: {
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(32, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0)
      },
      3: {
        Move.none: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
          Sprite(baseImg, srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
        ], stepTime: Stage.objectStepTime)
      },
    };
  }

  Trap({
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            key: GameUniqueKey('Trap'),
            priority: Stage.dynamicPriority,
            size: Stage.cellSize,
            scale: scale,
            anchor: Anchor.center,
            children: [scaleEffect],
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.trap,
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
    // このオブジェクトが押されていて、敵とすれ違うなら、罠レベル以下の敵を消す
    if (playerStartMoving) {
      if (stage.player.pushings.contains(this)) {
        final targets = stage.enemies.where((e) =>
            e.pos == pos + stage.player.moving.point &&
            e.moving == stage.player.moving.oppsite);
        for (final target in targets) {
          if (target.isEnemy && target.killable && target.level <= level) {
            // 敵側の処理が残っているかもしれないので、フレームの最後に消す
            target.removeAfterFrame();
            // コイン獲得
            int gotCoins = target.coins;
            stage.coins.actual += gotCoins;
            stage.showGotCoinEffect(gotCoins, target.pos);
            // 効果音を鳴らす
            switch (level) {
              default:
                Audio().playSound(Sound.trap1);
                break;
            }
            if (Config().consumeTrap) {
              // トラップのレベルを下げる、0以下になったら消す
              --level;
              if (level <= 0) removeAfterFrame();
            }
          }
        }
      }
    }
    // このオブジェクトと同じ位置の、罠レベル以下の敵を消す
    if (playerEndMoving) {
      final killing = stage.get(pos);
      if (killing.isTrapKillable && killing.level <= level) {
        // 敵側の処理が残っているかもしれないので、フレームの最後に消す
        killing.removeAfterFrame();
        // コイン獲得
        int gotCoins = killing.coins;
        stage.coins.actual += gotCoins;
        stage.showGotCoinEffect(gotCoins, killing.pos);
        // 効果音を鳴らす
        switch (level) {
          default:
            Audio().playSound(Sound.trap1);
            break;
        }
        if (Config().consumeTrap) {
          // トラップのレベルを下げる、0以下になったら消す
          --level;
          if (level <= 0) removeAfterFrame();
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
  bool get playerMovable => true;

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

  @override
  bool get hasVector => false;
}
