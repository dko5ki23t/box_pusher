import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Canon extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'canon.png';

  /// 砲弾の画像のファイル名
  static String get canonballFileName => 'canonball.png';

  /// 砲弾のアニメーション
  static late final List<SpriteAnimation> canonballAnimations;

  /// 砲弾の飛距離
  static const int attackingReach = 3;

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    final canonballImg = await Flame.images.load(canonballFileName);
    levelToAnimationsS = {
      0: {
        Move.none:
            SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      1: {
        Move.down: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
        Move.up: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(32, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
        Move.left: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(64, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
        Move.right: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(96, 0), srcSize: Stage.cellSize)
        ], stepTime: 1.0),
      },
    };
    canonballAnimations = [
      SpriteAnimation.spriteList([
        Sprite(canonballImg,
            srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
      ], stepTime: 1.0)
    ];
  }

  /// 砲弾が飛ぶ時間
  double canonballMoveTime(int dist) =>
      Stage.cellSize.x / 2 / Stage.playerSpeed * (dist / attackingReach);

  Canon({
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.vector,
    required super.pos,
    int level = 1,
  }) : super(
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
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.canon,
            level: level,
          ),
        ) {
    nextVector = vector;
    _setNextVector();
  }

  /// 次に向く方向
  Move nextVector = Move.down;

  /// 攻撃中のマス
  Set<Point> attackingPoints = {};

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
    // 砲弾発射
    if (playerStartMoving) {
      // 飛距離
      int dist = attackingReach;
      if (!Config().isArrowPathThrough) {
        // 砲弾がオブジェクトに当たる場合は飛距離はそこまで
        for (dist = 1; dist < attackingReach + 1; dist++) {
          final obj = stage.getAfterPush(pos + vector.point * dist);
          if (!obj.isAlly && !obj.isEnemy && !obj.enemyMovable) {
            break;
          }
        }
        --dist;
      }
      if (dist > 0) {
        gameWorld.add(SpriteAnimationComponent(
          animation: canonballAnimations[level - 1],
          priority: Stage.movingPriority,
          children: [
            MoveEffect.by(
              Vector2(Stage.cellSize.x * vector.point.x * dist,
                  Stage.cellSize.y * vector.point.y * dist),
              EffectController(duration: canonballMoveTime(dist)),
            ),
            RemoveEffect(delay: canonballMoveTime(dist)),
          ],
          size: Stage.cellSize,
          anchor: Anchor.center,
          position:
              Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                  Stage.cellSize / 2,
        ));
        attackingPoints
            .addAll(PointLineRange(pos + vector.point, vector, dist).set);
      }
    }
    if (playerEndMoving) {
      for (final p in attackingPoints) {
        // ステージ範囲外
        if (!stage.contains(p)) continue;
        final obj = stage.get(p);
        // hit()でレベルを下げる前にコイン数を取得
        int gettableCoins = obj.coins;
        if (obj.isEnemy && obj.hit(level, stage)) {
          // 敵側の処理が残ってるかもしれないので、フレーム処理終了後に消す
          obj.removeAfterFrame();
          // コイン獲得
          stage.coins.actual += gettableCoins;
          stage.showGotCoinEffect(gettableCoins, obj.pos);
        }
      }
      attackingPoints.clear();
      // 向きを変更
      super.vector = nextVector;
      // 次に向く方向を設定
      _setNextVector();
    }
  }

  // 押された場合はその方向を向く
  @override
  set vector(Move v) {
    super.vector = v;
    nextVector = v;
  }

  void _setNextVector() {
    switch (nextVector) {
      case Move.down:
        nextVector = Move.left;
        return;
      case Move.left:
        nextVector = Move.up;
        return;
      case Move.up:
        nextVector = Move.right;
        return;
      case Move.right:
      default:
        nextVector = Move.down;
        return;
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
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => true;

  // ポケットに入れていてもupdate()する
  @override
  bool get updateInPocket => true;

  @override
  int get weight => 1;
}
