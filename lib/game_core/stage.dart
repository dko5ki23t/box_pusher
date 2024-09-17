import 'dart:math';

import 'package:box_pusher/game_core/stage_objs/box.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/wall.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:logger/logger.dart';

/// 移動
enum Move {
  none,
  left,
  right,
  up,
  down,
}

extension MoveExtent on Move {
  /// 対応する座標
  Point get point {
    switch (this) {
      case Move.none:
        return Point(0, 0);
      case Move.left:
        return Point(-1, 0);
      case Move.right:
        return Point(1, 0);
      case Move.up:
        return Point(0, -1);
      case Move.down:
        return Point(0, 1);
    }
  }

  /// 対応するベクトル
  Vector2 get vector {
    switch (this) {
      case Move.none:
        return Vector2(0, 0);
      case Move.left:
        return Vector2(-1.0, 0);
      case Move.right:
        return Vector2(1.0, 0);
      case Move.up:
        return Vector2(0, -1.0);
      case Move.down:
        return Vector2(0, 1.0);
    }
  }
}

/// 移動履歴
class MoveHistory {
  final bool boxMoved;
  final Move move;

  MoveHistory({
    required this.boxMoved,
    required this.move,
  });
}

class StageObjFactory {
  final Map<StageObjType, Sprite> stageSprites;

  StageObjFactory({
    required this.stageSprites,
  });

  StageObj create({required StageObjTypeLevel typeLevel, required Point pos}) {
    int priority = Stage.staticPriority;
    if (typeLevel.type == StageObjType.box ||
        typeLevel.type == StageObjType.player ||
        typeLevel.type == StageObjType.spike) {
      priority = Stage.dynamicPriority;
    }

    final sprite = SpriteComponent(
      sprite: stageSprites[typeLevel.type],
      priority: priority,
      children: [
        if (typeLevel.level > 1)
          AlignComponent(
            alignment: Anchor.center,
            child: TextComponent(
              text: typeLevel.level.toString(),
              textRenderer: TextPaint(
                style: const TextStyle(
                  fontFamily: 'Aboreto',
                  color: Color(0xff000000),
                ),
              ),
            ),
          ),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (/*offset +*/
          Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
              Stage.cellSize / 2),
    );

    switch (typeLevel.type) {
      case StageObjType.none:
      case StageObjType.goal: // TODO:goalは消す予定
        return Floor(sprite: sprite, pos: pos);
      case StageObjType.box:
      case StageObjType.boxOnGoal: // TODO: goalは消す予定
        return Box(sprite: sprite, pos: pos);
      case StageObjType.player:
      case StageObjType.playerOnGoal: // TODO: goalは消す予定
        return Player(sprite: sprite, pos: pos);
      case StageObjType.wall:
        return Wall(sprite: sprite, pos: pos);
      case StageObjType.spike:
        return Spike(sprite: sprite, pos: pos);
    }
  }

  Sprite getSprite(StageObjType type) => stageSprites[type]!;

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.sprite.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }
}

class Point {
  int x = 0;
  int y = 0;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Point &&
            runtimeType == other.runtimeType &&
            x == other.x &&
            y == other.y);
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Point operator -() {
    return Point(-x, -y);
  }

  Point operator +(Point a) {
    return Point(x + a.x, y + a.y);
  }

  Point operator -(Point a) {
    return Point(x - a.x, y - a.y);
  }

  Point copy() => Point(x, y);

  int distance() {
    return (x.abs() + y.abs());
  }
}

class MovePath {
  List<Point> path = [];
  int fCount = 0;
}

class Stage {
  /// マスのサイズ
  static Vector2 get cellSize => Vector2(32.0, 32.0);

  /// プレイヤーの移動速度
  static const double playerSpeed = 96.0;

  /// 静止物のzインデックス
  static const staticPriority = 1;

  /// 動く物のzインデックス
  static const dynamicPriority = 2;

  final Image stageImg;

  /// プレイヤーの位置
  //Point playerPos = Point(-1, -1);

  late StageObjFactory objFactory;

  /// 静止物
  Map<Point, StageObj> staticObjs = {};

  /// 箱
  List<StageObj> boxes = [];

  /// 敵
  List<StageObj> enemies = [];

  /// プレイヤー
  late StageObj player;

  /// プレイヤーが移動中かどうか
  //bool isPlayerMoving = false;

  /// 箱が移動中かどうか
  //bool isBoxMoving = false;

  /// 移動中の箱
  //StageObj? movingBox;

  /// 移動量
  //double movingAmount = 0.0;

  /// 移動中の方向
  //Move movingTo = Move.none;

  /// ステージの左上座標(プレイヤーの動きにつれて拡張されていく)
  Point stageLT = Point(0, 0);

  /// ステージの右下座標(プレイヤーの動きにつれて拡張されていく)
  Point stageRB = Point(0, 0);

  Stage(this.stageImg) {
    final Map<StageObjType, Sprite> stageSprites = {};
    stageSprites[StageObjType.none] =
        Sprite(stageImg, srcPosition: Vector2(0, 0), srcSize: cellSize);
    stageSprites[StageObjType.wall] =
        Sprite(stageImg, srcPosition: Vector2(160, 0), srcSize: cellSize);
    stageSprites[StageObjType.goal] =
        Sprite(stageImg, srcPosition: Vector2(32, 0), srcSize: cellSize);
    stageSprites[StageObjType.box] =
        Sprite(stageImg, srcPosition: Vector2(96, 0), srcSize: cellSize);
    stageSprites[StageObjType.player] =
        Sprite(stageImg, srcPosition: Vector2(128, 0), srcSize: cellSize);
    stageSprites[StageObjType.spike] =
        Sprite(stageImg, srcPosition: Vector2(192, 0), srcSize: cellSize);

    objFactory = StageObjFactory(stageSprites: stageSprites);
  }

  /// デフォルトのステージを生成する
  void setDefault(World gameWorld, CameraComponent camera) {
    stageLT = Point(-6, -20);
    stageRB = Point(6, 20);
    //playerPos = Point(0, 0);
    _drawWithObjsInfo(gameWorld, camera);
  }

  /// 初期化
  void initialize(void Function() removeAll) {
    // TODO: 合ってる？
    player.moving = Move.none;
    player.pushing = null;
    player.movingAmount = 0;
    boxes.clear();
    removeAll();
  }

  // TODO:不要？
  /// ステージを初期状態に戻す
  void reset() {
    //objsInfo = [...initialObjsInfo];
    //playerPos = initialPlayerPos.copy();
    // 荷物位置初期化
    // TODO
    /*
    for (final box in boxes) {
      box.current = box.initial;
      // 描画
      stage.setCellPosition(box.sprite, box.current.x, box.current.y, 0, 0);
    }
    */
    // プレイヤー描画
    objFactory.setPosition(player);

    // 各種変数初期化
    player.pushing = null;
    player.moving = Move.none;
    player.movingAmount = 0;
  }

  void logInitialStage() {
    String output = '';
    /*for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (Point(x, y) == initialPlayerPos) {
          if (initialObjsInfo[y][x].type == StageObjType.goal) {
            output += symboleToStr(StageObjType.playerOnGoal);
          } else {
            output += symboleToStr(StageObjType.player);
          }
        } else {
          output += symboleToStr(initialObjsInfo[y][x].type);
        }
      }
      if (y < height - 1) output += '\n';
    }
    final logger = Logger();
    logger.i(output);*/
  }

  void logCurrentStage() {
    String output = '';
    /*for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (Point(x, y) == playerPos) {
          if (objsInfo[y][x].type == StageObjType.goal) {
            output += symboleToStr(StageObjType.playerOnGoal);
          } else {
            output += symboleToStr(StageObjType.player);
          }
        } else {
          output += symboleToStr(objsInfo[y][x].type);
        }
      }
      if (y < height - 1) output += '\n';
    }
    final logger = Logger();
    logger.i(output);*/
  }

  List<List<int>> combination(List<int> list, int n) {
    return n == 1
        ? list.map((el) => [el]).toList()
        : list.asMap().entries.expand((entry) {
            return combination(list.sublist(entry.key + 1), n - 1)
                .map((el) => [entry.value] + el)
                .toList();
          }).toList();
  }

  void explode(Point pos, StageObj box, World gameWorld) {
    // 引数位置を中心として周囲を爆破する
    final List<Point> breaked = [];
    for (int y = pos.y - 1; y < pos.y + 2; y++) {
      for (int x = pos.x - 1; x < pos.x + 2; x++) {
        if (x < stageLT.x || x > stageRB.x) continue;
        if (y < stageLT.y || y > stageRB.y) continue;
        final p = Point(x, y);
        if (p == pos) continue;
        if (get(p).type == StageObjType.wall &&
            get(p).level <= box.typeLevel.level) {
          setType(p, StageObjType.none);
          staticObjs[p]!.sprite.sprite =
              objFactory.getSprite(StageObjType.none);
          breaked.add(p);
        }
      }
    }
    // 破壊した壁の数/2(切り上げ)個の箱/敵を出現させる
    final boxAppears = breaked.sample((breaked.length / 2).ceil());
    final List<StageObj> adding = [];
    bool hasAppearedEnemy = false;
    for (final boxAppear in boxAppears) {
      // プレイヤーの位置から2以上離れている場合、1/2の確率、最大1匹で敵が出現
      final appearEnemy = Random().nextBool();
      if (appearEnemy &&
          (player.pos - boxAppear).distance() > 1 &&
          !hasAppearedEnemy) {
        adding.add(objFactory.create(
            typeLevel: StageObjTypeLevel(type: StageObjType.spike, level: 1),
            pos: boxAppear));
        enemies.add(adding.last);
        hasAppearedEnemy = true;
      } else {
        setType(boxAppear, StageObjType.box, level: 1);
        adding.add(objFactory.create(
            typeLevel: StageObjTypeLevel(type: StageObjType.box, level: 1),
            pos: boxAppear));
        boxes.add(adding.last);
      }
    }
    gameWorld.addAll([for (final e in adding) e.sprite]);
    // 当該位置の箱を消す
    final mergedBox = boxes.firstWhere((element) => element.pos == pos);
    gameWorld.remove(mergedBox.sprite);
    boxes.remove(mergedBox);
    // 移動した箱のレベルを上げる
    box.sprite.removeAll(box.sprite.children);
    box.sprite.add(
      AlignComponent(
        alignment: Anchor.center,
        child: TextComponent(
          text: (++box.typeLevel.level).toString(),
          textRenderer: TextPaint(
            style: const TextStyle(
              fontFamily: 'Aboreto',
              color: Color(0xff000000),
            ),
          ),
        ),
      ),
    );
  }

  StageObjTypeLevel get(Point p) {
    final box = boxes.firstWhereOrNull((element) => element.pos == p);
    final enemy = enemies.firstWhereOrNull((element) => element.pos == p);
    if (enemy != null) {
      return enemy.typeLevel;
    } else if (box != null) {
      return box.typeLevel;
    } else {
      return staticObjs[p]!.typeLevel;
    }
    //return objsInfo[p.y][p.x];
  }

  void setType(Point p, StageObjType type, {int? level}) {
    staticObjs[p]!.typeLevel.type = type;
    if (level != null) staticObjs[p]!.typeLevel.level = level;
  }

  void _drawWithObjsInfo(World gameWorld, CameraComponent camera) {
    staticObjs.clear();
    for (int y = stageLT.y; y <= stageRB.y; y++) {
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        StageObjTypeLevel objType = StageObjTypeLevel(type: StageObjType.wall);
        if (x == 0 && y == 0) {
          objType.type = StageObjType.none;
        } else if (x == 0 && -2 <= y && y <= 2) {
          objType.type = StageObjType.box;
        } else if (y == 0 && -2 <= x && x <= 2) {
          objType.type = StageObjType.box;
        }
        switch (objType.type) {
          case StageObjType.none:
          case StageObjType.box:
          case StageObjType.player:
          case StageObjType.spike:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.none, level: objType.level),
                pos: Point(x, y));
            break;
          case StageObjType.wall:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.wall, level: objType.level),
                pos: Point(x, y));
            break;
          case StageObjType.goal:
          case StageObjType.boxOnGoal:
          case StageObjType.playerOnGoal:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.goal, level: objType.level),
                pos: Point(x, y));
            break;
        }
        if (objType.type == StageObjType.box ||
            objType.type == StageObjType.boxOnGoal) {
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.box, level: objType.level),
              pos: Point(x, y)));
        } else if (objType.type == StageObjType.spike) {
          enemies.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.spike, level: objType.level),
              pos: Point(x, y)));
        }
      }
    }
    gameWorld.addAll([for (final e in staticObjs.values) e.sprite]);
    gameWorld.addAll([for (final e in boxes) e.sprite]);
    gameWorld.addAll([for (final e in enemies) e.sprite]);

    player = objFactory.create(
        typeLevel: StageObjTypeLevel(type: StageObjType.player, level: 1),
        pos: Point(0, 0));
    gameWorld.addAll([player.sprite]);
    camera.follow(player.sprite);
  }

  void update(
      double dt, Move moveInput, World gameWorld, CameraComponent camera) {
    // クリア済みなら何もしない
    if (isClear()) return;
    Move before = player.moving;
    final List<Point> prohibitedPoints = [];
    // プレイヤー更新
    player.update(
        dt, moveInput, gameWorld, camera, this, false, prohibitedPoints);
    // 敵更新
    bool playerStartMoving = before == Move.none && player.moving != Move.none;
    for (final enemy in enemies) {
      enemy.update(dt, player.moving, gameWorld, camera, this,
          playerStartMoving, prohibitedPoints);
    }

    // 移動完了時
    if (before != Move.none && player.moving == Move.none) {
      // 移動によって新たな座標が見えそうなら追加する
      // 左端
      if (camera.canSee(staticObjs[Point(stageLT.x, player.pos.y)]!.sprite)) {
        stageLT.x--;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageLT.x, y));
          staticObjs[Point(stageLT.x, y)] = adding;
          gameWorld.add(adding.sprite);
        }
      }
      // 右端
      if (camera.canSee(staticObjs[Point(stageRB.x, player.pos.y)]!.sprite)) {
        stageRB.x++;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageRB.x, y));
          staticObjs[Point(stageRB.x, y)] = adding;
          gameWorld.add(adding.sprite);
        }
      }
      // 上端
      if (camera.canSee(staticObjs[Point(player.pos.x, stageLT.y)]!.sprite)) {
        stageLT.y--;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageLT.y));
          staticObjs[Point(x, stageLT.y)] = adding;
          gameWorld.add(adding.sprite);
        }
      }
      // 下端
      if (camera.canSee(staticObjs[Point(player.pos.x, stageRB.y)]!.sprite)) {
        stageRB.y++;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageRB.y));
          staticObjs[Point(x, stageRB.y)] = adding;
          gameWorld.add(adding.sprite);
        }
      }
    }
  }

  bool isClear() {
    return false;
  }
}
