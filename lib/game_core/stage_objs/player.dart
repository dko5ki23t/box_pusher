import 'package:box_pusher/audio.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

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
      1: {
        Move.down: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(0, 0), srcSize: playerImgSize),
          Sprite(baseImg, srcPosition: Vector2(40, 0), srcSize: playerImgSize),
        ], stepTime: Stage.objectStepTime),
        Move.up: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(80, 0), srcSize: playerImgSize),
          Sprite(baseImg, srcPosition: Vector2(120, 0), srcSize: playerImgSize),
        ], stepTime: Stage.objectStepTime),
        Move.left: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(160, 0), srcSize: playerImgSize),
          Sprite(baseImg, srcPosition: Vector2(200, 0), srcSize: playerImgSize),
        ], stepTime: Stage.objectStepTime),
        Move.right: SpriteAnimation.spriteList([
          Sprite(baseImg, srcPosition: Vector2(240, 0), srcSize: playerImgSize),
          Sprite(baseImg, srcPosition: Vector2(280, 0), srcSize: playerImgSize),
        ], stepTime: Stage.objectStepTime),
      },
    };
    levelToAttackAnimationsS = {
      1: {
        0: {
          Move.none:
              SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
        },
        1: {
          Move.down: SpriteAnimation.spriteList([
            Sprite(baseImg, srcPosition: Vector2(0, 0), srcSize: playerImgSize),
            Sprite(baseImg,
                srcPosition: Vector2(40, 0), srcSize: playerImgSize),
          ], stepTime: Stage.objectStepTime),
          Move.up: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(80, 0), srcSize: playerImgSize),
            Sprite(baseImg,
                srcPosition: Vector2(120, 0), srcSize: playerImgSize),
          ], stepTime: Stage.objectStepTime),
          Move.left: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(160, 0), srcSize: playerImgSize),
            Sprite(baseImg,
                srcPosition: Vector2(200, 0), srcSize: playerImgSize),
          ], stepTime: Stage.objectStepTime),
          Move.right: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(240, 0), srcSize: playerImgSize),
            Sprite(baseImg,
                srcPosition: Vector2(280, 0), srcSize: playerImgSize),
          ], stepTime: Stage.objectStepTime),
        },
      },
    };
  }

  final Blink damagedBlink = Blink(showDuration: 0.2, hideDuration: 0.1);

  static Vector2 playerImgSize = Vector2(40, 40);

  Player({
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
          levelToAnimations: levelToAnimationsS,
          // ※※ ダメージを受けた時はattackのアニメーションに変更する ※※
          levelToAttackAnimations: levelToAttackAnimationsS,
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
      Move actualMove = forceMoving != Move.none ? forceMoving : moveInput;
      forceMoving = Move.none;
      // ユーザの入力や氷で滑る移動がなければ何もしない
      if (actualMove == Move.none) {
        return;
      }
      // ダメージを受けていた場合でもアニメーションを元に戻す
      attacking = false;
      // 動けないとしても、向きは変更
      vector = actualMove.toStraightLR();
      // ステージ範囲外への移動を試みているか
      if (!stage.contains(pos + actualMove.point)) {
        return;
      }
      // プレイヤーが壁などにぶつかるか
      if (!stage.get(pos + actualMove.point).playerMovable) {
        return;
      }
      // 押し始める・押すオブジェクトを決定
      if (!startPushing(actualMove, pushableNum, stage, gameWorld,
          prohibitedPoints, pushings, executings)) {
        // 押せない等で移動できないならreturn
        return;
      }
      moving = actualMove;
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
    // 目の前がステージ外ならreturn
    if (!stage.contains(pos + vector.point)) return;

    if (pocketItem == null) {
      // 目の前のオブジェクトをポケットに入れる
      final target = stage.get(pos + vector.point);
      // 押せるものかつ重さが0なら入れることができる
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
        pocketItem!.addToGameWorld(gameWorld);
        // 置いた場所がマグマならオブジェクト蒸発
        if (target.type == StageObjType.magma) {
          // コイン獲得
          stage.coins.actual += pocketItem!.coins;
          stage.showGotCoinEffect(pocketItem!.coins, pos + vector.point);
          pocketItem!.remove();
          // 効果音を鳴らす
          Audio().playSound(Sound.magmaEvaporate);
        }
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
      // ダメージを負った音を鳴らす
      Audio().playSound(Sound.playerDamaged);
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

  @override
  bool get isAlly => true;
}
