import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class Ghost extends StageObj {
  /// 各レベルに対応する動きのパターン
  final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerWithGhosting,
    2: EnemyMovePattern.followPlayerWithGhosting,
    3: EnemyMovePattern.followPlayerWithGhosting,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'ghost.png';

  /// オブジェクトのレベル->ゴースト化アニメーションのマップ
  final Map<int, SpriteAnimation> levelToGhostAnimations;

  Ghost({
    required Image ghostImg,
    required Image errorImg,
    required super.savedArg,
    required super.pos,
    int level = 1,
  })  : levelToGhostAnimations = {
          0: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
          for (int i = 1; i <= 3; i++)
            i: SpriteAnimation.spriteList([
              Sprite(ghostImg,
                  srcPosition: Vector2(128 * (i - 1) + 64, 0),
                  srcSize: Stage.cellSize),
              Sprite(ghostImg,
                  srcPosition: Vector2(128 * (i - 1) + 96, 0),
                  srcSize: Stage.cellSize),
            ], stepTime: Stage.objectStepTime),
        },
        super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.movingPriority,
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
            for (int i = 1; i <= 3; i++)
              i: {
                Move.none: SpriteAnimation.spriteList([
                  Sprite(ghostImg,
                      srcPosition: Vector2(128 * (i - 1), 0),
                      srcSize: Stage.cellSize),
                  Sprite(ghostImg,
                      srcPosition: Vector2(128 * (i - 1) + 32, 0),
                      srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.ghost,
            level: level,
          ),
        );

  bool playerStartMovingFlag = false;

  /// すり抜け中か
  bool ghosting = false;

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
      // 移動/ゴースト化/ゴースト解除を決定
      final ret = super.enemyMove(
          movePatterns[level]!, vector, stage.player, stage, prohibitedPoints,
          isGhost: ghosting);
      if (ret.containsKey('ghost') && ret['ghost']! && !ghosting) {
        ghosting = true;
        // ゴースト化したアニメーションに変更
        int key = levelToGhostAnimations.containsKey(level) ? level : 0;
        animationComponent.animation = levelToGhostAnimations[key]!;
      } else if (ret.containsKey('ghost') && !ret['ghost']! && ghosting) {
        ghosting = false;
        // 元のアニメーションに変更
        int key = levelToAnimations.containsKey(level) ? level : 0;
        animationComponent.animation = levelToAnimations[key]![Move.none]!;
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
}
