import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Ghost extends StageObj {
  /// 各レベルに対応する動きのパターン
  static final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerWithGhosting,
    2: EnemyMovePattern.followPlayerWithGhosting,
    3: EnemyMovePattern.followPlayerWithGhosting,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'ghost.png';

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// チャンネル->オブジェクトのレベル->向き->攻撃時アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<int, Map<Move, SpriteAnimation>>>
      levelToAttackAnimationsS = {};

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
                srcPosition: Vector2(128 * (i - 1), 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(128 * (i - 1) + 32, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
        },
    };
    levelToAttackAnimationsS = {
      1: {
        0: {
          Move.none:
              SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
        },
        for (int i = 1; i <= 3; i++)
          i: {
            Move.none: SpriteAnimation.spriteList([
              Sprite(baseImg,
                  srcPosition: Vector2(128 * (i - 1) + 64, 0),
                  srcSize: Stage.cellSize),
              Sprite(baseImg,
                  srcPosition: Vector2(128 * (i - 1) + 96, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: Stage.objectStepTime),
          },
      },
    };
  }

  /// ゴースト状態になってからの経過ターン数
  int ghostTurns = 0;

  Ghost({
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            key: GameUniqueKey('Ghost'),
            priority: Stage.movingPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          levelToAttackAnimations: levelToAttackAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.ghost,
            level: level,
          ),
        ) {
    // ゴースト状態経過ターン数に応じて変数とアニメーションを変更
    ghosting = ghostTurns > 0;
    vector = vector;
  }

  bool playerStartMovingFlag = false;

  /// すり抜け中か
  bool get ghosting => attacking;
  set ghosting(bool b) => attacking = b;

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
      if ((ghostTurns > 0 && (ghostTurns == 1 || ghostTurns % 3 == 0)) &&
          level > 1) {
        // 火の玉を設置
        final fire = stage.createObject(
            typeLevel: StageObjTypeLevel(type: StageObjType.fire, level: level),
            pos: pos);
        stage.enemies.add(fire);
      }
      // 移動/ゴースト化/ゴースト解除を決定
      final ret = super.enemyMove(
          movePatterns[level]!, vector, stage.player, stage, prohibitedPoints,
          isGhost: ghosting);
      if (ret.containsKey('ghost') && ret['ghost']! && !ghosting) {
        ghosting = true;
        // ゴースト化したアニメーションに変更
        vector = vector;
      } else if (ret.containsKey('ghost') && !ret['ghost']! && ghosting) {
        ghosting = false;
        ghostTurns = 0;
        // 元のアニメーションに変更
        vector = vector;
      } else if (ret.containsKey('move')) {
        moving = ret['move'] as Move;
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
        if (stage.player.pos == pos && !ghosting) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        }
        // ゴースト継続ターン追加
        if (ghosting) {
          ghostTurns++;
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
  bool get puttable => ghosting;

  @override
  bool get playerMovable => true;

  @override
  bool get enemyMovable => ghosting;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => !ghosting;

  @override
  bool get beltMove => !ghosting;

  @override
  bool get hasVector => false;

  @override
  int get coins => level * 2;

  // Stage.get()の対象にならない(オブジェクトと重なってるのに敵の移動先にならないように)
  @override
  bool get isOverlay => ghosting;

  // ghostTurnsの保存/読み込み
  @override
  int get arg => ghostTurns;

  @override
  void loadArg(int val) {
    ghostTurns = val;
  }
}
