import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Water extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'water.png';

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
          for (int i = 0; i < 14; i++)
            Sprite(baseImg,
                srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
          Sprite(baseImg, srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
          Sprite(baseImg, srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
        ], stepTime: Stage.objectStepTime / 3)
      },
    };
  }

  Water({
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
            type: StageObjType.water,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

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
    if (playerStartMoving) {
      playerStartMovingFlag = true;
      // この氷の上にあるものが押せるか
      bool canPush = false;
      if (moving != Move.none && stage.get(pos).pushable) {
        // 一旦位置を変える
        pos += moving.oppsite.point;
        // 押すのを試みる。押せない場合はmovingをnoneに
        canPush = startPushing(moving, 1, stage, gameWorld, prohibitedPoints,
            pushings, executings);
        // 位置を元に戻す
        pos += moving.point;
      }
      if (!canPush) {
        moving = Move.none;
      }
      movingAmount = 0;
    }

    if (playerStartMovingFlag) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      Vector2 offset = moving.vector * movingAmount;
      for (final pushing in pushings) {
        // 押しているオブジェクトの位置変更
        stage.setObjectPosition(pushing, offset: offset);
        // 押しているオブジェクトの向き変更
        pushing.vector = moving.toStraightLR();
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        // 押すオブジェクトに関する処理
        endPushing(stage, gameWorld);
        movingAmount = 0;
        pushings.clear();
        executings.clear();
        playerStartMovingFlag = false;
      }
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
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;

  @override
  bool get hasVector => false;
}
