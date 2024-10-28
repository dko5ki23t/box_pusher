import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Player extends StageObj {
  Player({
    required super.animationComponent,
    required super.levelToAnimations,
    required super.pos,
    int level = 1,
  }) : super(
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

  @override
  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    List<Point> prohibitedPoints,
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
      StageObj toObj = stage.get(to);
      StageObj toToObj = stage.get(toTo);

      // プレイヤーが壁にぶつかるか
      if (toObj.type == StageObjType.wall) {
        return;
      }

      pushings.clear();
      int end = pushableNum;
      if (end < 0) {
        final range = stage.stageRB - stage.stageLT;
        end = max(range.x, range.y);
      }
      for (int i = 0; i < end; i++) {
        bool stopBecauseMergeOrDrill =
            false; // マージが発生する/ドリルでブロックを壊すため、以降の判定をしなくて良いことを示すフラグ
        // オブジェクトが押せるか
        if (toObj.pushable) {
          // ドリルの場合は少し違う処理
          if (toObj.type == StageObjType.drill &&
              toToObj.type == StageObjType.wall) {
            // 押した先がブロックなら即座に破壊、かつマージと同様、一気に押せるオブジェクト（pushings）はここまで
            stage.setStaticType(toTo, StageObjType.none, gameWorld);
            // 破壊したブロックのアニメーションを描画
            gameWorld.add(stage.objFactory.createBreakingBlock(toTo));
            executing = true;
            stopBecauseMergeOrDrill = true;
          } else if (toToObj.stopping ||
              (i == end - 1 &&
                  !toToObj.puttable &&
                  (!toObj.isSameTypeLevel(toToObj) || !toObj.mergable))) {
            // 押した先が敵等 or 一気に押せる数の端だがマージできないオブジェクトの場合は、
            // これまでにpushingsに追加したものも含めて一切押せない
            pushings.clear();
            return;
          }
          // マージできる場合は、一気に押せるオブジェクト（pushings）はここまで
          if (toToObj.isSameTypeLevel(toObj) && toObj.mergable) {
            stopBecauseMergeOrDrill = true;
          }
        } else {
          // 押せない場合
          break;
        }
        // 押すオブジェクトリストに追加
        pushings.add(stage.boxes.firstWhere((element) => element.pos == to));
        // オブジェクトの移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints.add(toTo);
        if (stopBecauseMergeOrDrill) {
          // マージする/ドリルでブロックを壊す場合
          break;
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
      stage.objFactory.setPosition(this, offset: offset);
      // TODO: 箱の方に実装？
      for (final pushing in pushings) {
        // 押している箱の位置変更
        stage.objFactory.setPosition(pushing, offset: offset);
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        final Point to = pos + moving.point;
        Point toTo = to + moving.point;
        // プレーヤー位置更新
        // ※merge()より前で更新することで、敵出現位置を、プレイヤーの目前にさせない
        pos = to.copy();
        stage.objFactory.setPosition(this);

        // 押したオブジェクト位置更新
        // TODO:箱の方に実装？
        for (final pushing in pushings) {
          // 押した先のオブジェクトを調べる
          if (pushing.mergable && pushing.isSameTypeLevel(stage.get(toTo))) {
            // マージ
            stage.merge(toTo, pushing, gameWorld);
          }
          // 押したものの位置を設定
          pushing.pos = toTo;
          stage.objFactory.setPosition(pushing);
          if (pushing.type == StageObjType.drill && executing) {
            // ドリル使用時
            // ドリルのオブジェクトレベルダウン、0になったら消す
            pushing.level--;
            if (pushing.level <= 0) {
              gameWorld.remove(pushing.animationComponent);
              stage.boxes.remove(pushing);
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
            stage.objFactory.setPosition(this);
          }
        }

        // 各種移動中変数初期化
        moving = Move.none;
        pushings.clear();
        movingAmount = 0;
        executing = false;
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
  bool get mergable => false;

  @override
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;
}
