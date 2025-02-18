import 'dart:math';

import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:push_and_merge/game_core/stage_objs/block.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Belt extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'belt.png';

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    levelToAnimationsS = {
      0: {
        for (final move in MoveExtent.straights)
          move: SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      1: {
        Move.up: SpriteAnimation.fromFrameData(
          baseImg,
          SpriteAnimationData.sequenced(
              amount: 4,
              stepTime: Stage.objectStepTime,
              textureSize: Stage.cellSize),
        ),
      },
    };
  }

  void _setAngle() {
    switch (vector) {
      case Move.right:
        animationComponent.angle = 0.5 * pi;
        break;
      case Move.up:
        animationComponent.angle = 0;
        break;
      case Move.down:
        animationComponent.angle = pi;
        break;
      case Move.left:
      default:
        animationComponent.angle = -0.5 * pi;
        break;
    }
  }

  /// レベル
  @override
  set level(int l) {
    super.level = l;
    int key = levelToAnimations.containsKey(level) ? level : 0;
    animationComponent.animation = levelToAnimations[key]![Move.up];
    _setAngle();
  }

  /// コンベアの向き
  @override
  set vector(Move v) {
    super.vector = v;
    int key = levelToAnimations.containsKey(level) ? level : 0;
    animationComponent.animation = levelToAnimations[key]![Move.up];
    _setAngle();
  }

  Belt({
    required super.pos,
    required Move vector,
    required super.savedArg,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.staticPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.belt,
            level: level,
          ),
          vector: vector,
        );

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
    bool playerEndMoving,
    Map<Point, Move> prohibitedPoints,
  ) {
    // プレイヤー移動開始時
    if (playerStartMoving) {
      final obj = stage.get(pos);
      final to = pos + vector.point;
      final toObj = stage.get(to);
      if (obj.beltMove) {
        // コンベア上のオブジェクトが動かせる場合
        // ドリルの場合は少し違う処理
        if (obj.type == StageObjType.drill &&
            toObj.type == StageObjType.block) {
          // 押した先がブロックなら即座に破壊
          // 破壊するブロックのアニメーションを描画
          gameWorld.add((toObj as Block).createBreakingBlock());
          stage.setStaticType(to, StageObjType.none);
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
        prohibitedPoints[to] = Move.none;
        // 上にオブジェクトがなくなったコンベアには、押した方向と逆方向からの移動は禁ずる
        if (!prohibitedPoints.containsKey(pos)) {
          prohibitedPoints[pos] = vector.oppsite;
        }
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
        stage.setObjectPosition(pushing, offset: offset);
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
            int mergePow = Config.getMergePower(0, pushing);
            final affect = MergeAffect(
              basePoint: to,
              range: PointRectRange(to + Point(-1, -1), to + Point(1, 1)),
              canBreakBlockFunc: (block) =>
                  Config.canBreakBlock(block, mergePow),
              enemyDamage: Config().debugEnemyDamageInMerge,
            );
            stage.merge(
              to,
              pushing,
              gameWorld,
              affect,
            );
          }
          // 押したものの位置を設定
          pushing.pos = to;
          stage.setObjectPosition(pushing);
          if (pushing.type == StageObjType.drill && executing) {
            // ドリル使用時
            // ドリルのオブジェクトレベルダウン、0になったら消す
            pushing.level--;
            if (pushing.level <= 0) {
              pushing.remove();
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
            stage.setObjectPosition(this);
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
  bool get playerMovable => true;

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
  bool get beltMove => false;

  @override
  bool get hasVector => true;
}
