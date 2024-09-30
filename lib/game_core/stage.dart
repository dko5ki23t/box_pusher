import 'dart:math';

import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage_objs/box.dart';
import 'package:box_pusher/game_core/stage_objs/drill.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/wall.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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
  upLeft,
  upRight,
  downLeft,
  downRight,
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
      case Move.upLeft:
        return Point(-1, -1);
      case Move.upRight:
        return Point(1, -1);
      case Move.downLeft:
        return Point(-1, 1);
      case Move.downRight:
        return Point(1, 1);
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
      case Move.upLeft:
        return Vector2(-1.0, -1.0);
      case Move.upRight:
        return Vector2(1.0, -1.0);
      case Move.downLeft:
        return Vector2(-1.0, 1.0);
      case Move.downRight:
        return Vector2(1.0, 1.0);
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
  final Map<StageObjType, SpriteAnimation> stageSpriteAnimatinos;
  final SpriteAnimation breakingBlockAnimation;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラ
  EffectController? baseMergable;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラが逆再生中かどうか
  bool isBaseMergableReverse = false;

  void setReverse() {
    isBaseMergableReverse = !isBaseMergableReverse;
  }

  StageObjFactory({
    required this.stageSpriteAnimatinos,
    required this.breakingBlockAnimation,
  });

  StageObj create({required StageObjTypeLevel typeLevel, required Point pos}) {
    int priority = Stage.staticPriority;
    switch (typeLevel.type) {
      case StageObjType.box:
      case StageObjType.trap:
      case StageObjType.drill:
      case StageObjType.player:
      case StageObjType.spike:
        priority = Stage.dynamicPriority;
        break;
      case StageObjType.none:
      case StageObjType.wall:
        priority = Stage.staticPriority;
    }

    final animation = SpriteAnimationComponent(
      animation: stageSpriteAnimatinos[typeLevel.type],
      priority: priority,
      scale: (typeLevel.type == StageObjType.box ||
                  typeLevel.type == StageObjType.trap ||
                  typeLevel.type == StageObjType.drill) &&
              isBaseMergableReverse
          ? Vector2.all(Stage.mergableZoomRate)
          : Vector2.all(1.0),
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: TextComponent(
            text: typeLevel.level > 1 ? typeLevel.level.toString() : '',
            textRenderer: TextPaint(
              style: const TextStyle(
                fontFamily: 'Aboreto',
                color: Color(0xff000000),
              ),
            ),
          ),
        ),
        if (typeLevel.type == StageObjType.box ||
            typeLevel.type == StageObjType.trap ||
            typeLevel.type == StageObjType.drill)
          ScaleEffect.by(
            isBaseMergableReverse
                ? Vector2.all(1.0 / Stage.mergableZoomRate)
                : Vector2.all(Stage.mergableZoomRate),
            EffectController(
              onMax: baseMergable == null ? setReverse : null,
              onMin: baseMergable == null ? setReverse : null,
              duration: Stage.mergableZoomDuration,
              reverseDuration: Stage.mergableZoomDuration,
              infinite: true,
            ),
          ),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
    if (typeLevel.type == StageObjType.box ||
        typeLevel.type == StageObjType.trap ||
        typeLevel.type == StageObjType.drill) {
      final controller = (animation.children.last as Effect).controller;
      baseMergable ??= controller;
      controller.advance((isBaseMergableReverse
              ? (1.0 - baseMergable!.progress)
              : baseMergable!.progress) *
          Stage.mergableZoomDuration);
    }

    switch (typeLevel.type) {
      case StageObjType.none:
        return Floor(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.box:
        return Box(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.trap:
        return Trap(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.player:
        return Player(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.wall:
        return Wall(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.spike:
        return Spike(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.drill:
        return Drill(animation: animation, pos: pos, level: typeLevel.level);
    }
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
        typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
        pos: Point.decode(src['pos']));
  }

  SpriteAnimationComponent createBreakingBlock(Point pos) {
    return SpriteAnimationComponent(
      animation: breakingBlockAnimation,
      priority: Stage.dynamicPriority,
      children: [
        OpacityEffect.by(
          -1.0,
          EffectController(duration: 0.5),
        ),
        RemoveEffect(delay: 1.0),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
  }

  SpriteAnimation getSpriteAnimation(StageObjType type) =>
      stageSpriteAnimatinos[type]!;

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.animation.position =
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

  String encode() {
    return "$x,$y";
  }

  static Point decode(String str) {
    final xy = str.split(',');
    return Point(int.parse(xy[0]), int.parse(xy[1]));
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

  /// 常に動くオブジェクトのアニメーションステップ時間
  static const double objectStepTime = 0.4;

  /// マージ可能なオブジェクトの拡大/縮小の時間(s)
  static const double mergableZoomDuration = 0.8;

  /// マージ可能なオブジェクトの拡大/縮小率
  static const double mergableZoomRate = 0.9;

  /// 静止物のzインデックス
  static const staticPriority = 1;

  /// 動く物のzインデックス
  static const dynamicPriority = 2;

  final Image stageImg;
  final Image playerImg;
  final Image spikeImg;
  final Image blockImg;

  late StageObjFactory objFactory;

  /// 静止物
  Map<Point, StageObj> staticObjs = {};

  // TODO: あまり美しくないのでできれば廃止する
  /// effectを追加する際、動きを合わせる基となるエフェクトを持つStageObj（不可視）
  List<StageObj> effectBase = [];

  /// 箱
  List<StageObj> boxes = [];

  /// 敵
  List<StageObj> enemies = [];

  /// プレイヤー
  late StageObj player;

  /// ゲームオーバーになったかどうか
  bool isGameover = false;

  /// ステージの左上座標(プレイヤーの動きにつれて拡張されていく)
  Point stageLT = Point(0, 0);

  /// ステージの右下座標(プレイヤーの動きにつれて拡張されていく)
  Point stageRB = Point(0, 0);

  /// スコア
  int score = 0;

  Stage(
    this.stageImg,
    this.playerImg,
    this.spikeImg,
    this.blockImg,
  ) {
    final Map<StageObjType, SpriteAnimation> stageSprites = {};
    stageSprites[StageObjType.none] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(0, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.wall] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(160, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.trap] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(32, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.box] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(96, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.player] = SpriteAnimation.fromFrameData(
      playerImg,
      SpriteAnimationData.sequenced(
          amount: 2, stepTime: objectStepTime, textureSize: cellSize),
    );
    stageSprites[StageObjType.spike] = SpriteAnimation.fromFrameData(
      spikeImg,
      SpriteAnimationData.sequenced(
          amount: 2, stepTime: objectStepTime, textureSize: cellSize),
    );
    stageSprites[StageObjType.drill] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(224, 0), srcSize: cellSize)],
        stepTime: 1.0);

    objFactory = StageObjFactory(
      stageSpriteAnimatinos: stageSprites,
      breakingBlockAnimation: SpriteAnimation.spriteList(
          [Sprite(blockImg, srcPosition: Vector2(32, 0), srcSize: cellSize)],
          stepTime: 1.0),
    );
  }

  /// デフォルトのステージを生成する
  void setDefault(
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    effectBase = [
      objFactory.create(
          typeLevel: StageObjTypeLevel(type: StageObjType.box, level: 1),
          pos: Point(0, 0))
    ];
    effectBase.first.animation.opacity = 0.0;
    gameWorld.add(effectBase.first.animation);
    // 前回のステージ情報が保存されているなら
    if (stageData.containsKey('score')) {
      score = stageData['score'];
      stageLT = Point.decode(stageData['stageLT']);
      stageRB = Point.decode(stageData['stageRB']);
      staticObjs.clear();
      for (final entry
          in (stageData['staticObjs'] as Map<String, dynamic>).entries) {
        staticObjs[Point.decode(entry.key)] =
            objFactory.createFromMap(entry.value);
      }
      boxes = [
        for (final e in stageData['boxes'] as List<dynamic>)
          objFactory.createFromMap(e)
      ];
      enemies = [
        for (final e in stageData['enemies'] as List<dynamic>)
          objFactory.createFromMap(e)
      ];
      gameWorld.addAll([for (final e in staticObjs.values) e.animation]);
      gameWorld.addAll([for (final e in boxes) e.animation]);
      gameWorld.addAll([for (final e in enemies) e.animation]);
      player = objFactory.createFromMap(stageData['player']);
      gameWorld.addAll([player.animation]);
      camera.follow(player.animation);
    } else {
      stageLT = Point(-6, -20);
      stageRB = Point(6, 20);
      //playerPos = Point(0, 0);
      _drawWithObjsInfo(gameWorld, camera);
    }
  }

  /// 初期化
  void initialize(void Function() removeAll) {
    // TODO: 合ってる？
    player.moving = Move.none;
    player.pushings.clear();
    player.movingAmount = 0;
    score = 0;
    isGameover = false;
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
    player.pushings.clear();
    player.moving = Move.none;
    player.movingAmount = 0;
    score = 0;
    isGameover = false;
  }

  Map<String, dynamic> getStageData() {
    final Map<String, dynamic> ret = {};
    ret['score'] = score;
    ret['stageLT'] = stageLT.encode();
    ret['stageRB'] = stageRB.encode();
    final Map<String, dynamic> staticObjsMap = {};
    for (final entry in staticObjs.entries) {
      staticObjsMap[entry.key.encode()] = entry.value.encode();
    }
    ret['staticObjs'] = staticObjsMap;
    final List<Map<String, dynamic>> boxesList = [
      for (final e in boxes) e.encode()
    ];
    ret['boxes'] = boxesList;
    final List<Map<String, dynamic>> enemiesList = [
      for (final e in enemies) e.encode()
    ];
    ret['enemies'] = enemiesList;
    ret['player'] = player.encode();
    return ret;
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
    // 引数位置を中心として周囲のブロックを爆破する
    final List<Point> breaked = [];
    final List<Component> breakingAnimations = [];
    for (int y = pos.y - 1; y < pos.y + 2; y++) {
      for (int x = pos.x - 1; x < pos.x + 2; x++) {
        if (x < stageLT.x || x > stageRB.x) continue;
        if (y < stageLT.y || y > stageRB.y) continue;
        final p = Point(x, y);
        if (p == pos) continue;
        if (get(p).type == StageObjType.wall &&
            get(p).level <= box.typeLevel.level) {
          setStaticType(p, StageObjType.none);
          breakingAnimations.add(objFactory.createBreakingBlock(p));
          breaked.add(p);
        }
      }
    }
    // 引数位置を元に、どういうオブジェクトが出現するか決定
    final distance = pos.distance();
    ObjInBlock pattern = ObjInBlock.jewel1_2;
    int jewelLevel = 1;
    for (final objInBlock in SettingVariables.objInBlockMap.entries) {
      if (objInBlock.key <= distance) {
        pattern = objInBlock.value;
      }
    }
    for (final level in SettingVariables.jewelLevelInBlockMap.entries) {
      if (level.key <= distance) {
        jewelLevel = level.value;
      }
    }
    final List<StageObj> adding = [];
    switch (pattern) {
      case ObjInBlock.jewel1_2:
        // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
        final jewelAppears = breaked.sample((breaked.length / 2).ceil());
        for (final jewelAppear in jewelAppears) {
          adding.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.box,
                level: jewelLevel,
              ),
              pos: jewelAppear));
          boxes.add(adding.last);
        }
        break;
      case ObjInBlock.jewel1_2SpikeOrTrap1:
        // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
        final jewelAppears = breaked.sample((breaked.length / 2).ceil());
        final breakedRemain = [...breaked];
        breakedRemain.removeWhere((element) => jewelAppears.contains(element));
        for (final jewelAppear in jewelAppears) {
          adding.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.box,
                level: jewelLevel,
              ),
              pos: jewelAppear));
          boxes.add(adding.last);
        }
        // 宝石出現以外の位置に最大1個の敵/罠を出現させる
        if (breakedRemain.isNotEmpty) {
          int spikeOrTrap = Random().nextInt(4);
          final appear = breakedRemain.sample(1).first;
          if (spikeOrTrap == 0) {
            adding.add(objFactory.create(
                typeLevel:
                    StageObjTypeLevel(type: StageObjType.spike, level: 1),
                pos: appear));
            enemies.add(adding.last);
          } else if (spikeOrTrap == 1) {
            adding.add(objFactory.create(
                typeLevel: StageObjTypeLevel(type: StageObjType.trap, level: 1),
                pos: appear));
            boxes.add(adding.last);
          }
        }
        break;
      case ObjInBlock.jewel1_2Drill1:
        // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
        final jewelAppears = breaked.sample((breaked.length / 2).ceil());
        final breakedRemain = [...breaked];
        breakedRemain.removeWhere((element) => jewelAppears.contains(element));
        for (final jewelAppear in jewelAppears) {
          adding.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.box,
                level: jewelLevel,
              ),
              pos: jewelAppear));
          boxes.add(adding.last);
        }
        // 宝石出現以外の位置に最大1個のドリルを出現させる
        if (breakedRemain.isNotEmpty) {
          bool drill = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (drill) {
            adding.add(objFactory.create(
                typeLevel:
                    StageObjTypeLevel(type: StageObjType.drill, level: 1),
                pos: appear));
            boxes.add(adding.last);
          }
        }
        break;
    }
    gameWorld.addAll([for (final e in adding) e.animation]);

    // 当該位置のオブジェクトを消す
    final merged = boxes.firstWhere((element) => element.pos == pos);
    gameWorld.remove(merged.animation);
    boxes.remove(merged);
    // 移動したオブジェクトのレベルを上げる
    (box.animation.children.first.children.first as TextComponent).text =
        (++box.typeLevel.level).toString();

    // 破壊したブロックのアニメーションを描画
    gameWorld.addAll(breakingAnimations);

    // スコア加算
    score += box.typeLevel.level * 100;
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
  }

  void setStaticType(Point p, StageObjType type, {int? level}) {
    staticObjs[p]!.typeLevel.type = type;
    if (level != null) staticObjs[p]!.typeLevel.level = level;
    staticObjs[p]!.animation.animation = objFactory.getSpriteAnimation(type);
  }

  void _drawWithObjsInfo(World gameWorld, CameraComponent camera) {
    staticObjs.clear();
    boxes.clear();
    enemies.clear();
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
          case StageObjType.trap:
          case StageObjType.player:
          case StageObjType.spike:
          case StageObjType.drill:
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
        }
        if (objType.type == StageObjType.box) {
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.box, level: objType.level),
              pos: Point(x, y)));
        } else if (objType.type == StageObjType.trap) {
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.trap, level: objType.level),
              pos: Point(x, y)));
        } else if (objType.type == StageObjType.drill) {
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.drill, level: objType.level),
              pos: Point(x, y)));
        } else if (objType.type == StageObjType.spike) {
          enemies.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.spike, level: objType.level),
              pos: Point(x, y)));
        }
      }
    }
    gameWorld.addAll([for (final e in staticObjs.values) e.animation]);
    gameWorld.addAll([for (final e in boxes) e.animation]);
    gameWorld.addAll([for (final e in enemies) e.animation]);

    player = objFactory.create(
        typeLevel: StageObjTypeLevel(type: StageObjType.player, level: 1),
        pos: Point(0, 0));
    gameWorld.addAll([player.animation]);
    camera.follow(player.animation);
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
    {
      // 同じレベルの敵同士が同じ位置になったらマージしてレベルアップ
      // TODO: 敵がお互いにすれ違ってマージしない場合あり
      final List<Point> mergingPosList = [];
      final List<StageObj> mergedEnemies = [];
      for (final enemy in enemies) {
        if (mergingPosList.contains(enemy.pos)) {
          continue;
        }
        final t = enemies.where((element) =>
            element != enemy &&
            element.pos == enemy.pos &&
            element.typeLevel.type == StageObjType.spike &&
            element.typeLevel.level == enemy.typeLevel.level);
        if (t.isNotEmpty) {
          mergingPosList.add(enemy.pos);
          mergedEnemies.add(enemy);
          // マージされた敵を削除
          gameWorld.remove(enemy.animation);
          // レベルを上げる
          t.first.animation.removeAll(t.first.animation.children);
          t.first.animation.add(
            AlignComponent(
              alignment: Anchor.center,
              child: TextComponent(
                text: (++t.first.typeLevel.level).toString(),
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
      }
      // マージされた敵を削除
      for (final enemy in mergedEnemies) {
        enemies.remove(enemy);
      }
    }
    // オブジェクト更新(罠：敵を倒す)
    // TODO: これらは他オブジェクトの移動完了時のみ動かせばよい
    for (final box in boxes) {
      box.update(dt, player.moving, gameWorld, camera, this, playerStartMoving,
          prohibitedPoints);
    }

    // 移動完了時
    if (before != Move.none && player.moving == Move.none) {
      // 移動によって新たな座標が見えそうなら追加する
      // 左端
      if (camera
          .canSee(staticObjs[Point(stageLT.x, player.pos.y)]!.animation)) {
        stageLT.x--;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageLT.x, y));
          staticObjs[Point(stageLT.x, y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 右端
      if (camera
          .canSee(staticObjs[Point(stageRB.x, player.pos.y)]!.animation)) {
        stageRB.x++;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageRB.x, y));
          staticObjs[Point(stageRB.x, y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 上端
      if (camera
          .canSee(staticObjs[Point(player.pos.x, stageLT.y)]!.animation)) {
        stageLT.y--;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageLT.y));
          staticObjs[Point(x, stageLT.y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 下端
      if (camera
          .canSee(staticObjs[Point(player.pos.x, stageRB.y)]!.animation)) {
        stageRB.y++;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageRB.y));
          staticObjs[Point(x, stageRB.y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
    }

    // ゲームオーバー判定
    for (final enemy in enemies) {
      if (player.pos == enemy.pos) {
        isGameover = true;
      }
    }
  }

  void setHandAbility(bool isOn) {
    if (isOn) {
      (player as Player).pushableNum = -1;
    } else {
      (player as Player).pushableNum = 1;
    }
  }

  bool getHandAbility() {
    return (player as Player).pushableNum == -1;
  }

  void setLegAbility(bool isOn) {
    (player as Player).isLegAbilityOn = isOn;
  }

  bool getLegAbility() {
    return (player as Player).isLegAbilityOn;
  }

  bool isClear() {
    return false;
  }
}
