import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Fire extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'fire.png';

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
      for (int i = 1; i <= 3; i++)
        i: {
          Move.none: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(64 * (i - 1), 0), srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(64 * (i - 1) + 32, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
        },
    };
  }

  /// 経過ターン
  int turns = 0;

  /// 消えるまでのターン数
  int get lastingTurns {
    switch (level) {
      case 2:
        return 4;
      case 3:
        return 8;
      default:
        return 1;
    }
  }

  Fire({
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.frontMovingPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          )..add(OpacityEffect.to(0.9, EffectController(duration: 0))),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.fire,
            level: level,
          ),
        ) {
    // 透明度変更
    animationComponent.add(OpacityEffect.to(
        turns >= lastingTurns - 1 ? 0.5 : 0.8, EffectController(duration: 0)));
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
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      ++turns;
      if (stage.safeGetStaticObj(pos).type == StageObjType.water) {
        // 氷は溶かして消滅
        stage.setStaticType(pos, StageObjType.none);
        validAfterFrame = false;
      }
      if (turns >= lastingTurns) {
        // オブジェクト削除
        validAfterFrame = false;
      }
      // 透明度変更
      if (turns >= lastingTurns - 1) {
        animationComponent
            .add(OpacityEffect.to(0.5, EffectController(duration: 0)));
      }
    }
    // 移動終了時のフレームの場合
    else if (playerEndMoving) {
      // 攻撃情報を追加
      stage.addEnemyAttackDamage(level, {pos});
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => true;

  @override
  bool get playerMovable => true;

  @override
  bool get enemyMovable => true;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;

  @override
  bool get hasVector => false;

  // Stage.get()の対象にならない(オブジェクトと重なってるのに敵の移動先にならないように)
  @override
  bool get isOverlay => true;

  // turnsの保存/読み込み
  @override
  int get arg => turns;

  @override
  void loadArg(int val) {
    turns = val;
  }
}
