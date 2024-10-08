import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
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

  Map<String, dynamic> encode() {
    return {'typeLevel': typeLevel.encode(), 'pos': pos.encode()};
  }
}
