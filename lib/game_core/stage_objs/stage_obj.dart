import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

/// ステージ上オブジェクトの種類
enum StageObjType {
  none,
  wall,
  trap,
  box,
  player,
  spike, // とげの敵
  drill,
  treasureBox,
  warp,
  bomb,
  beltL,
  beltR,
  beltU,
  beltD,
  guardian,
  water,
  magma,
  swordsman, // 剣を使う敵
  archer, // 弓を使う敵
  wizard, // 魔法を使う敵
}

extension StageObjTypeExtent on StageObjType {
  static Map<StageObjType, String> strMap = {
    StageObjType.none: ' ',
    StageObjType.wall: '#',
    StageObjType.trap: '.',
    StageObjType.box: 'o',
    StageObjType.player: 'p',
    StageObjType.spike: 's',
    StageObjType.drill: 'd',
    StageObjType.treasureBox: 'b',
    StageObjType.warp: 'w',
    StageObjType.bomb: 'B',
    StageObjType.beltL: 'bL',
    StageObjType.beltR: 'bR',
    StageObjType.beltU: 'bU',
    StageObjType.beltD: 'bD',
    StageObjType.guardian: 'g',
    StageObjType.water: 'W',
    StageObjType.magma: 'm',
    StageObjType.swordsman: 'S',
    StageObjType.archer: 'a',
    StageObjType.wizard: 'M',
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
  StageObjTypeLevel typeLevel;
  Point pos; // 現在位置
  bool valid;
  SpriteAnimationComponent animation;
  Move moving = Move.none; // 移動中の向き
  double movingAmount = 0;
  final List<StageObj> pushings = []; // 押しているオブジェクト

  StageObj({
    required this.typeLevel,
    required this.animation,
    this.valid = true,
    required this.pos,
  });

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
        final eToObj = stage.getObject(eTo);
        if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
            player.pushings.isNotEmpty &&
            player.pushings.first.pos == eTo) {
          // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
        } else if (!eToObj.puttable && eToObj.typeLevel != typeLevel) {
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
            final eToObj = stage.getObject(eTo);
            if (SettingVariables.allowEnemyMoveToPushingObjectPoint &&
                player.pushings.isNotEmpty &&
                player.pushings.first.pos == eTo) {
              // 移動先にあるオブジェクトをプレイヤーが押すなら移動可能とする
            } else if (!eToObj.puttable && eToObj.typeLevel != typeLevel) {
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
    return {'typeLevel': typeLevel.encode(), 'pos': pos.encode()};
  }
}
