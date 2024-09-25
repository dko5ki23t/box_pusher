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
}

extension StageObjTypeExtent on StageObjType {
  static Map<StageObjType, String> strMap = {
    StageObjType.none: ' ',
    StageObjType.wall: '#',
    StageObjType.trap: '.',
    StageObjType.box: 'o',
    StageObjType.player: 'p',
    StageObjType.spike: 's',
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
}

/// ステージ上オブジェクト
abstract class StageObj {
  StageObjTypeLevel typeLevel;
  Point pos; // 現在位置
  bool valid;
  SpriteComponent sprite;
  Move moving = Move.none; // 移動中の向き
  double movingAmount = 0;
  StageObj? pushing; // 押しているオブジェクト

  StageObj({
    required this.typeLevel,
    required this.sprite,
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

  Map<String, dynamic> encode() {
    return {'typeLevel': typeLevel.encode(), 'pos': pos.encode()};
  }
}
