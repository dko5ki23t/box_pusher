import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flame/extensions.dart';

/// プレイヤーの能力
enum PlayerAbility {
  hand,
  leg,
  armer,
  pocket,
  eye,
  merge,
}

class Player extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'player.png';

  final Blink damagedBlink = Blink(showDuration: 0.2, hideDuration: 0.1);

  Player({
    required Image playerImg,
    required Image errorImg,
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
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
            1: {
              Move.down: SpriteAnimation.spriteList([
                Sprite(playerImg,
                    srcPosition: Vector2(0, 0), srcSize: Stage.cellSize),
                Sprite(playerImg,
                    srcPosition: Vector2(32, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.up: SpriteAnimation.spriteList([
                Sprite(playerImg,
                    srcPosition: Vector2(64, 0), srcSize: Stage.cellSize),
                Sprite(playerImg,
                    srcPosition: Vector2(96, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.left: SpriteAnimation.spriteList([
                Sprite(playerImg,
                    srcPosition: Vector2(128, 0), srcSize: Stage.cellSize),
                Sprite(playerImg,
                    srcPosition: Vector2(160, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
              Move.right: SpriteAnimation.spriteList([
                Sprite(playerImg,
                    srcPosition: Vector2(192, 0), srcSize: Stage.cellSize),
                Sprite(playerImg,
                    srcPosition: Vector2(224, 0), srcSize: Stage.cellSize),
              ], stepTime: Stage.objectStepTime),
            },
          },
          // ※※ ダメージを受けた時はattackのアニメーションに変更する ※※
          levelToAttackAnimations: {
            1: {
              0: {
                Move.none: SpriteAnimation.spriteList([Sprite(errorImg)],
                    stepTime: 1.0),
              },
              1: {
                Move.down: SpriteAnimation.spriteList([
                  Sprite(playerImg,
                      srcPosition: Vector2(256, 0), srcSize: Stage.cellSize),
                  Sprite(playerImg,
                      srcPosition: Vector2(288, 0), srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.up: SpriteAnimation.spriteList([
                  Sprite(playerImg,
                      srcPosition: Vector2(320, 0), srcSize: Stage.cellSize),
                  Sprite(playerImg,
                      srcPosition: Vector2(352, 0), srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.left: SpriteAnimation.spriteList([
                  Sprite(playerImg,
                      srcPosition: Vector2(384, 0), srcSize: Stage.cellSize),
                  Sprite(playerImg,
                      srcPosition: Vector2(416, 0), srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
                Move.right: SpriteAnimation.spriteList([
                  Sprite(playerImg,
                      srcPosition: Vector2(448, 0), srcSize: Stage.cellSize),
                  Sprite(playerImg,
                      srcPosition: Vector2(480, 0), srcSize: Stage.cellSize),
                ], stepTime: Stage.objectStepTime),
              },
            },
          },
          typeLevel: StageObjTypeLevel(
            type: StageObjType.player,
            level: level,
          ),
        );

  /// 各能力を習得済みかどうか
  Map<PlayerAbility, bool> isAbilityAquired = {
    for (final ability in PlayerAbility.values) ability: false
  };

  /// 各能力が封印されているかどうか
  Map<PlayerAbility, bool> isAbilityForbidden = {
    for (final ability in PlayerAbility.values) ability: false
  };

  /// 引数で指定した能力を使えるか
  bool isAbilityAvailable(PlayerAbility ability) {
    return isAbilityAquired[ability]! && !isAbilityForbidden[ability]!;
  }

  /// 一度にいくつのオブジェクトを押せるか(-1なら制限なし)
  int get pushableNum => isAbilityAvailable(PlayerAbility.hand) ? -1 : 1;
  set pushableNum(int n) {}

  /// ポケットの能力で保持しているアイテム
  StageObj? pocketItem;

  /// アーマー回復までの残りターン数
  int armerRecoveryTurns = 0;

  /// アーマー回復に要するターン数
  static int armerNeedRecoveryTurns = 3;

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
    damagedBlink.update(dt);
    if (moving == Move.none) {
      // 移動中でない場合
      // ダメージを受けたターンなら点滅
      if (attacking) {
        if (damagedBlink.isShowTime) {
          animationComponent.animation = null;
        } else {
          vector = vector;
        }
      }
      // ユーザの入力がなければ何もしない
      if (moveInput == Move.none) {
        return;
      }
      // ダメージを受けていた場合でもアニメーションを元に戻す
      attacking = false;
      // 動けないとしても、向きは変更
      vector = moveInput.toStraightLR();
      // プレイヤーが壁などにぶつかるか
      if (!stage.get(pos + moveInput.point).playerMovable) {
        return;
      }
      // 押し始める・押すオブジェクトを決定
      if (!startPushing(moveInput, pushableNum, stage, gameWorld,
          prohibitedPoints, pushings, executings)) {
        // 押せない等で移動できないならreturn
        return;
      }
      moving = moveInput;
      movingAmount = 0.0;
      // 移動先に他のオブジェクトが移動できないようにする
      prohibitedPoints[pos + moving.point] = Move.none;
    }

    if (moving != Move.none) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      Vector2 offset = moving.vector * movingAmount;
      // プレイヤー位置変更
      stage.setObjectPosition(this, offset: offset);
      for (final pushing in pushings) {
        // 押しているオブジェクトの位置変更
        stage.setObjectPosition(pushing, offset: offset);
        // 押しているオブジェクトの向き変更
        pushing.vector = moving.toStraightLR();
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        // プレーヤー位置更新
        // ※merge()より前で更新することで、敵出現位置を、プレイヤーの目前にさせない
        pos = pos + moving.point;
        // ポケットに入れているオブジェクトの位置も更新
        pocketItem?.pos = pos;
        stage.setObjectPosition(this);
        // 移動後に関する処理（ワープで移動、動物の能力取得など）
        endMoving(stage, gameWorld);
        // 押すオブジェクトに関する処理
        // マージ能力が有効なら範囲と威力増大
        endPushing(
          stage,
          gameWorld,
          mergeRangeFunc: isAbilityAvailable(PlayerAbility.merge)
              ? (pos) => PointDistanceRange(pos, 2)
              : null,
          mergeDamageBase: isAbilityAvailable(PlayerAbility.merge) ? 1 : 0,
          mergePowerBase: isAbilityAvailable(PlayerAbility.merge) ? 1 : 0,
        );

        // 各種移動中変数初期化
        moving = Move.none;
        pushings.clear();
        movingAmount = 0;
        executings.clear();

        // アーマー回復
        if (armerRecoveryTurns > 0) {
          armerRecoveryTurns--;
        }
      }
    }
  }

  void usePocketAbility(Stage stage, World gameWorld) {
    // ポケットの能力を使えないならreturn
    if (!isAbilityAvailable(PlayerAbility.pocket)) return;
    // 移動中ならreturn
    if (moving != Move.none) return;

    if (pocketItem == null) {
      // 目の前のオブジェクトをポケットに入れる
      final target = stage.get(pos + vector.point);
      // 押せるものなら入れることができる
      if (target.pushable) {
        pocketItem = target;
        pocketItem?.pos = pos;
        target.remove();
      }
    } else {
      // 目の前に置く
      final target = stage.get(pos + vector.point);
      // 置ける場所/敵なら置く
      if (target.puttable || (target.isEnemy && pocketItem!.enemyMovable)) {
        pocketItem!.valid = true;
        stage.boxes.add(pocketItem!);
        pocketItem!.pos = pos + vector.point;
        stage.setObjectPosition(pocketItem!);
        gameWorld.add(pocketItem!.animationComponent);
        pocketItem = null;
      }
    }
  }

  @override
  bool hit(int damageLevel, Stage stage) {
    // ※※ ダメージを受けた時はattackのアニメーションに変更する ※※
    attacking = true;
    vector = vector;
    // アーマー能力判定
    if (isAbilityAvailable(PlayerAbility.armer) && armerRecoveryTurns == 0) {
      armerRecoveryTurns = armerNeedRecoveryTurns;
      return false;
    } else {
      return true;
    }
  }

  @override
  Map<String, dynamic> encode() {
    Map<String, dynamic> ret = super.encode();
    ret['handAbility'] = isAbilityAquired[PlayerAbility.hand]! ? -1 : 1;
    ret['legAbility'] = isAbilityAquired[PlayerAbility.leg]!;
    ret['pocketAbility'] = isAbilityAquired[PlayerAbility.pocket]!;
    ret['pocketItem'] = pocketItem?.encode();
    ret['armerAbility'] = isAbilityAquired[PlayerAbility.armer]!;
    ret['armerRecoveryTurns'] = armerRecoveryTurns;
    ret['eyeAbility'] = isAbilityAquired[PlayerAbility.eye]!;
    ret['mergeAbility'] = isAbilityAquired[PlayerAbility.merge]!;
    return ret;
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get playerMovable => false;

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
  bool get beltMove => true;

  @override
  bool get hasVector => true;
}
