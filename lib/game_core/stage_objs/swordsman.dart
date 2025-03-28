import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Swordsman extends StageObj {
  /// 各レベルに対応する動きのパターン
  static final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayerAttackForward3,
    2: EnemyMovePattern.followPlayerAttackRound8,
    3: EnemyMovePattern.followPlayerAttackRound8,
  };

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'swordsman.png';

  /// 各レベルごとの攻撃時の画像のファイル名
  static List<Map<Move, String>> get attackImgFileNames => [
        for (int i = 1; i <= 3; i++)
          {
            Move.down: 'swordsman_attackD$i.png',
            Move.left: 'swordsman_attackL$i.png',
            Move.right: 'swordsman_attackR$i.png',
            Move.up: 'swordsman_attackU$i.png',
          }
      ];

  /// 各レベルごとの回転斬り時の画像のファイル名
  static List<String> get roundAttackImgFileNames =>
      [for (int i = 1; i <= 3; i++) 'swordsman_attack_round$i.png'];

  /// 攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  static final Map<Move, Vector2> attackAnimationOffset = {
    Move.up: Vector2(0, -16.0),
    Move.down: Vector2(0, 16.0),
    Move.left: Vector2(-16.0, 0),
    Move.right: Vector2(16.0, 0)
  };

  /// 回転斬り攻撃時アニメーションのオフセット
  static final Vector2 roundAttackAnimationOffset = Vector2.zero();

  /// 攻撃の1コマの時間
  static const double attackStepTime = 32.0 / Stage.playerSpeed / 5;

  /// 回転斬りの1コマの時間
  static const double roundAttackStepTime = 32.0 / Stage.playerSpeed / 20;

  /// 攻撃をし続けるターン数
  static final Map<int, int> attackTurns = {
    1: 1,
    2: 1,
    3: 2,
  };

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// チャンネル->オブジェクトのレベル->向き->攻撃時アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<int, Map<Move, SpriteAnimation>>>
      levelToAttackAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    final attackImgs = [
      for (final names in attackImgFileNames)
        {
          for (final entry in names.entries)
            entry.key: await Flame.images.load(entry.value)
        }
    ];
    final roundAttackImgs = [
      for (final name in roundAttackImgFileNames) await Flame.images.load(name)
    ];
    levelToAnimationsS = {
      0: {
        for (final move in MoveExtent.straights)
          move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0)
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
    levelToAttackAnimationsS = {
      // 前方3マスに攻撃
      1: {
        0: {
          for (final move in MoveExtent.straights)
            move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0)
        },
        for (int i = 1; i <= 3; i++)
          i: {
            Move.down: SpriteAnimation.fromFrameData(
              attackImgs[i - 1][Move.down]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.up: SpriteAnimation.fromFrameData(
              attackImgs[i - 1][Move.up]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(96.0, 64.0)),
            ),
            Move.left: SpriteAnimation.fromFrameData(
              attackImgs[i - 1][Move.left]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
            Move.right: SpriteAnimation.fromFrameData(
              attackImgs[i - 1][Move.right]!,
              SpriteAnimationData.sequenced(
                  amount: 5,
                  stepTime: attackStepTime,
                  textureSize: Vector2(64.0, 96.0)),
            ),
          },
      },
      // 回転斬りで周囲8マスに攻撃
      2: {
        0: {
          for (final move in MoveExtent.straights)
            move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0)
        },
        for (int i = 1; i <= 3; i++)
          i: {
            Move.down: SpriteAnimation.fromFrameData(
              roundAttackImgs[i - 1],
              SpriteAnimationData.sequenced(
                  amount: 20,
                  stepTime: roundAttackStepTime,
                  textureSize: Vector2.all(96.0)),
            ),
            Move.up: SpriteAnimation.spriteList(
              [
                for (int j = 10; j < 30; j++)
                  Sprite(roundAttackImgs[i - 1],
                      srcPosition: Vector2((j % 20) * 96, 0),
                      srcSize: Vector2.all(96.0))
              ],
              stepTime: roundAttackStepTime,
            ),
            Move.left: SpriteAnimation.spriteList(
              [
                for (int j = 15; j < 35; j++)
                  Sprite(roundAttackImgs[i - 1],
                      srcPosition: Vector2((j % 20) * 96, 0),
                      srcSize: Vector2.all(96.0))
              ],
              stepTime: roundAttackStepTime,
            ),
            Move.right: SpriteAnimation.spriteList(
              [
                for (int j = 5; j < 25; j++)
                  Sprite(roundAttackImgs[i - 1],
                      srcPosition: Vector2((j % 20) * 96, 0),
                      srcSize: Vector2.all(96.0))
              ],
              stepTime: roundAttackStepTime,
            ),
          },
      },
    };
  }

  /// 経過している攻撃ターン
  int attackingTurns = 0;

  Swordsman({
    required super.savedArg,
    required super.pos,
    required void Function(StageObj obj, {Vector2? offset}) setPosition,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            key: GameUniqueKey('Swordsman'),
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
            type: StageObjType.swordsman,
            level: level,
          ),
        ) {
    // レベル3での2ターン連続斬り途中でセーブされていたら、それを復元
    attacking = attackingTurns > 0;
    if (attacking) {
      // 攻撃中のアニメーションに変更
      if (level <= 1) {
        attackCh = 1;
        vector = vector;
        animationComponent.size =
            animationComponent.animation!.frames.first.sprite.srcSize;
        setPosition(this, offset: attackAnimationOffset[vector]!);
      } else {
        attackCh = 2;
        vector = vector;
        animationComponent.size =
            animationComponent.animation!.frames.first.sprite.srcSize;
        setPosition(this, offset: roundAttackAnimationOffset);
      }
    }
  }

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
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      playerStartMovingFlag = true;
      if (attackingTurns == 0) {
        // 攻撃中でないなら
        // 移動/攻撃を決定
        final ret = super.enemyMove(movePatterns[level]!, vector, stage.player,
            stage, prohibitedPoints);
        if (ret.containsKey('attack') && ret['attack']!) {
          attacking = true;
          // 攻撃中のアニメーションに変更
          if (level <= 1) {
            attackCh = 1;
            vector = vector;
            animationComponent.size =
                animationComponent.animation!.frames.first.sprite.srcSize;
            stage.setObjectPosition(this,
                offset: attackAnimationOffset[vector]!);
          } else {
            attackCh = 2;
            vector = vector;
            animationComponent.size =
                animationComponent.animation!.frames.first.sprite.srcSize;
            stage.setObjectPosition(this, offset: roundAttackAnimationOffset);
          }
        }
        if (ret.containsKey('move')) {
          moving = ret['move'] as Move;
        }
        if (ret.containsKey('vector')) {
          vector = ret['vector'] as Move;
        }
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
        } else if (attacking) {
          attackingTurns++;
          if (level <= 1) {
            // 前方3マスに攻撃
            final tmp = MoveExtent.straights;
            tmp.remove(vector);
            tmp.remove(vector.oppsite);
            final attackable = pos + vector.point;
            final attackables = {attackable};
            for (final v in tmp) {
              attackables.add(attackable + v.point);
            }
            // 攻撃情報を追加
            stage.addEnemyAttackDamage(level, attackables);
          } else {
            // 回転斬りの場合は周囲8マスに攻撃
            final range =
                PointRectRange((pos - Point(1, 1)), pos + Point(1, 1));
            // 攻撃情報を追加
            stage.addEnemyAttackDamage(level, range.set);
          }
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
        if (attacking) {
          if (attackingTurns >= attackTurns[level]!) {
            // レベルで決まる攻撃持続ターンを超えていたら攻撃終了
            attacking = false;
            attackingTurns = 0;
            // アニメーションを元に戻す
            vector = vector;
            animationComponent.size = Stage.cellSize;
            stage.setObjectPosition(this);
          }
        }
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

  // attackingTurnsの保存/読み込み
  @override
  int get arg => attackingTurns;

  @override
  void loadArg(int val) {
    attackingTurns = val;
  }
}
