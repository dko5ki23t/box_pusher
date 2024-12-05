import 'dart:developer';
import 'dart:math' hide log;

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
import 'package:box_pusher/game_core/stage_objs/builder.dart';
import 'package:box_pusher/game_core/stage_objs/drill.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/ghost.dart';
import 'package:box_pusher/game_core/stage_objs/gorilla.dart';
import 'package:box_pusher/game_core/stage_objs/guardian.dart';
import 'package:box_pusher/game_core/stage_objs/jewel.dart';
import 'package:box_pusher/game_core/stage_objs/kangaroo.dart';
import 'package:box_pusher/game_core/stage_objs/magma.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/rabbit.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/swordsman.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/treasure_box.dart';
import 'package:box_pusher/game_core/stage_objs/turtle.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:box_pusher/game_core/stage_objs/water.dart';
import 'package:box_pusher/game_core/stage_objs/wizard.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart' hide Block;

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
  ghost, // オブジェクトをすり抜けて移動できる敵
  builder, // 一定間隔でブロックを置く敵
  gorilla,
  rabbit,
  kangaroo,
  turtle,
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
    StageObjType.builder: 'builder',
    StageObjType.gorilla: 'gorilla',
    StageObjType.rabbit: 'rabbit',
    StageObjType.kangaroo: 'kangaroo',
    StageObjType.turtle: 'turtle',
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
      case StageObjType.builder:
        return Builder;
      case StageObjType.gorilla:
        return Gorilla;
      case StageObjType.rabbit:
        return Rabbit;
      case StageObjType.kangaroo:
        return Kangaroo;
      case StageObjType.turtle:
        return Turtle;
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
      case StageObjType.builder:
        return Builder.imageFileName;
      case StageObjType.gorilla:
        return Gorilla.imageFileName;
      case StageObjType.rabbit:
        return Rabbit.imageFileName;
      case StageObjType.kangaroo:
        return Kangaroo.imageFileName;
      case StageObjType.turtle:
        return Turtle.imageFileName;
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

  StageObjTypeLevel({required this.type, this.level = 1});

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

  /// 移動中の向き
  Move moving = Move.none;

  /// 向いている方向
  Move _vector = Move.down;
  double movingAmount = 0;

  /// 向いている方向による、animationComponentの回転
  Map<Move, double> vectorToAnimationAngles = {};

  /// 押しているオブジェクト
  final List<StageObj> pushings = [];

  StageObj({
    required typeLevel,
    required this.animationComponent,
    required this.levelToAnimations,
    this.valid = true,
    this.validAfterFrame = true,
    required this.pos,
    Move vector = Move.down,
  }) : _typeLevel = typeLevel {
    level = typeLevel.level;
    this.vector = vector;
  }

  /// タイプ
  StageObjType get type => _typeLevel.type;
  set type(StageObjType t) => _typeLevel.type = type;

  /// レベル
  int get level => _typeLevel.level;
  set level(int l) {
    if (!levelToAnimations.containsKey(l)) {
      log('no animation for level $l in ${_typeLevel.type}');
      animationComponent.animation = levelToAnimations[0]![vector];
    } else {
      animationComponent.animation = levelToAnimations[l]![vector];
    }
    animationComponent.angle = vectorToAnimationAngles[vector] ?? 0;
    _typeLevel.level = l;
  }

  /// 向いている方向
  Move get vector => _vector;
  set vector(Move v) {
    if (hasVector) {
      if (!MoveExtent.straights.contains(v)) {
        return;
      }
      _vector = v;
    } else {
      _vector = Move.none;
    }
    int key = levelToAnimations.containsKey(level) ? level : 0;
    animationComponent.animation = levelToAnimations[key]![vector];
    animationComponent.angle = vectorToAnimationAngles[vector] ?? 0;
  }

  /// 対象とタイプ・レベルが一致しているかどうか
  bool isSameTypeLevel(StageObj o) {
    return o._typeLevel == _typeLevel;
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

  /// このオブジェクトは押せるか
  bool get pushable;

  /// このオブジェクトは押す対象にならず、移動もできないか
  bool get stopping;

  /// このオブジェクトは押したオブジェクトの移動先になり得るか
  bool get puttable;

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

  /// このオブジェクトを削除
  void remove() => valid = false;

  /// 今フレームの終わりにこのオブジェクトを削除
  void removeAfterFrame() => validAfterFrame = false;

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
    // 今プレイヤーの移動先にいるなら移動しない
    if (pos == player.pos + player.moving.point) {
      cand.add(Move.none);
    } else {
      if (containStop) {
        cand.add(Move.none);
      }
      for (final move in MoveExtent.straights) {
        Point eTo = pos + move.point;
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
        if (prohibitedPoints.containsKey(eTo) &&
            (prohibitedPoints[eTo] == Move.none ||
                prohibitedPoints[eTo] == move)) {
          continue;
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

  void _enemyMoveFollow(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    StageObj target,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints,
  ) {
    // 今ターゲットの移動先にいるなら移動しない
    if (pos == target.pos + target.moving.point) {
      ret['move'] = Move.none;
    } else if (Random().nextInt(6) == 0) {
      ret['move'] = Move.none;
    } else {
      // ターゲットの方へ移動する/向きを変える
      final delta = target.pos - pos;
      final List<Move> tmpCand = [];
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
      final List<Move> cand = [];
      for (final move in tmpCand) {
        Point eTo = pos + move.point;
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
        if (prohibitedPoints.containsKey(eTo) &&
            (prohibitedPoints[eTo] == Move.none ||
                prohibitedPoints[eTo] == move)) {
          continue;
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
    // 今ターゲットの移動先にいるなら移動しない、ゴーストなら解除する
    if (pos == target.pos + target.moving.point) {
      ret['move'] = Move.none;
      ret['ghost'] = false;
    } else if (Random().nextInt(6) == 0) {
      ret['move'] = Move.none;
      ret['ghost'] = isGhost;
    } else {
      // ゴースト解除できるかどうかの判定
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
        if (prohibitedPoints.containsKey(p) &&
            (prohibitedPoints[p] == Move.none || prohibitedPoints[p] == move)) {
          return false;
        }
        return true;
      }

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

  /// 敵の動きを決定する
  Map<String, dynamic> enemyMove(
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    Map<Point, Move> prohibitedPoints, {
    bool isGhost = false,
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
        // 向いている方向の3マスにプレイヤーがいるなら攻撃
        final tmp = MoveExtent.straights;
        tmp.remove(vector);
        tmp.remove(vector.oppsite);
        final attackable = pos + vector.point;
        final attackables = [attackable];
        for (final v in tmp) {
          attackables.add(attackable + v.point);
        }
        if (attackables.contains(player.pos)) {
          ret['attack'] = true;
        } else {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackRound8:
        // 周囲8マスにプレイヤーがいるなら攻撃
        if (PointRectRange(
                Point(pos.x - 1, pos.y - 1), Point(pos.x + 1, pos.y + 1))
            .contains(player.pos)) {
          ret['attack'] = true;
        } else {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackStraight5:
        // 前方直線状5マスにプレイヤーがいるなら攻撃
        if (PointRectRange(pos, pos + vector.point * 5).contains(player.pos)) {
          ret['attack'] = true;
        } else {
          _enemyMoveFollow(
              ret, pattern, vector, player, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerWithGhosting:
        // プレイヤーの方へ動くor向く、通れない場合はゴースト化する/通れるならゴースト解除する
        _enemyMoveFollowWithGhosting(ret, pattern, vector, player, player,
            stage, prohibitedPoints, isGhost);
        break;
    }

    return ret;
  }

  Map<String, dynamic> encode() {
    return {
      'typeLevel': _typeLevel.encode(),
      'pos': pos.encode(),
      'vector': vector.index
    };
  }
}
