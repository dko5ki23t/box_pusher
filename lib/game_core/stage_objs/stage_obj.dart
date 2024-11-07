import 'dart:developer';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

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
  gorilla,
}

extension StageObjTypeExtent on StageObjType {
  static Map<StageObjType, String> strMap = {
    StageObjType.none: ' ',
    StageObjType.block: '#',
    StageObjType.trap: '.',
    StageObjType.jewel: 'o',
    StageObjType.player: 'p',
    StageObjType.spike: 's',
    StageObjType.drill: 'd',
    StageObjType.treasureBox: 'b',
    StageObjType.warp: 'w',
    StageObjType.bomb: 'B',
    StageObjType.belt: 'blt',
    StageObjType.guardian: 'g',
    StageObjType.water: 'W',
    StageObjType.magma: 'm',
    StageObjType.swordsman: 'S',
    StageObjType.archer: 'a',
    StageObjType.wizard: 'M',
    StageObjType.gorilla: 'G',
  };

  String get str => strMap[this]!;

  static StageObjType fromStr(String str) {
    for (final entry in strMap.entries) {
      if (entry.value == str) {
        return entry.key;
      }
    }
    assert(false, 'invalid str');
    return StageObjType.none;
  }
}

class StageObjTypeLevel {
  StageObjType type;
  int level;

  StageObjTypeLevel({required this.type, this.level = 1});

  Map<String, dynamic> encode() {
    return {'type': type.str, 'level': level};
  }

  static decode(Map<String, dynamic> src) {
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
  Point pos; // 現在位置
  bool valid;
  SpriteAnimationComponent animationComponent;
  Map<int, Map<Move, SpriteAnimation>>
      levelToAnimations; // オブジェクトのレベル->向き->アニメーションのマップ
  Move moving = Move.none; // 移動中の向き
  Move _vector = Move.down; // 向いている方向
  double movingAmount = 0;
  final List<StageObj> pushings = []; // 押しているオブジェクト

  StageObj({
    required typeLevel,
    required this.animationComponent,
    required this.levelToAnimations,
    this.valid = true,
    required this.pos,
    Move? vector,
  }) : _typeLevel = typeLevel {
    level = typeLevel.level;
    if (vector != null) {
      this.vector = vector;
    }
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
    _typeLevel.level = l;
  }

  /// 向いている方向
  Move get vector => _vector;
  set vector(Move v) {
    _vector = v;
    int key = levelToAnimations.containsKey(level) ? level : 0;
    animationComponent.animation = levelToAnimations[key]![v];
  }

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
    List<Point> prohibitedPoints, // 今は移動可能だが、他のオブジェクトが同時期に移動してくるため移動不可な座標のリスト
  );

  /// このオブジェクトは押せるか
  bool get pushable;

  /// このオブジェクトは押す対象にならず、移動もできないか
  bool get stopping;

  /// このオブジェクトは押したオブジェクトの移動先になり得るか
  bool get puttable;

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

  void _enemyMoveFollow(
    Map<String, dynamic> ret,
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    List<Point> prohibitedPoints,
  ) {
    // 今プレイヤーの移動先にいるなら移動しない
    if (pos == player.pos + player.moving.point) {
      ret['move'] = Move.none;
    } else {
      // プレイヤーの方へ移動する/向きを変える
      final delta = player.pos - pos;
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
        if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.puttable &&
            !(eToObj.type == type && eToObj.level == level)) {
          continue;
        }
        if (prohibitedPoints.contains(eTo)) {
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
        prohibitedPoints.add(pos + move.point);
      } else if (tmpCand.isNotEmpty) {
        // 向きだけ変更
        ret['vector'] = tmpCand.sample(1).first;
      }
    }
  }

  /// 敵の動きを決定する
  Map<String, dynamic> enemyMove(
    EnemyMovePattern pattern,
    Move vector,
    Player player,
    Stage stage,
    List<Point> prohibitedPoints,
  ) {
    Map<String, dynamic> ret = {};

    switch (pattern) {
      case EnemyMovePattern.walkRandom:
      case EnemyMovePattern.walkRandomOrStop:
        final List<Move> cand = [];
        // 今プレイヤーの移動先にいるなら移動しない
        if (pos == player.pos + player.moving.point) {
          cand.add(Move.none);
        } else {
          if (pattern == EnemyMovePattern.walkRandomOrStop) {
            cand.add(Move.none);
          }
          for (final move in MoveExtent.straights) {
            Point eTo = pos + move.point;
            final eToObj = stage.get(eTo);
            if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
                player.pushings.isNotEmpty &&
                player.pushings.first.pos == eTo) {
              // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
            } else if (!eToObj.puttable &&
                (eToObj.type != type || eToObj.level != level)) {
              continue;
            }
            if (prohibitedPoints.contains(eTo)) {
              continue;
            }
            cand.add(move);
          }
        }
        if (cand.isNotEmpty) {
          final move = cand.sample(1).first;
          ret['move'] = move;
          // 自身の移動先は、他のオブジェクトの移動先にならないようにする
          prohibitedPoints.add(pos + move.point);
        }
        break;
      case EnemyMovePattern.followPlayer:
        _enemyMoveFollow(ret, pattern, vector, player, stage, prohibitedPoints);
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
              ret, pattern, vector, player, stage, prohibitedPoints);
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
              ret, pattern, vector, player, stage, prohibitedPoints);
        }
        break;
      case EnemyMovePattern.followPlayerAttackStraight5:
        // 前方直線状5マスにプレイヤーがいるなら攻撃
        if (PointRectRange(pos, pos + vector.point * 5).contains(player.pos)) {
          ret['attack'] = true;
        } else {
          _enemyMoveFollow(
              ret, pattern, vector, player, stage, prohibitedPoints);
        }
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
