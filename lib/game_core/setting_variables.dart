import 'package:flame/components.dart' hide Block;
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';

enum EnemyMovePattern {
  /// 完全にランダムに動く
  walkRandom,

  /// ランダムに動くorその場にとどまる
  walkRandomOrStop,

  /// マージを目的に動く/ランダムに動くorその場にとどまる
  mergeWalkRandomOrStop,

  /// プレイヤーの方へ動くor向く
  followPlayer,

  /// プレイヤーの方へ動くor向く、前方3マスを攻撃する
  followPlayerAttackForward3,

  /// プレイヤーの方へ動くor向く、周囲8マスを攻撃する
  followPlayerAttackRound8,

  /// プレイヤーの方へ動くor向く、直線5マスを攻撃する
  followPlayerAttackStraight5,
}

class BlockFloorPattern {
  /// 床の割合
  final int floorPercent;

  /// ブロックのレベル->出現割合のMap
  final Map<int, int> blockPercents;

  BlockFloorPattern(this.floorPercent, this.blockPercents);
}

class ObjInBlock {
  /// 破壊した数の内、宝石が含まれる割合
  final int jewelPercent;

  /// 宝石以外で出現するアイテム
  final List<StageObjTypeLevel> items1;

  /// 宝石以外で出現するアイテムの最大個数
  final int itemsMaxNum1;

  ObjInBlock(this.jewelPercent, this.items1, this.itemsMaxNum1);
}

class SettingVariables {
  /// 「今はオブジェクトがある位置だが、プレイヤーがそれを押すことで、プレイヤーの移動先となる座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToPushingObjectPoint = false;
  // TODO: 実装は少し手間がかかる
  /// 「今は敵または移動するオブジェクトがある位置だが、その敵やオブジェクトが移動することが確定しているため、実際には移動可能な座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToMovingEnemyPoint = true;

  /// 斜め移動ボタンの範囲を広く取るかどうか（広く取ると上下左右のボタンを台形にして小さくするので複雑になるし、斜めボタンを誤タップしやすくなる）
  static bool wideDiagonalMoveButton = false;

  /// スコア加算表示(+100とか)を現在のスコアの上に表示するかどうか
  static bool showAddedScoreOnScore = false;

  /// スコア加算表示(+100とか)をマージ位置に表示するかどうか
  static bool showAddedScoreOnMergePos = true;

  /// スコア加算表示(+100とか)エフェクトの移動量
  static Vector2 addedScoreEffectMove = Vector2(0, -10.0);

  /// ステージ上範囲->出現床/ブロックのマップ（範囲が重複する場合は先に存在するキーを優先）
  static Map<PointRange, BlockFloorPattern> blockFloorMap = {
    PointDistanceRange(Point(0, 0), 8): BlockFloorPattern(0, {1: 100}),
    PointDistanceRange(Point(0, 0), 10): BlockFloorPattern(2, {1: 98}),
    PointDistanceRange(Point(0, 0), 10): BlockFloorPattern(5, {1: 95}),
    PointDistanceRange(Point(0, 0), 100): BlockFloorPattern(2, {1: 88, 2: 10}),
  };

  /// ステージ上範囲->ブロック破壊時の出現オブジェクトのマップ（範囲が重複する場合は先に存在するキーを優先）
  static Map<PointRange, ObjInBlock> objInBlockMap = {
    PointDistanceRange(Point(0, 0), 5): ObjInBlock(50, [], 0),
    //PointDistanceRange(Point(0, 0), 10): ObjInBlock.jewel1_2Trap1,
    PointDistanceRange(Point(0, 0), 20): ObjInBlock(
        50,
        [
          StageObjTypeLevel(type: StageObjType.spike),
          StageObjTypeLevel(type: StageObjType.trap)
        ],
        2),
    PointRectRange(Point(-10, -10), Point(-5, -5)): ObjInBlock(
        50,
        [
          StageObjTypeLevel(type: StageObjType.spike),
          StageObjTypeLevel(type: StageObjType.trap)
        ],
        1),
    PointRectRange(Point(5, 5), Point(10, 10)): ObjInBlock(
        50,
        [
          StageObjTypeLevel(type: StageObjType.belt),
          StageObjTypeLevel(type: StageObjType.guardian),
          StageObjTypeLevel(type: StageObjType.swordsman)
        ],
        1),
    PointDistanceRange(Point(0, 0), 10): ObjInBlock(50, [], 0),
    PointDistanceRange(Point(0, 0), 15):
        ObjInBlock(50, [StageObjTypeLevel(type: StageObjType.wizard)], 0),
    PointDistanceRange(Point(0, 0), 100):
        ObjInBlock(50, [StageObjTypeLevel(type: StageObjType.guardian)], 0),
  };

  /// ステージ上範囲->ブロック破壊時の出現宝石のレベル（範囲が重複する場合は先に存在するキーを優先）
  static Map<PointRange, int> jewelLevelInBlockMap = {
    PointDistanceRange(Point(0, 0), 4): 1,
    PointDistanceRange(Point(0, 0), 9): 2,
    PointDistanceRange(Point(0, 0), 16): 3,
    PointDistanceRange(Point(0, 0), 25): 4,
    PointDistanceRange(Point(0, 0), 36): 5,
    PointDistanceRange(Point(0, 0), 49): 6,
    PointDistanceRange(Point(0, 0), 64): 7,
    PointDistanceRange(Point(0, 0), 81): 8,
    PointDistanceRange(Point(0, 0), 100): 9,
    PointDistanceRange(Point(0, 0), 121): 10,
    PointDistanceRange(Point(0, 0), 1000): 11,
  };

  /// マージしたオブジェクトが、対象のブロックを破壊できるかどうか
  static bool canBreakBlock(Block block, StageObj mergeObj) {
    return block.level == 1 || mergeObj.level >= block.level * 2;
  }

  /// 助け出す動物の場所マップ
  static Map<Point, StageObjType> animalsPoints = {
    Point(-5, -5): StageObjType.gorilla,
    Point(5, 5): StageObjType.rabbit,
  };
}
