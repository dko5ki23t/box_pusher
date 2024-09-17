import 'package:box_pusher/game_core/stage.dart';
import 'package:flame/components.dart';

/// ステージ上オブジェクトの種類
enum StageObjType {
  none,
  wall,
  goal,
  box,
  boxOnGoal,
  player,
  playerOnGoal,
  spike, // とげの敵
}

extension StageObjTypeExtent on StageObjType {
  String get str {
    switch (this) {
      case StageObjType.none:
        return ' ';
      case StageObjType.wall:
        return '#';
      case StageObjType.goal:
        return '.';
      case StageObjType.box:
        return 'o';
      case StageObjType.boxOnGoal:
        return 'O';
      case StageObjType.player:
        return 'p';
      case StageObjType.playerOnGoal:
        return 'P';
      case StageObjType.spike:
        return 's';
    }
  }
}

class StageObjTypeLevel {
  StageObjType type;
  int level;

  StageObjTypeLevel({required this.type, this.level = 1});
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
}
