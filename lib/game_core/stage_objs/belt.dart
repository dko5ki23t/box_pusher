import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';

class Belt extends StageObj {
  Move _vector = Move.left;

  /// コンベアの向き
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    switch (_vector) {
      case Move.right:
        type = StageObjType.beltR;
        break;
      case Move.up:
        type = StageObjType.beltU;
        break;
      case Move.down:
        type = StageObjType.beltD;
        break;
      case Move.left:
      default:
        type = StageObjType.beltL;
        break;
    }
  }

  Belt({
    required super.animationComponent,
    required super.levelToAnimations,
    required super.pos,
    required Move vector,
    int level = 1,
  }) : super(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.beltL,
            level: level,
          ),
        ) {
    this.vector = vector;
  }

  /// 押しているオブジェクトを「行使」しているかどうか
  /// ex.) ドリルによるブロックの破壊
  bool executing = false;

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
    // プレイヤー移動開始時
    if (playerStartMoving) {
      final obj = stage.get(pos);
      final to = pos + vector.point;
      final toObj = stage.get(to);
      if (obj.beltMove) {
        // コンベア上のオブジェクトが動かせる場合
        // ドリルの場合は少し違う処理
        if (obj.type == StageObjType.drill && toObj.type == StageObjType.wall) {
          // 押した先がブロックなら即座に破壊
          stage.setStaticType(to, StageObjType.none, gameWorld);
          // 破壊したブロックのアニメーションを描画
          gameWorld.add(stage.objFactory.createBreakingBlock(to));
          executing = true;
        } else if (toObj.stopping ||
            (!toObj.puttable &&
                (!obj.isSameTypeLevel(toObj) || !obj.mergable))) {
          // 押した先が敵等 or マージできないオブジェクトの場合は押せない
          pushings.clear();
          return;
        }
        // 押すオブジェクトリストに追加
        pushings.add(obj);
        // オブジェクトの移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints.add(to);
      }
    }

    if (pushings.isNotEmpty) {
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      Vector2 offset = vector.vector * movingAmount;
      for (final pushing in pushings) {
        // 押しているオブジェクトの位置変更
        stage.objFactory.setPosition(pushing, offset: offset);
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        final Point to = pos + vector.point;
        // 押したオブジェクト位置更新
        // TODO:箱の方に実装？
        for (final pushing in pushings) {
          // 押した先のオブジェクトを調べる
          if (pushing.mergable && pushing.isSameTypeLevel(stage.get(to))) {
            // マージ
            stage.merge(to, pushing, gameWorld);
          }
          // 押したものの位置を設定
          pushing.pos = to;
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
        }

        // TODO: オブジェクトのワープどうする？
        /*if (stage.get(to).type == StageObjType.warp) {
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
        }*/

        // 各種移動中変数初期化
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
  bool get puttable => true;

  @override
  bool get mergable => false;

  @override
  int get maxLevel => 1;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;
}
