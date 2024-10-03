import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Player extends StageObj {
  Player({
    required super.animation,
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
      StageObjTypeLevel toObj = stage.get(to);
      StageObjTypeLevel toToObj = stage.get(toTo);

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
        // 押すオブジェクトがあるか
        if (toObj.type == StageObjType.box || toObj.type == StageObjType.trap) {
          // TODO:以下、各typeに属性として持たせるべき
          const stopTypes = [
            StageObjType.wall,
            StageObjType.spike,
          ];
          const puttableTypes = [
            StageObjType.none,
          ];
          // 押した先がブロック等 or 一気に押せる数の端だがマージできないオブジェクトの場合は、
          // これまでにpushingsに追加したものも含めて一切押せない
          if (stopTypes.contains(toToObj.type) ||
              (i == end - 1 &&
                  !puttableTypes.contains(toToObj.type) &&
                  toObj != toToObj)) {
            pushings.clear();
            return;
          }
          // マージできる場合は、一気に押せるオブジェクト（pushings）はここまで
          if (toToObj == toObj) {
            stopBecauseMergeOrDrill = true;
          }
        } else if (toObj.type == StageObjType.drill) {
          // 押した先が敵等 or 一気に押せる数の端だがマージできないオブジェクトの場合は、
          // これまでにpushingsに追加したものも含めて一切押せない
          // TODO:以下、各typeに属性として持たせるべき
          const stopTypes = [
            StageObjType.spike,
          ];
          const puttableTypes = [
            StageObjType.none,
          ];
          // 押した先がブロックなら即座に破壊、かつマージと同様、一気に押せるオブジェクト（pushings）はここまで
          if (toToObj.type == StageObjType.wall) {
            stage.setStaticType(toTo, StageObjType.none);
            executing = true;
            stopBecauseMergeOrDrill = true;
          } else if (stopTypes.contains(toToObj.type) ||
              (i == end - 1 &&
                  !puttableTypes.contains(toToObj.type) &&
                  toObj != toToObj)) {
            pushings.clear();
            return;
          }
          // マージできる場合は、一気に押せるオブジェクト（pushings）はここまで
          if (toToObj == toObj) {
            stopBecauseMergeOrDrill = true;
          }
        } else {
          // 押すものがない場合
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
        Point to = pos + moving.point;
        Point toTo = to + moving.point;
        // プレーヤー位置更新
        // ※explode()より前で更新することで、敵出現位置を、プレイヤーの目前にさせない
        pos = to.copy();
        stage.objFactory.setPosition(this);

        // 押したオブジェクト位置更新
        // TODO:箱の方に実装？
        for (final pushing in pushings) {
          // 押した先のオブジェクトを調べる
          switch (stage.get(toTo).type) {
            case StageObjType.none:
              break;
            case StageObjType.box:
            case StageObjType.trap:
            case StageObjType.drill:
              // マージ
              if (pushing.typeLevel == stage.get(toTo)) {
                stage.explode(toTo, pushing, gameWorld);
              }
              break;
            default:
              // ありえない
              //HALT("fatal error");
              break;
          }
          // 押したものの位置を設定
          pushing.pos = toTo;
          stage.objFactory.setPosition(pushing);
          if (pushing.typeLevel.type == StageObjType.drill && executing) {
            // ドリル使用時
            // ドリルのオブジェクトレベルダウン、0になったら消す
            pushing.typeLevel.level--;
            if (pushing.typeLevel.level <= 0) {
              gameWorld.remove(pushing.animation);
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
          stage.setStaticType(to, StageObjType.none);
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
}
