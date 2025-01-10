import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flame/extensions.dart';

class Player extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'player.png';

  Player({
    required Image playerImg,
    required Image errorImg,
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
          typeLevel: StageObjTypeLevel(
            type: StageObjType.player,
            level: level,
          ),
        );

  /// 一度にいくつのオブジェクトを押せるか(-1なら制限なし)
  int pushableNum = 1;

  /// 足の能力が有効か
  bool isLegAbilityOn = false;

  /// ポケットの能力が有効か
  bool isPocketAbilityOn = false;

  /// ポケットの能力で保持しているアイテム
  StageObj? pocketItem;

  /// アーマーの能力が有効か
  bool isArmerAbilityOn = false;

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
    if (moving == Move.none) {
      // 移動中でない場合
      if (moveInput == Move.none) {
        return;
      }
      // 動けないとしても、向きは変更
      vector = moveInput.toStraightLR();
      // プレイヤーが壁などにぶつかるか
      if (stage.get(pos + moveInput.point).stopping) {
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
        stage.setObjectPosition(this);
        // 移動後に関する処理（ワープで移動、動物の能力取得など）
        endMoving(stage, gameWorld);
        // 押すオブジェクトに関する処理
        endPushing(stage, gameWorld);

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
    // ポケットの能力を取得していないならreturn
    if (!isPocketAbilityOn) return;
    // 移動中ならreturn
    if (moving != Move.none) return;

    if (pocketItem == null) {
      // 目の前のオブジェクトをポケットに入れる
      final target = stage.get(pos + vector.point);
      // 押せるものなら入れることができる
      if (target.pushable) {
        pocketItem = target;
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
  bool hit(int damageLevel) {
    if (isArmerAbilityOn && armerRecoveryTurns == 0) {
      armerRecoveryTurns = armerNeedRecoveryTurns;
      return false;
    } else {
      return true;
    }
  }

  @override
  Map<String, dynamic> encode() {
    Map<String, dynamic> ret = super.encode();
    ret['handAbility'] = pushableNum;
    ret['legAbility'] = isLegAbilityOn;
    ret['pocketAbility'] = isPocketAbilityOn;
    ret['pocketItem'] = pocketItem?.encode();
    ret['armerAbility'] = isArmerAbilityOn;
    ret['armerRecoveryTurns'] = armerRecoveryTurns;
    return ret;
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

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
