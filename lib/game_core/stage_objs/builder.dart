import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Builder extends StageObj {
  /// 各レベルに対応する動きのパターン
  static final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.walkRandomOrStop,
    2: EnemyMovePattern.walkRandomOrStop,
    3: EnemyMovePattern.walkRandomOrStop,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'builder.png';

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    levelToAnimationsS = {
      0: {
        for (final move in MoveExtent.straights)
          move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      for (int i = 0; i < 3; i++)
        i + 1: {
          Move.left: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 128, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 160, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.right: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 192, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 224, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.up: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 64, 0), srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 96, 0), srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.down: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 0, 0), srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(i * 256 + 32, 0), srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
        },
    };
  }

  Builder({
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            key: GameUniqueKey('Builder'),
            priority: Stage.movingPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.builder,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// ブロックを置くまでにあと何ターンあるか
  int remainTurnToBuild = Config().builderBuildBlockTurn;

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
      // ランダムに移動orその場で停止
      final ret = super.enemyMove(
        movePatterns[level]!,
        vector,
        stage.player,
        stage,
        prohibitedPoints,
      );
      if (ret.containsKey('move')) {
        moving = ret['move'] as Move;
      }
      if (ret.containsKey('vector')) {
        vector = ret['vector'] as Move;
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

      if (moving != Move.none) {
        // ※※※画像の移動ここから※※※
        // 移動中の場合は画素も考慮
        Vector2 offset = moving.vector * movingAmount;
        stage.setObjectPosition(this, offset: offset);
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        pos += moving.point;
        // 移動後に関する処理
        endMoving(stage, gameWorld);
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        }
        // ブロック設置
        if (--remainTurnToBuild <= 0) {
          remainTurnToBuild = 0;
          // ステージ範囲外には設置不可
          if (stage.contains(pos + vector.point)) {
            final buildPosType = stage.get(pos + vector.point).type;
            if ((buildPosType == StageObjType.none ||
                    buildPosType == StageObjType.water ||
                    buildPosType == StageObjType.magma) &&
                stage.player.pos != pos + vector.point) {
              // ブロック設置
              stage.setStaticType(pos + vector.point, StageObjType.block,
                  level: 100 + level);
              // 次回ブロック設置までのターンをリセット
              remainTurnToBuild = Config().builderBuildBlockTurn;
            }
          }
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
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
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => true;

  @override
  int get coins => (level * 1.5).floor();
}
