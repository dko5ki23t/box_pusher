import 'dart:developer';
import 'dart:math' hide log;

import 'package:push_and_merge/audio.dart';
import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/archer.dart';
import 'package:push_and_merge/game_core/stage_objs/barrierman.dart';
import 'package:push_and_merge/game_core/stage_objs/belt.dart';
import 'package:push_and_merge/game_core/stage_objs/bomb.dart';
import 'package:push_and_merge/game_core/stage_objs/boneman.dart';
import 'package:push_and_merge/game_core/stage_objs/builder.dart';
import 'package:push_and_merge/game_core/stage_objs/canon.dart';
import 'package:push_and_merge/game_core/stage_objs/drill.dart';
import 'package:push_and_merge/game_core/stage_objs/fire.dart';
import 'package:push_and_merge/game_core/stage_objs/floor.dart';
import 'package:push_and_merge/game_core/stage_objs/block.dart';
import 'package:push_and_merge/game_core/stage_objs/ghost.dart';
import 'package:push_and_merge/game_core/stage_objs/girl.dart';
import 'package:push_and_merge/game_core/stage_objs/gorilla.dart';
import 'package:push_and_merge/game_core/stage_objs/guardian.dart';
import 'package:push_and_merge/game_core/stage_objs/jewel.dart';
import 'package:push_and_merge/game_core/stage_objs/kangaroo.dart';
import 'package:push_and_merge/game_core/stage_objs/magma.dart';
import 'package:push_and_merge/game_core/stage_objs/player.dart';
import 'package:push_and_merge/game_core/stage_objs/pusher.dart';
import 'package:push_and_merge/game_core/stage_objs/rabbit.dart';
import 'package:push_and_merge/game_core/stage_objs/shop.dart';
import 'package:push_and_merge/game_core/stage_objs/smoke.dart';
import 'package:push_and_merge/game_core/stage_objs/smoker.dart';
import 'package:push_and_merge/game_core/stage_objs/spike.dart';
import 'package:push_and_merge/game_core/stage_objs/spawner.dart';
import 'package:push_and_merge/game_core/stage_objs/swordsman.dart';
import 'package:push_and_merge/game_core/stage_objs/trap.dart';
import 'package:push_and_merge/game_core/stage_objs/treasure_box.dart';
import 'package:push_and_merge/game_core/stage_objs/turtle.dart';
import 'package:push_and_merge/game_core/stage_objs/warp.dart';
import 'package:push_and_merge/game_core/stage_objs/water.dart';
import 'package:push_and_merge/game_core/stage_objs/weight.dart';
import 'package:push_and_merge/game_core/stage_objs/wizard.dart';
import 'package:push_and_merge/game_core/tutorial.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flutter/foundation.dart';

/// ステージ上オブジェクトの種類
enum StageObjType {
  none,
  block,
  trap,
  jewel,
  player,
  spike, // とげの敵
  drill,
  treasureBox,
  warp,
  bomb,
  belt,
  guardian,
  water,
  magma,
  swordsman, // 剣を使う敵
  archer, // 弓を使う敵
  wizard, // 魔法を使う敵
  ghost, // オブジェクトをすり抜けて移動できる敵（ゴースト）
  fire, // ゴーストが残す炎（設置型）
  builder, // 一定間隔でブロックを置く敵
  pusher, // オブジェクトを押す敵
  smoker, // 周囲を見えづらく、プレイヤーの能力を使用不能にする煙を出す敵
  smoke,
  gorilla,
  rabbit,
  kangaroo,
  turtle,
  girl,
  shop,
  canon,
  spawner, // 敵を生み出す場
  boneman, // 骨の敵、倒すと押せるオブジェクト化、一定ターンで復活
  barrierman, // 範囲内の敵に一定以上ダメージを軽減させるバリアを展開する敵
  weight,
}

extension StageObjTypeExtent on StageObjType {
  static Map<StageObjType, String> strMap = {
    StageObjType.none: 'floor',
    StageObjType.block: 'block',
    StageObjType.trap: 'trap',
    StageObjType.jewel: 'jewel',
    StageObjType.player: 'player',
    StageObjType.spike: 'spike',
    StageObjType.drill: 'drill',
    StageObjType.treasureBox: 'treasure',
    StageObjType.warp: 'warp',
    StageObjType.bomb: 'bomb',
    StageObjType.belt: 'belt',
    StageObjType.guardian: 'guardian',
    StageObjType.water: 'water',
    StageObjType.magma: 'magma',
    StageObjType.swordsman: 'swordsman',
    StageObjType.archer: 'archer',
    StageObjType.wizard: 'wizard',
    StageObjType.ghost: 'ghost',
    StageObjType.fire: 'fire',
    StageObjType.builder: 'builder',
    StageObjType.pusher: 'pusher',
    StageObjType.smoker: 'smoker',
    StageObjType.smoke: 'smoke',
    StageObjType.gorilla: 'gorilla',
    StageObjType.rabbit: 'rabbit',
    StageObjType.kangaroo: 'kangaroo',
    StageObjType.turtle: 'turtle',
    StageObjType.girl: 'girl',
    StageObjType.shop: 'shop',
    StageObjType.canon: 'canon',
    StageObjType.spawner: 'spawner',
    StageObjType.boneman: 'boneman',
    StageObjType.barrierman: 'barrierman',
    StageObjType.weight: 'weight',
  };

  String get str => strMap[this]!;

  Type get type {
    switch (this) {
      case StageObjType.none:
        return Floor;
      case StageObjType.block:
        return Block;
      case StageObjType.trap:
        return Trap;
      case StageObjType.jewel:
        return Jewel;
      case StageObjType.player:
        return Player;
      case StageObjType.spike:
        return Spike;
      case StageObjType.drill:
        return Drill;
      case StageObjType.treasureBox:
        return TreasureBox;
      case StageObjType.warp:
        return Warp;
      case StageObjType.bomb:
        return Bomb;
      case StageObjType.belt:
        return Belt;
      case StageObjType.guardian:
        return Guardian;
      case StageObjType.water:
        return Water;
      case StageObjType.magma:
        return Magma;
      case StageObjType.swordsman:
        return Swordsman;
      case StageObjType.archer:
        return Archer;
      case StageObjType.wizard:
        return Wizard;
      case StageObjType.ghost:
        return Ghost;
      case StageObjType.fire:
        return Fire;
      case StageObjType.builder:
        return Builder;
      case StageObjType.pusher:
        return Pusher;
      case StageObjType.smoker:
        return Smoker;
      case StageObjType.smoke:
        return Smoke;
      case StageObjType.gorilla:
        return Gorilla;
      case StageObjType.rabbit:
        return Rabbit;
      case StageObjType.kangaroo:
        return Kangaroo;
      case StageObjType.turtle:
        return Turtle;
      case StageObjType.girl:
        return Girl;
      case StageObjType.shop:
        return Shop;
      case StageObjType.canon:
        return Canon;
      case StageObjType.spawner:
        return Spawner;
      case StageObjType.boneman:
        return Boneman;
      case StageObjType.barrierman:
        return Barrierman;
      case StageObjType.weight:
        return Weight;
    }
  }

  String get baseImageFileName {
    switch (this) {
      case StageObjType.none:
        return Floor.imageFileName;
      case StageObjType.block:
        return Block.imageFileName;
      case StageObjType.trap:
        return Trap.imageFileName;
      case StageObjType.jewel:
        return Jewel.imageFileName;
      case StageObjType.player:
        return Player.imageFileName;
      case StageObjType.spike:
        return Spike.imageFileName;
      case StageObjType.drill:
        return Drill.imageFileName;
      case StageObjType.treasureBox:
        return TreasureBox.imageFileName;
      case StageObjType.warp:
        return Warp.imageFileName;
      case StageObjType.bomb:
        return Bomb.imageFileName;
      case StageObjType.belt:
        return Belt.imageFileName;
      case StageObjType.guardian:
        return Guardian.imageFileName;
      case StageObjType.water:
        return Water.imageFileName;
      case StageObjType.magma:
        return Magma.imageFileName;
      case StageObjType.swordsman:
        return Swordsman.imageFileName;
      case StageObjType.archer:
        return Archer.imageFileName;
      case StageObjType.wizard:
        return Wizard.imageFileName;
      case StageObjType.ghost:
        return Ghost.imageFileName;
      case StageObjType.fire:
        return Fire.imageFileName;
      case StageObjType.builder:
        return Builder.imageFileName;
      case StageObjType.pusher:
        return Pusher.imageFileName;
      case StageObjType.smoker:
        return Smoker.imageFileName;
      case StageObjType.smoke:
        return Smoke.imageFileName;
      case StageObjType.gorilla:
        return Gorilla.imageFileName;
      case StageObjType.rabbit:
        return Rabbit.imageFileName;
      case StageObjType.kangaroo:
        return Kangaroo.imageFileName;
      case StageObjType.turtle:
        return Turtle.imageFileName;
      case StageObjType.girl:
        return Girl.imageFileName;
      case StageObjType.shop:
        return Shop.imageFileName;
      case StageObjType.canon:
        return Canon.imageFileName;
      case StageObjType.spawner:
        return Spawner.imageFileName;
      case StageObjType.boneman:
        return Boneman.imageFileName;
      case StageObjType.barrierman:
        return Barrierman.imageFileName;
      case StageObjType.weight:
        return Weight.imageFileName;
    }
  }

  static StageObjType fromStr(String str) {
    for (final entry in strMap.entries) {
      if (entry.value == str) {
        return entry.key;
      }
    }
    throw ('[StageObjType]オブジェクトタイプとして無効な文字列が入力された');
  }
}

class StageObjTypeLevel {
  StageObjType type;
  int level;

  StageObjTypeLevel({required this.type, this.level = 1}) {
    assert(level >= 0);
  }

  Map<String, dynamic> encode() {
    return {'type': type.str, 'level': level};
  }

  static StageObjTypeLevel decode(Map<String, dynamic> src) {
    return StageObjTypeLevel(
      type: StageObjTypeExtent.fromStr(src['type']),
      level: src['level'],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StageObjTypeLevel &&
            runtimeType == other.runtimeType &&
            type == other.type &&
            level == other.level);
  }

  @override
  int get hashCode => type.hashCode ^ level.hashCode;

  static Map<String, dynamic> staticEncode(StageObjTypeLevel tl) {
    return {'type': tl.type.str, 'level': tl.level};
  }

  @override
  String toString() {
    return '${type.str},$level';
  }

  StageObjTypeLevel.fromStr(String str)
      : type = StageObjTypeExtent.fromStr(str.split(',')[0]),
        level = int.parse(str.split(',')[1]);

  StageObjTypeLevel copy() => StageObjTypeLevel(type: type, level: level);
}

/// ステージ上オブジェクト
abstract class StageObj {
  final StageObjTypeLevel _typeLevel;

  /// 現在位置
  Point pos;

  /// 有効/無効
  /// 無効なオブジェクトはStage.update()の最後にまとめて削除すること
  bool valid;

  /// このフレーム終了後の有効/無効
  /// falseの場合、このフレーム内処理終了までは有効。
  /// Stage.update()の最後にまとめて削除すること
  bool validAfterFrame;
  SpriteAnimationComponent animationComponent;

  /// オブジェクトのレベル->向き->アニメーションのマップ
  Map<int, Map<Move, SpriteAnimation>> levelToAnimations;

  /// チャンネル->オブジェクトのレベル->向き->攻撃時アニメーションのマップ
  Map<int, Map<int, Map<Move, SpriteAnimation>>> levelToAttackAnimations;

  /// 移動中の向き
  Move moving = Move.none;

  /// 向いている方向
  Move _vector = Move.down;

  /// 移動量
  double movingAmount = 0;

  /// 向いている方向による、animationComponentの回転
  Map<Move, double> vectorToAnimationAngles = {};

  /// 押しているオブジェクト
  final List<StageObj> pushings = [];

  /// 押している各オブジェクトを「行使」しているかどうか
  /// ex.) ドリルによるブロックの破壊
  List<bool> executings = [];

  /// 攻撃中か
  bool attacking = false;

  /// 攻撃のチャンネル
  int attackCh = 1;

  /// 氷により、強制的に移動させられる方向
  Move forceMoving = Move.none;

  /// バリア範囲内にいることでカットするダメージ（敵用、Stage.update()で毎回0にリセットされる）
  int cutDamage = 0;

  /// 誰かに押されているか(trueの場合は他の人は押せない)
  bool isPushed = false;

  /// その他保存しておきたいint値(攻撃後ターン数等)
  /// 使用したい場合はoverrideすること
  int get arg => 0;

  /// その他保存しておきたいint値を取得
  /// コンストラクタで呼び出す
  void loadArg(int val) {}

  StageObj({
    required typeLevel,
    required this.animationComponent,
    required this.levelToAnimations,
    this.levelToAttackAnimations = const {},
    this.valid = true,
    this.validAfterFrame = true,
    required this.pos,
    required int savedArg,
    Move vector = Move.down,
  }) : _typeLevel = typeLevel {
    level = typeLevel.level;
    this.vector = vector;
    loadArg(savedArg);
  }

  /// タイプ
  StageObjType get type => _typeLevel.type;
  set type(StageObjType t) => _typeLevel.type = type;

  /// レベル
  int get level => _typeLevel.level;
  set level(int l) {
    if (kDebugMode) {
      assert(l >= 0);
    }
    if (level < 0) {
      // 例外起こして止まるのを避けてる
      remove();
    }
    // 攻撃中かどうか、レベル、向きでアニメーションを変更する
    if (attacking) {
      if (!levelToAttackAnimations[attackCh]!.containsKey(l)) {
        log('no attacking animation for level $l in ${_typeLevel.type}');
        // 通常時でのエラー画像を使う
        animationComponent.animation = levelToAnimations[0]![vector];
      } else {
        animationComponent.animation =
            levelToAttackAnimations[attackCh]![l]![vector];
      }
    } else {
      if (!levelToAnimations.containsKey(l)) {
        log('no animation for level $l in ${_typeLevel.type}');
        animationComponent.animation = levelToAnimations[0]![vector];
      } else {
        animationComponent.animation = levelToAnimations[l]![vector];
      }
    }
    animationComponent.angle = vectorToAnimationAngles[vector] ?? 0;
    _typeLevel.level = l;
  }

  /// 向いている方向
  Move get vector => _vector;
  set vector(Move v) {
    if (hasVector) {
      if (!v.isStraight) {
        return;
      }
      _vector = v;
    } else {
      _vector = Move.none;
    }
    if (attacking) {
      final animation = levelToAttackAnimations[attackCh]!.containsKey(level)
          ? levelToAttackAnimations[attackCh]![level]![vector]
          : levelToAnimations[0]![vector]; // 通常時でのエラー画像を使う
      animationComponent.animation = animation;
    } else {
      int key = levelToAnimations.containsKey(level) ? level : 0;
      animationComponent.animation = levelToAnimations[key]![vector];
    }
    animationComponent.angle = vectorToAnimationAngles[vector] ?? 0;
  }

  /// 対象とタイプ・レベルが一致しているかどうか
  bool isSameTypeLevel(StageObj o) {
    return o._typeLevel == _typeLevel;
  }

  /// animationComponentがgameWorldに追加されているかどうか
  /// (この判定をせずにremoveすると例外起きるし、毎回World.contain()すると遅くなるのでメンバとして持つ)
  bool isAddedToGameWorld = false;

  /// animationComponentをgameWorldに追加(既に追加されていれば何もしない)
  void addToGameWorld(World gameWorld) {
    if (!isAddedToGameWorld) {
      gameWorld.add(animationComponent);
      isAddedToGameWorld = true;
    }
  }

  /// animationComponentをgameWorldから削除(既に削除されていれば何もしない)
  void removeFromGameWorld(World gameWorld) {
    if (isAddedToGameWorld) {
      gameWorld.remove(animationComponent);
      isAddedToGameWorld = false;
    }
  }

  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    bool playerEndMoving,
    Map<Point, Move>
        prohibitedPoints, // 今は移動可能だが、他のオブジェクトが同時期に移動してくるため移動不可な座標と向きのMap（例えば、移動しているオブジェクトに対してその交差するように移動できないようにするためのMap）
  );

  @mustCallSuper
  void onRemove(World gameWorld) {
    removeFromGameWorld(gameWorld);
  }

  /// このオブジェクトは押せるか
  bool get pushable;

  /// このオブジェクトは押す対象にならず、移動もできないか
  bool get stopping;

  /// このオブジェクトは押したオブジェクトの移動先になり得るか
  bool get puttable;

  /// このオブジェクトはプレイヤーの移動先になり得るか
  bool get playerMovable;

  /// このオブジェクトは敵の移動先になり得るか
  bool get enemyMovable;

  /// このオブジェクトは同じレベルの同じオブジェクトとマージできるか
  bool get mergable;

  /// 最大レベル
  int get maxLevel;

  /// 敵かどうか
  bool get isEnemy;

  /// 倒せるかどうか
  bool get killable;

  /// コンベアで動くかどうか
  bool get beltMove;

  /// 向きがあるかどうか
  bool get hasVector;

  /// 持っているコイン
  int get coins => 0;

  /// 獲得スコア(現状宝箱専用)
  int get score => 0;

  /// ポケットに入れていてもupdate()するかどうか
  bool get updateInPocket => false;

  /// トラップでやられる敵かどうか
  bool get isTrapKillable => isEnemy && killable;

  /// プレイヤーの味方か（敵の攻撃を受けるか）
  bool get isAlly => false;

  /// 動物か
  bool get isAnimals => false;

  /// 他オブジェクトに重ねているか（trueの場合、Stage.get()で取得する対象にならない）
  bool get isOverlay => false;

  /// 重さ(押すにはその分のアイテム個数＋重りを連ねて押さないといけない)
  int get weight => 0;

  /// 攻撃を受ける
  /// やられたかどうかを返す
  bool hit(int damageLevel, Stage stage) {
    if (!killable) return false;
    int damageAfterCut = damageLevel - cutDamage;
    if (damageAfterCut < 0) damageAfterCut = 0;
    level = (level - damageAfterCut).clamp(0, maxLevel);
    return level <= 0;
  }

  /// このオブジェクトを削除
  void remove() => valid = false;

  /// 今フレームの終わりにこのオブジェクトを削除
  void removeAfterFrame() => validAfterFrame = false;

  /// 敵の対象の移動が、移動してよいかどうかを返す
  bool _isEnemyMoveAllowed(
    Point point,
    Move move,
    Player player,
    Map<Point, Move> prohibitedPoints,
  ) {
    return (Config().debugEnemyCanCollidePlayer &&
            point == player.pos + player.moving.point) || // プレイヤーの移動先なら移動しても良い
        !prohibitedPoints.containsKey(point) ||
        (prohibitedPoints[point] != Move.none &&
            prohibitedPoints[point] != move);
  }

  void _enemyMoveRondom(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
    bool containStop,
  ) {
    final List<Move> cand = [];
    // 氷で滑っておらず、
    // 今プレイヤーの移動先にいるなら移動しない
    if (forceMoving == Move.none && pos == player.pos + player.moving.point) {
      cand.add(Move.none);
    } else {
      if (containStop) {
        cand.add(Move.none);
      }
      for (final move in MoveExtent.straights) {
        Point eTo = pos + move.point;
        // ステージ範囲外に出る場合は候補に入れない
        if (!stage.contains(eTo)) continue;
        final eToObj = stage.get(eTo);
        if (Config().allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.enemyMovable &&
            !(mergable && isSameTypeLevel(eToObj))) {
          // 敵が移動可能でない、かつマージできない
          continue;
        }
        if (!_isEnemyMoveAllowed(eTo, move, player, prohibitedPoints)) {
          continue;
        }
        // 氷で滑る先に移動可能ならその方向に動くこと確定
        if (move == forceMoving) {
          cand.clear();
          cand.add(move);
          break;
        }
        cand.add(move);
      }
    }
    if (cand.isNotEmpty) {
      final move = cand.sample(1).first;
      ret['move'] = move;
      // 向きも変更
      ret['vector'] = move;
      // 自身の移動先は、他のオブジェクトの移動先にならないようにする
      prohibitedPoints[pos + move.point] = Move.none;
      // 他オブジェクトとすれ違えないようにする
      if (!prohibitedPoints.containsKey(pos)) {
        prohibitedPoints[pos] = move.oppsite;
      }
    }
  }

  void _enemyMoveAndPushRondom(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
    bool containStop,
    World gameWorld,
    int pushableNum,
  ) {
    final Map<Move, Map<String, dynamic>> cand = {};
    // 氷で滑っておらず、
    // 今プレイヤーの移動先にいるなら移動しない
    if (forceMoving == Move.none && pos == player.pos + player.moving.point) {
      cand[Move.none] = {
        "prohibitedPoints": prohibitedPoints,
        "pushings": <StageObj>[],
        "executings": <bool>[]
      };
    } else {
      if (containStop) {
        cand[Move.none] = {
          "prohibitedPoints": prohibitedPoints,
          "pushings": <StageObj>[],
          "executings": <bool>[]
        };
      }
      for (final move in MoveExtent.straights) {
        Point eTo = pos + move.point;
        // ステージ範囲外に出る場合は候補に入れない
        if (!stage.contains(eTo)) continue;
        final eToObj = stage.get(eTo);
        if (Config().allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.enemyMovable &&
            !eToObj.pushable &&
            !(mergable && isSameTypeLevel(eToObj))) {
          // 敵が移動可能でない、押すこともできない、かつマージできない
          continue;
        }
        if (!_isEnemyMoveAllowed(eTo, move, player, prohibitedPoints)) {
          continue;
        }
        // 実際に押せるか
        // TODO:できればコピーしたくない
        Map<Point, Move> copied = {};
        List<StageObj> pushingsList = [];
        List<bool> executingsList = [];
        copied.addAll(prohibitedPoints);
        if (startPushing(move, pushableNum, stage, gameWorld, copied,
            pushingsList, executingsList)) {
          cand[move] = {
            "prohibitedPoints": copied,
            "pushings": pushingsList,
            "executings": executingsList,
          };
        }
        // 氷で滑る先に移動可能ならその方向に動くこと確定
        if (move == forceMoving) {
          cand.removeWhere((key, value) => key != move);
          break;
        }
      }
    }
    if (cand.isNotEmpty) {
      final move = cand.keys.sample(1).first;
      ret['move'] = move;
      // 向きも変更
      ret['vector'] = move;
      // 自身の移動先は、他のオブジェクトの移動先にならないようにする
      prohibitedPoints[pos + move.point] = Move.none;
      // 他オブジェクトとすれ違えないようにする
      if (!prohibitedPoints.containsKey(pos)) {
        prohibitedPoints[pos] = move.oppsite;
      }
      // startPushing()の結果を反映する
      prohibitedPoints.addAll(cand[move]!["prohibitedPoints"]!);
      pushings.clear();
      pushings.addAll(cand[move]!["pushings"]!);
      for (final e in cand[move]!["pushings"]!) {
        (e as StageObj).isPushed = true;
      }
      executings.clear();
      executings.addAll(cand[move]!["executings"]!);
    }
  }

  void _enemyMoveFollow(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    StageObj target,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
  ) {
    // 滑っておらず、
    // 今ターゲットの移動先にいるなら移動しない
    if (forceMoving == Move.none && pos == target.pos + target.moving.point) {
      ret['move'] = Move.none;
    } else if (forceMoving == Move.none && Config().random.nextInt(6) == 0) {
      ret['move'] = Move.none;
    } else {
      // ターゲットの方へ移動する/向きを変える
      final delta = target.pos - pos;
      final Set<Move> tmpCand = {};
      if (delta.x > 0) {
        tmpCand.add(Move.right);
      } else if (delta.x < 0) {
        tmpCand.add(Move.left);
      }
      if (delta.y > 0) {
        tmpCand.add(Move.down);
      } else if (delta.y < 0) {
        tmpCand.add(Move.up);
      }
      // 滑っている場合は、プレイヤーの方じゃなくても候補に入れる
      if (forceMoving != Move.none) {
        tmpCand.add(forceMoving);
      }
      final List<Move> cand = [];
      for (final move in tmpCand) {
        Point eTo = pos + move.point;
        // ステージ範囲外に出る場合は候補に入れない
        if (!stage.contains(eTo)) continue;
        final eToObj = stage.get(eTo);
        if (Config().allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.enemyMovable &&
            !(mergable && isSameTypeLevel(eToObj))) {
          // 敵が移動可能でない、かつマージできない
          continue;
        }
        if (!_isEnemyMoveAllowed(eTo, move, player, prohibitedPoints)) {
          continue;
        }
        // 氷で滑る先に移動可能ならその方向に動くこと確定
        if (move == forceMoving) {
          cand.clear();
          cand.add(move);
          break;
        }
        cand.add(move);
      }
      if (cand.isNotEmpty) {
        final move = cand.sample(1).first;
        ret['move'] = move;
        // 向きも変更
        ret['vector'] = move;
        // 自身の移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints[pos + move.point] = Move.none;
        // 他オブジェクトとすれ違えないようにする
        if (!prohibitedPoints.containsKey(pos)) {
          prohibitedPoints[pos] = move.oppsite;
        }
      } else {
        // ランダムに移動を試みる
        _enemyMoveRondom(
            ret, pattern, vector, player, stage, prohibitedPoints, true);
        if ((!ret.containsKey('move') || ret['move'] == Move.none) &&
            tmpCand.isNotEmpty) {
          // 向きだけ変更
          ret['vector'] = tmpCand.sample(1).first;
        }
      }
    }
  }

  void _enemyMoveFollowWithWarp(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    StageObj target,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
    int distanceFromTarget, // ターゲットからどれだけ離れていたらワープするか
  ) {
    final nearTargetRange = PointDistanceRange(target.pos, distanceFromTarget);
    if (!nearTargetRange.contains(pos)) {
      Point warpPoint = pos;
      // ターゲットの付近の座標から、移動可能な候補を選ぶ
      List<Point> cand = [];
      for (final p in nearTargetRange.set) {
        // そもそもステージ範囲外なら除外する
        if (!stage.contains(p)) continue;
        final obj = stage.get(p, detectPlayer: true);
        // ワープでいきなりプレイヤーと重ならないようにする
        if (obj.type == StageObjType.player ||
            obj.type == StageObjType.warp ||
            p == (player.pos + player.moving.point)) {
          continue;
        }
        if (Config().allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == p) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!obj.enemyMovable && !(mergable && isSameTypeLevel(obj))) {
          // 敵が移動可能でない、かつマージできない
          continue;
        }
        if (!_isEnemyMoveAllowed(p, Move.none, player, prohibitedPoints)) {
          continue;
        }
        cand.add(p);
      }
      if (cand.isNotEmpty) {
        // ワープ位置候補の中からランダムに1つ選ぶ
        warpPoint = cand.sample(1).first;
        // ターゲットの近くにワープする
        ret['warp'] = warpPoint;
        // 自身の移動先は、他のオブジェクトの移動先にならないようにする
        prohibitedPoints[warpPoint] = Move.none;
      }
    } else {
      _enemyMoveFollow(
          ret, pattern, vector, target, player, stage, prohibitedPoints);
    }
  }

  void _enemyMoveFollowWithGhosting(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    StageObj target,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
    bool isGhost,
  ) {
    // ゴースト解除できるかどうかの判定関数
    bool canUnGhost(Point p, Move move) {
      final obj = stage.get(p);
      if (Config().allowEnemyMoveToPushingObjectPoint &&
          player.pushings.isNotEmpty &&
          player.pushings.first.pos == p) {
        // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        return true;
      } else if (!obj.enemyMovable && !(mergable && isSameTypeLevel(obj))) {
        // 敵が移動可能でない、かつマージできない
        return false;
      }
      if (!_isEnemyMoveAllowed(p, move, player, prohibitedPoints)) {
        return false;
      }
      return true;
    }

    // 今ターゲットの移動先にいるなら移動しない、ゴーストなら解除する
    if (pos == target.pos + target.moving.point &&
        (!isGhost || canUnGhost(pos, Move.none))) {
      ret['move'] = Move.none;
      ret['ghost'] = false;
    } else if (Config().random.nextInt(6) == 0) {
      ret['move'] = Move.none;
      ret['ghost'] = isGhost;
    } else {
      // 今いる位置でゴースト解除できるか
      bool canUnGhostNow = canUnGhost(pos, Move.none);
      // ターゲットの方へ移動する/向きを変える
      final delta = target.pos - pos;

      /// 動く向きの候補->ゴースト化が必要かどうかのマップ
      final Map<Move, bool> candWithGhosting = {};
      if (delta.x > 0) {
        candWithGhosting[Move.right] = true;
      } else if (delta.x < 0) {
        candWithGhosting[Move.left] = true;
      }
      if (delta.y > 0) {
        candWithGhosting[Move.down] = true;
      } else if (delta.y < 0) {
        candWithGhosting[Move.up] = true;
      }
      for (final entry in candWithGhosting.entries) {
        final move = entry.key;
        Point eTo = pos + move.point;
        // ステージ範囲外に出る場合は候補に入れない
        if (!stage.contains(eTo)) continue;

        if (canUnGhost(eTo, move)) {
          candWithGhosting[move] = false;
        }
        /*final eToObj = stage.get(eTo);
        if (Config().allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.enemyMovable &&
            !(mergable && isSameTypeLevel(eToObj))) {
          // 敵が移動可能でない、かつマージできない
          continue;
        }
        if (prohibitedPoints.containsKey(eTo) &&
            (prohibitedPoints[eTo] == Move.none ||
                prohibitedPoints[eTo] == move)) {
          continue;
        }
        candWithGhosting[move] = false;*/
      }
      if (candWithGhosting.isNotEmpty) {
        final move = candWithGhosting.keys.sample(1).first;
        ret['move'] = move;
        // 向きも変更
        ret['vector'] = move;
        // ゴースト化が必要かどうか
        ret['ghost'] = candWithGhosting[move]!;
        // ゴースト解除ができないなら
        if (isGhost && !canUnGhostNow) {
          ret['ghost'] = true;
        }
        if (!ret['ghost']!) {
          // 自身の移動先は、他のオブジェクトの移動先にならないようにする
          prohibitedPoints[pos + move.point] = Move.none;
          // 他オブジェクトとすれ違えないようにする
          if (!prohibitedPoints.containsKey(pos)) {
            prohibitedPoints[pos] = move.oppsite;
          }
        }
      }
    }
  }

  bool _enemyAttackIfPlayersExist(
    Map<String, dynamic> ret,
    Stage stage,
    Iterable<Point> attackables,
  ) {
    bool find = false;
    for (final point in attackables) {
      // ステージ範囲外は除外
      if (!stage.contains(point)) continue;
      final target = stage.get(point, detectPlayer: true);
      if (target.type == StageObjType.player) {
        // プレイヤーがいれば攻撃
        ret['attack'] = true;
        find = true;
        break;
      } else if (target.isAlly) {
        // プレイヤーの味方の場合、レベルに応じた確率で攻撃
        int t = level < 2
            ? 10
            : level < 3
                ? 40
                : 70;
        if (Config().random.nextInt(100) < t) {
          ret['attack'] = true;
          find = true;
          break;
        }
      }
    }
    return find;
  }

  /// 敵の動きを決定する
  Map<String, dynamic> enemyMove(
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints, {
    bool isGhost = false,
    World? gameWorld,
    int? pushableNum,
  }) {
    Map<String, dynamic> ret = {};

    switch (pattern) {
      case EnemyMovePattern.walkRandom:
        _enemyMoveRondom(
            ret, pattern, vector, player, stage, prohibitedPoints, false);
        break;
      case EnemyMovePattern.walkRandomOrStop:
        _enemyMoveRondom(
            ret, pattern, vector, player, stage, prohibitedPoints, true);
        break;
      case EnemyMovePattern.mergeWalkRandomOrStop:
        // マージできる、同じタイプ・レベルの敵を探す
        final sameEnemies = stage.enemies
            .where((e) => e != this && e.isSameTypeLevel(this) && e.mergable);
        if (sameEnemies.isEmpty) {
          _enemyMoveRondom(
              ret, pattern, vector, player, stage, prohibitedPoints, true);
        } else {
          // 対象の動いている向きも加味して最も近い敵を探す
          final closests = pos.closests([
            for (final enemy in sameEnemies) enemy.pos + enemy.moving.point
          ]);
          Point closest = closests.sample(1).first;
          StageObj closestEnemy =
              sameEnemies.where((e) => e.pos + e.moving.point == closest).first;
          _enemyMoveFollow(ret, pattern, vector, closestEnemy, player, stage,
              prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayer:
        _enemyMoveFollow(
            ret, pattern, vector, player, player, stage, prohibitedPoints);
        break;
      case EnemyMovePattern.followPlayerAttackForward3:
        // 向いている方向の3マスにプレイヤー(/の味方)がいるなら攻撃
        final tmp = MoveExtent.straights;
        tmp.remove(vector);
        tmp.remove(vector.oppsite);
        final attackable = pos + vector.point;
        final attackables = [attackable];
        for (final v in tmp) {
          attackables.add(attackable + v.point);
        }
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackRound8:
        // 周囲8マスにプレイヤー/味方がいるなら攻撃
        final attackables = PointRectRange(
                Point(pos.x - 1, pos.y - 1), Point(pos.x + 1, pos.y + 1))
            .set;
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackStraight3:
        // 前方直線状3マスにプレイヤー/味方がいるなら攻撃
        final attackables = PointRectRange(pos, pos + vector.point * 3).set;
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackStraight5:
        // 前方直線状5マスにプレイヤー/味方がいるなら攻撃
        final attackables = PointRectRange(pos, pos + vector.point * 5).set;
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttack3Straight5:
        // 前方3方向の直線5マスにプレイヤー/味方がいるなら攻撃
        final vec1 = vector.neighbors[0];
        final vec2 = vector.neighbors[1];
        final attackables = {
          ...PointLineRange(pos + vector.point, vector, 5).set,
          ...PointLineRange(pos + vec1.point, vec1, 5).set,
          ...PointLineRange(pos + vec2.point, vec2, 5).set,
        };
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followWarpPlayerAttackStraight5:
        // 前方直線状5マスにプレイヤー/味方がいるなら攻撃
        final attackables = PointRectRange(pos, pos + vector.point * 5).set;
        // プレイヤー/味方がいるなら攻撃、いないなら動く
        if (!_enemyAttackIfPlayersExist(ret, stage, attackables)) {
          _enemyMoveFollowWithWarp(
              ret, pattern, vector, player, player, stage, prohibitedPoints, 5);
        }
        break;
      case EnemyMovePattern.followPlayerWithGhosting:
        // プレイヤーの方へ動くor向く、通れない場合はゴースト化する/通れるならゴースト解除する
        _enemyMoveFollowWithGhosting(ret, pattern, vector, player, player,
            stage, prohibitedPoints, isGhost);
        break;
      case EnemyMovePattern.walkAndPushRandomOrStop:
        _enemyMoveAndPushRondom(ret, pattern, vector, player, stage,
            prohibitedPoints, true, gameWorld!, pushableNum!);
        break;
    }

    // 氷で滑っている場合は解除する
    forceMoving = Move.none;
    return ret;
  }

  /// 移動方向を元に、押し始める・押すオブジェクトを決定する
  /// 移動自体ができない場合はfalseを返す
  bool startPushing(
    Move moveInput,
    int pushableNum,
    Stage stage,
    World gameWorld,
    Map<Point, Move> prohibitedPoints,
    List<StageObj> pushingsList,
    List<bool> executingsList,
  ) {
    pushingsList.clear();
    executingsList.clear();
    // 移動先の座標、オブジェクト
    Point to = pos + moveInput.point;
    // 範囲外に出る場合は、移動できないとする
    if (!stage.contains(to)) {
      return false;
    }
    // 移動先がワープなら（ただし、その上にオブジェクトがあれば気にしない）
    if (stage.get(to).type == StageObjType.warp) {
      to = stage.getWarpedPoint(to);
    }
    StageObj toObj = stage.get(to);
    StageObj toBox = stage.get(to, priorBox: true);
    // 押すオブジェクトの移動先の座標、オブジェクト
    Point toTo = to + moveInput.point;
    // 押す先が範囲外に出る場合は、プレイヤーが移動できるかどうかを返すのみ
    if (!stage.contains(toTo)) {
      return toObj.playerMovable && !toObj.pushable;
    }
    // 押すオブジェクトの移動先がワープなら（ただし、その上にオブジェクトがあれば気にしない）
    if (stage.get(toTo).type == StageObjType.warp) {
      toTo = stage.getWarpedPoint(toTo);
    }
    StageObj toToObj = stage.get(toTo);
    StageObj toToBox = stage.get(toTo, priorBox: true);
    // 動かないならreturn
    if (moveInput == Move.none) {
      return false;
    }
    // マージするからここまでは押せるよ、なpushingsのリスト
    List<StageObj> pushingsSave = [];
    List<bool> executingsSave = [];

    /// 同時に押しているアイテムの個数＋重り分の重さ
    int pushingWeight = 0;
    int end = pushableNum;
    if (end < 0) {
      final range = stage.stageRB - stage.stageLT;
      end = max(range.x, range.y);
    }
    for (int i = 0; i < end; i++) {
      bool stopBecauseDrill = false; // ドリルでブロックを壊すため、以降の判定をしなくて良いことを示すフラグ
      bool needSave = false;
      bool executing = false;
      // オブジェクトが押せるか
      if (toObj.pushable) {
        bool breakPushing = false;
        // ドリルの場合は少し違う処理
        if (toObj.type == StageObjType.drill &&
            toToObj.type == StageObjType.block) {
          // 画面外にドリルを押す行為
          if (toToObj == stage.mienaikabe) {
            // これまでにpushingsに追加したものも含めて一切押せない
            // ただし、途中でマージできるものがあるならそこまでは押せる
            pushingsList.clear();
            executingsList.clear();
            if (pushingsSave.isNotEmpty) {
              pushingsList.addAll(pushingsSave);
              executingsList.addAll(executingsSave);
              break;
            }
            return false;
          }
          if (pushingsSave.isEmpty) {
            // ここまでpushingsに加えた中でマージしていないのであれば、
            // 押した先がブロックなら即座に破壊、かつマージと同様、一気に押せるオブジェクト（pushings）はここまで
            // 破壊するブロックのアニメーションを描画
            gameWorld.add((toToObj as Block).createBreakingBlock());
            stage.setStaticType(toTo, StageObjType.none);
            executing = true;
          }
          stopBecauseDrill = true;
        } else {
          if (toObj.weight > pushingWeight) {
            // 押すための重さが足りない
            breakPushing = true;
          } else if (toToObj.stopping) {
            // 押した先が停止物
            breakPushing = true;
          } else if (prohibitedPoints.containsKey(toTo) &&
              (prohibitedPoints[toTo]! == Move.none ||
                  prohibitedPoints[toTo]! == moveInput)) {
            // 押した先には移動不可
            breakPushing = true;
          } else if (toObj.isPushed) {
            // すでに押されている
            breakPushing = true;
          } else if (toToObj.isEnemy && toObj.enemyMovable) {
            // 押した先が敵かつ押すオブジェクトに敵が移動可能(->敵にオブジェクトを重ねる（トラップ等）)
          } else if (toToObj.puttable) {
            // 押した先が、何かを置けるオブジェクト
          } else if (toBox.isSameTypeLevel(toToBox) && toBox.mergable) {
            // 押した先とマージできる
          } else if (i < end - 1 && toToObj.pushable) {
            // 押した先も押せる
          } else {
            breakPushing = true;
          }
          if (breakPushing) {
            // これまでにpushingsに追加したものも含めて一切押せない
            // ただし、途中でマージできるものがあるならそこまでは押せる
            pushingsList.clear();
            executingsList.clear();
            if (pushingsSave.isNotEmpty) {
              pushingsList.addAll(pushingsSave);
              executingsList.addAll(executingsSave);
              break;
            }
            return false;
          }
        }
        // マージできる場合は、pushingsをセーブする
        if (toToBox.isSameTypeLevel(toBox) && toBox.mergable) {
          needSave = true;
        }
      } else {
        // 押せない場合
        break;
      }
      // 押すオブジェクトリストに追加
      pushingsList.add(stage.boxes.firstWhere((element) => element.pos == to));
      executingsList.add(executing);
      // 同時に押しているアイテムの重さ加算
      if (pushingsList.last.type == StageObjType.weight) {
        pushingWeight += (pushingsList.last as Weight).getWeight();
      } else {
        ++pushingWeight;
      }
      // オブジェクトの移動先は、他のオブジェクトの移動先にならないようにする
      prohibitedPoints[toTo] = Move.none;
      if (stopBecauseDrill) {
        // ドリルでブロックを壊す場合
        break;
      }
      if (needSave) {
        // マージできる場合は、pushingsをセーブする
        pushingsSave = [...pushingsList];
        executingsSave = [...executingsList];
      }
      // 1つ先へ
      to = toTo.copy();
      toTo = to + moveInput.point;
      // 範囲外に出る場合は、そこに破壊不能なブロックがあるとする
      if (!stage.contains(toTo)) {
        toObj = stage.get(to);
        toBox = stage.get(to, priorBox: true);
        toToObj = stage.mienaikabe!;
        toToBox = stage.mienaikabe!;
      } else {
        // 押すオブジェクトの移動先がワープなら（ただし、その上にオブジェクトがあれば気にしない）
        if (stage.get(toTo).type == StageObjType.warp) {
          toTo = stage.getWarpedPoint(toTo);
        }
        toObj = stage.get(to);
        toBox = stage.get(to, priorBox: true);
        toToObj = stage.get(toTo);
        toToBox = stage.get(toTo, priorBox: true);
      }
    }
    // 押せる可能範囲全て押せるとしても、途中でマージするならそこまでしか押せない
    if (pushingsSave.isNotEmpty) {
      pushingsList.clear();
      executingsList.clear();
      pushingsList.addAll(pushingsSave);
      executingsList.addAll(executingsSave);
    }

    // オブジェクトを押した場合、そのオブジェクトをすり抜けて押した者の移動先には移動できないようにする
    if (pushingsList.isNotEmpty) {
      if (!prohibitedPoints.containsKey(pos + moveInput.point)) {
        prohibitedPoints[pos + moveInput.point] = moveInput.oppsite;
      }
    }
    // 押した者とはすれ違えないようにする
    if (!prohibitedPoints.containsKey(pos)) {
      prohibitedPoints[pos] = moveInput.oppsite;
    }
    return true;
  }

  /// 押し終わったときの処理
  /// ※押した者の位置(pos)は移動済みの座標にしてから呼ぶこと
  /// * mergeDamageBasedMergePower = trueならば、ブロック破壊レベルと同じ値だけ敵にダメージを与えられる
  void endPushing(
    Stage stage,
    World gameWorld, {
    PointRange Function(Point)? mergeRangeFunc,
    int mergeDamageBase = 0,
    int mergePowerBase = 0,
    bool mergeDamageBasedMergePower = false,
  }) {
    // 押したオブジェクトの中でマージするインデックスを探す
    int mergeIndex = -1; // -1はマージなし
    Point toTo = pos;
    for (int i = 0; i < pushings.length; i++) {
      toTo += moving.point;
      // 範囲外に出る場合はbreak
      if (!stage.contains(toTo)) break;
      if (stage.get(toTo).type == StageObjType.warp) {
        toTo = stage.getWarpedPoint(toTo);
      }
    }
    // 押すオブジェクトのうち、なるべく遠くのオブジェクトをマージするために逆順でforループ
    for (int i = pushings.length - 1; i >= 0; i--) {
      final pushing = pushings[i];
      final toToObj = stage.get(toTo, priorBox: true);
      // 押した先のオブジェクトを調べる
      if (pushing.mergable && pushing.isSameTypeLevel(toToObj)) {
        // マージするインデックスを保存
        mergeIndex = i;
        break; // 1回だけマージ
      }
      if (toToObj.type == StageObjType.warp) {
        toTo = stage.getWarpedPoint(toTo, reverse: true);
      }
      toTo -= moving.point;
    }
    // マージしたのなら、一旦氷による滑りは無くす
    if (mergeIndex != -1) {
      forceMoving = Move.none;
    }

    // 押したオブジェクト位置更新
    toTo = pos + moving.point;
    if (!stage.contains(toTo)) {
      // この時点でステージ範囲外ということは、押すものは無いはず
      assert(pushings.isEmpty);
      return;
    }
    if (stage.get(toTo).type == StageObjType.warp) {
      toTo = stage.getWarpedPoint(toTo);
      // ワープするオブジェクトに登録
      if (pushings.isNotEmpty) {
        stage.warpingObjs.add(pushings[0]);
      }
    }
    for (int i = 0; i < pushings.length; i++) {
      final pushing = pushings[i];
      // 上で探したインデックスと一致するならマージ
      if (i == mergeIndex) {
        // マージ
        int mergePow = Config.getMergePower(0, pushing) + mergePowerBase;
        PointRange mergeRange =
            PointRectRange(toTo + Point(-1, -1), toTo + Point(1, 1));
        if (mergeRangeFunc != null) {
          mergeRange = mergeRangeFunc(toTo);
        }
        final affect = MergeAffect(
          basePoint: toTo,
          range: mergeRange,
          canBreakBlockFunc: (block) => Config.canBreakBlock(block, mergePow),
          enemyDamage: mergeDamageBasedMergePower
              ? Config.getMergePower(0, pushing)
              : mergeDamageBase + Config().debugEnemyDamageInMerge,
        );
        stage.merge(
          toTo,
          pushing,
          gameWorld,
          affect,
        );
      }
      // 押したものの位置を設定
      pushing.pos = toTo;
      stage.setObjectPosition(pushing);
      // 押した先がマグマならオブジェクト蒸発
      if (stage.safeGetStaticObj(toTo).type == StageObjType.magma) {
        // コイン獲得
        stage.coins.actual += pushing.coins;
        stage.showGotCoinEffect(pushing.coins, toTo);
        pushing.remove();
        // 効果音を鳴らす
        Audio().playSound(Sound.magmaEvaporate);
      } else if (stage.safeGetStaticObj(toTo).type == StageObjType.water &&
          i != mergeIndex) {
        // 押した先が氷なら滑るように設定
        // ただし、マージしたなら滑らない
        stage.safeGetStaticObj(toTo).moving = moving;
      } else if (pushing.type == StageObjType.drill && executings[i]) {
        // ドリル使用時
        // ドリルのオブジェクトレベルダウン、0になったら消す
        pushing.level--;
        if (pushing.level <= 0) {
          pushing.remove();
        }
      }
      toTo += moving.point;
      // 範囲外に出る場合はループ終了
      if (!stage.contains(toTo)) {
        break;
      }
      if (stage.get(toTo).type == StageObjType.warp) {
        toTo = stage.getWarpedPoint(toTo);
        // ワープするオブジェクトに登録
        if (i < pushings.length - 1) {
          stage.warpingObjs.add(pushings[i + 1]);
        }
      }
    }
  }

  /// 移動し終わったときの処理
  /// ※移動した者の位置(pos)は移動済みの座標にしてから呼ぶこと
  void endMoving(
    Stage stage,
    World gameWorld,
  ) {
    // ゴースト状態なら何もしない
    if (type == StageObjType.ghost && (this as Ghost).ghosting) {
      return;
    }
    if (type == StageObjType.player) {
      // プレイヤー限定の処理
      final player = this as Player;
      // get()だと、アイテムを押してる場合はそのアイテムを取得してしまうので、staticObjをgetする
      final obj = stage.safeGetStaticObj(pos);
      if (obj.type == StageObjType.treasureBox) {
        // 移動先が宝箱だった場合
        // コイン獲得
        stage.coins.actual += obj.coins;
        stage.showGotCoinEffect(obj.coins, pos);
        // スコア獲得
        stage.score.actual += obj.score;
        // 宝箱消滅
        stage.setStaticType(pos, StageObjType.none);
        // 効果音を鳴らす
        Audio().playSound(Sound.getTreasure);
        // 【実績用】見つけた宝箱の数を加算
        stage.foundTreasureCount++;
        // 最後に宝箱を開けた状況として保存（スコアは0で保存される）
        stage.openTreasureBoxInUpdate = true;
        // 宝箱を開けた際のチュートリアル表示
        stage.tutorial.current = TutorialState.openTreasureBox;
        // 一手戻すのに必要なスコアを更新
        stage.updateRequiredScoreToUndo();
      } else if (obj.isAnimals && obj.type != StageObjType.shop) {
        // 移動先が動物だった場合
        switch (obj.type) {
          case StageObjType.gorilla:
            // 手の能力を習得
            player.isAbilityAquired[PlayerAbility.hand] = true;
            player.pushableNum = -1;
            // 手の能力のチュートリアル表示
            stage.tutorial.current = TutorialState.handAbility;
            break;
          case StageObjType.rabbit:
            // 足の能力を習得
            player.isAbilityAquired[PlayerAbility.leg] = true;
            // 足の能力のチュートリアル表示
            stage.tutorial.current = TutorialState.legAbility;
            break;
          case StageObjType.kangaroo:
            // ポケットの能力を習得
            player.isAbilityAquired[PlayerAbility.pocket] = true;
            // ポケットの能力のチュートリアル表示
            stage.tutorial.current = TutorialState.pocketAbility;
            break;
          case StageObjType.turtle:
            // アーマーの能力を習得
            player.isAbilityAquired[PlayerAbility.armer] = true;
            // アーマーの能力のチュートリアル表示
            stage.tutorial.current = TutorialState.armerAbility;
            break;
          case StageObjType.girl:
            // マージの能力を習得
            player.isAbilityAquired[PlayerAbility.merge] = true;
            // マージの能力のチュートリアル表示
            stage.tutorial.current = TutorialState.mergeAbility;
            break;
          default:
            break;
        }
        // 動物はいなくなる
        stage.setStaticType(pos, StageObjType.none);
        // 効果音を鳴らす
        Audio().playSound(Sound.getSkill);
        // 一手戻すのに必要なスコアを更新
        stage.updateRequiredScoreToUndo();
      }
    }
    // 敵がget()すると敵自身が返ってくるのでstaticObjsで取得している
    final staticObj = stage.safeGetStaticObj(pos);
    if (staticObj.type == StageObjType.warp) {
      // 移動先がワープだった場合
      Point orgPos = pos.copy();
      pos = stage.getWarpedPoint(pos);
      stage.setObjectPosition(this);
      // プレイヤーがワープしていたら
      if (type == StageObjType.player) {
        stage.isPlayerWarp = true;
      } else {
        // ワープするオブジェクトに登録
        stage.warpingObjs.add(this);
      }
      // 実際にワープしていたら効果音を鳴らす
      if (orgPos != pos) {
        Audio().playSound(Sound.warp);
      }
    } else if (staticObj.type == StageObjType.water) {
      // 氷の上に立ったとき
      forceMoving = moving;
    }
  }

  Map<String, dynamic> encode() {
    return {
      'typeLevel': _typeLevel.encode(),
      'pos': pos.encode(),
      'vector': vector.index,
      'arg': arg,
    };
  }
}
