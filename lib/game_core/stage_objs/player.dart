import 'dart:math';

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
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

  /// 押しているオブジェクトを「行使」しているかどうか
  /// ex.) ドリルによるブロックの破壊
  bool executing = false;

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
      // 移動先の座標
      Point to = pos + moveInput.point;
      // 押すオブジェクトの移動先の座標
      Point toTo = to + moveInput.point;
      if (moveInput == Move.none) {
        return;
      }
      // 動けないとしても、向きは変更
      vector = moveInput.toStraightLR();

      StageObj toObj = stage.get(to);
      StageObj toToObj = stage.get(toTo);

      // プレイヤーが壁にぶつかるか
      if (toObj.type == StageObjType.block) {
        return;
      }

      pushings.clear();
      // マージするからここまでは押せるよ、なpushingsのリスト
      List<StageObj> pushingsSave = [];
      int end = pushableNum;
      if (end < 0) {
        final range = stage.stageRB - stage.stageLT;
        end = max(range.x, range.y);
      }
      for (int i = 0; i < end; i++) {
        bool stopBecauseDrill = false; // ドリルでブロックを壊すため、以降の判定をしなくて良いことを示すフラグ
        bool needSave = false;
        // オブジェクトが押せるか
        if (toObj.pushable) {
          bool breakPushing = false;
          // ドリルの場合は少し違う処理
          if (toObj.type == StageObjType.drill &&
              toToObj.type == StageObjType.block) {
            // 押した先がブロックなら即座に破壊、かつマージと同様、一気に押せるオブジェクト（pushings）はここまで
            // 破壊するブロックのアニメーションを描画
            gameWorld.add((toToObj as Block).createBreakingBlock());
            stage.setStaticType(toTo, StageObjType.none, gameWorld);
            executing = true;
            stopBecauseDrill = true;
          } else {
            if (toToObj.stopping) {
              // 押した先が停止物
              breakPushing = true;
            } else if (toToObj.isEnemy && toObj.enemyMovable) {
              // 押した先が敵かつ押すオブジェクトに敵が移動可能(->敵にオブジェクトを重ねる（トラップ等）)
            } else if (toToObj.puttable) {
              // 押した先が、何かを置けるオブジェクト
            } else if (toObj.isSameTypeLevel(toToObj) && toObj.mergable) {
              // 押した先とマージ できる
            } else if (i < end - 1 && toToObj.pushable) {
              // 押した先も押せる
            } else {
              breakPushing = true;
            }
            if (breakPushing) {
              // これまでにpushingsに追加したものも含めて一切押せない
              // ただし、途中でマージできるものがあるならそこまでは押せる
              pushings.clear();
              if (pushingsSave.isNotEmpty) {
                pushings.addAll(pushingsSave);
                break;
              }
              return;
            }
          }
          // マージできる場合は、pushingsをセーブする
          if (toToObj.isSameTypeLevel(toObj) && toObj.mergable) {
            needSave = true;
          }
        } else {
          // 押せない場合
          break;
        }
        // 押すオブジェクトリストに追加
        pushings.add(stage.boxes.firstWhere((element) => element.pos == to));
        // オブジェクトの移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints[toTo] = Move.none;
        if (stopBecauseDrill) {
          // ドリルでブロックを壊す場合
          break;
        }
        if (needSave) {
          // マージできる場合は、pushingsをセーブする
          pushingsSave = [...pushings];
        }
        // 1つ先へ
        to = toTo.copy();
        toTo = to + moveInput.point;
        // 範囲外に出る場合は押せないとする
        if (toTo.x < stage.stageLT.x ||
            toTo.y < stage.stageLT.y ||
            toTo.x > stage.stageRB.x ||
            toTo.y > stage.stageRB.y) {
          return;
        }
        toObj = stage.get(to);
        toToObj = stage.get(toTo);
      }
      // 押せる可能範囲全て押せるとしても、途中でマージするならそこまでしか押せない
      if (pushingsSave.isNotEmpty) {
        pushings.clear();
        pushings.addAll(pushingsSave);
      }

      // オブジェクトを押した場合、そのオブジェクトをすり抜けてプレイヤーの移動先には移動できないようにする
      if (pushings.isNotEmpty) {
        if (!prohibitedPoints.containsKey(pos + moveInput.point)) {
          prohibitedPoints[pos + moveInput.point] = moveInput.oppsite;
        }
      }
      // プレイヤーとはすれ違えないようにする
      if (!prohibitedPoints.containsKey(pos)) {
        prohibitedPoints[pos] = moveInput.oppsite;
      }
      moving = moveInput;
      movingAmount = 0.0;
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
        final Point to = pos + moving.point;
        // プレーヤー位置更新
        // ※merge()より前で更新することで、敵出現位置を、プレイヤーの目前にさせない
        pos = to.copy();
        stage.setObjectPosition(this);

        // 押したオブジェクトの中でマージするインデックスを探す
        int mergeIndex = -1; // -1はマージなし
        Point toTo = to + moving.point * pushings.length;
        // 押すオブジェクトのうち、なるべく遠くのオブジェクトをマージするために逆順でforループ
        for (int i = pushings.length - 1; i >= 0; i--) {
          final pushing = pushings[i];
          // 押した先のオブジェクトを調べる
          if (pushing.mergable && pushing.isSameTypeLevel(stage.get(toTo))) {
            // マージするインデックスを保存
            mergeIndex = i;
            break; // 1回だけマージ
          }
          toTo -= moving.point;
        }

        // 押したオブジェクト位置更新
        toTo = to + moving.point;
        for (int i = 0; i < pushings.length; i++) {
          final pushing = pushings[i];
          // 上で探したインデックスと一致するならマージ
          if (i == mergeIndex) {
            // マージ
            stage.merge(toTo, pushing, gameWorld);
          }
          // 押したものの位置を設定
          pushing.pos = toTo;
          stage.setObjectPosition(pushing);
          if (pushing.type == StageObjType.drill && executing) {
            // ドリル使用時
            // ドリルのオブジェクトレベルダウン、0になったら消す
            pushing.level--;
            if (pushing.level <= 0) {
              pushing.remove();
            }
          }
          toTo += moving.point;
        }

        if (stage.get(to).type == StageObjType.treasureBox) {
          // 移動先が宝箱だった場合
          // TODO:
          // コイン増加
          stage.coinNum++;
          // 宝箱消滅
          stage.setStaticType(to, StageObjType.none, gameWorld);
        } else if (stage.get(to).type == StageObjType.warp) {
          // 移動先がワープだった場合
          if (stage.warpPoints.length > 1) {
            // リスト内で次のワープ位置に移動
            int index = stage.warpPoints.indexWhere((element) => element == to);
            if (++index == stage.warpPoints.length) {
              index = 0;
            }
            pos = stage.warpPoints[index];
            stage.setObjectPosition(this);
          }
        } else if (stage.get(to).type == StageObjType.gorilla) {
          // 移動先がゴリラだった場合
          // 手の能力を習得
          pushableNum = -1;
          // ゴリラ、いなくなる
          stage.setStaticType(to, StageObjType.none, gameWorld);
          // 効果音を鳴らす
          Audio.playSound(Sound.getSkill);
        } else if (stage.get(to).type == StageObjType.rabbit) {
          // 移動先がうさぎだった場合
          // 足の能力を習得
          isLegAbilityOn = true;
          // うさぎ、いなくなる
          stage.setStaticType(to, StageObjType.none, gameWorld);
          // 効果音を鳴らす
          Audio.playSound(Sound.getSkill);
        } else if (stage.get(to).type == StageObjType.kangaroo) {
          // 移動先がカンガルーだった場合
          // ポケットの能力を習得
          isPocketAbilityOn = true;
          // カンガルー、いなくなる
          stage.setStaticType(to, StageObjType.none, gameWorld);
          // 効果音を鳴らす
          Audio.playSound(Sound.getSkill);
        } else if (stage.get(to).type == StageObjType.turtle) {
          // 移動先が亀だった場合
          // アーマーの能力を習得
          isArmerAbilityOn = true;
          // 亀、いなくなる
          stage.setStaticType(to, StageObjType.none, gameWorld);
          // 効果音を鳴らす
          Audio.playSound(Sound.getSkill);
        }

        // 各種移動中変数初期化
        moving = Move.none;
        pushings.clear();
        movingAmount = 0;
        executing = false;

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

  /// 敵の攻撃がプレイヤーに当たる
  /// 戻り値：ゲームオーバーになるかどうか
  bool hit() {
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
