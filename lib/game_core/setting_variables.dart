import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';

enum EnemyMovePattern {
  /// 完全にランダムに動く
  walkRandom,

  /// ランダムに動くorその場にとどまる
  walkRandomOrStop,

  /// プレイヤーの方へ動くor向く
  followPlayer,

  /// プレイヤーの方へ動くor向く、前方3マスを攻撃する
  followPlayerAttackForward3,

  /// プレイヤーの方へ動くor向く、周囲8マスを攻撃する
  followPlayerAttackRound8,

  /// プレイヤーの方へ動くor向く、直線5マスを攻撃する
  followPlayerAttackStraight5,
}

enum BlockFloorPattern {
  /// 全てレベル1のブロック
  allBlockLevel1,

  /// 2%が床、それ以外はレベル1のブロック
  floor2BlockLevel1,

  /// 2%が床、10%がレベル2のブロック、それ以外はレベル1のブロック
  floor2Block10Level2BlockLevel1,
}

enum ObjInBlock {
  /// 破壊した数/2(切り上げ)個の宝石が出現
  jewel1_2,

  /// 破壊した数/2(切り上げ)個の宝石、敵/罠いずれかが1個以下出現
  jewel1_2SpikeOrTrap1,

  /// 破壊した数/2(切り上げ)個の宝石、ドリルが1個以下出現
  jewel1_2Drill1,

  /// 破壊した数/2(切り上げ)個の宝石、宝箱が1個以下出現
  jewel1_2Treasure1,

  /// 破壊した数/2(切り上げ)個の宝石、ワープが1個以下出現
  jewel1_2Warp1,

  /// 破壊した数/2(切り上げ)個の宝石、ボムが1個以下出現
  jewel1_2Bomb1,

  /// 破壊した数/2(切り上げ)個の宝石、ガーディアンが1個以下出現
  jewel1_2Guardian1,

  /// 破壊した数/2(切り上げ)個の宝石、コンベア/ガーディアン/剣を持つ敵がそれぞれ1個以下出現
  jewel1_2BeltGuardianSwordsman1,

  /// 破壊した数/2(切り上げ)個の宝石、弓を持つ敵が1個以下出現
  jewel1_2Archer1,

  /// 破壊した数/2(切り上げ)個の宝石、魔法使いが1個以下出現
  jewel1_2Wizard1,
}

class SettingVariables {
  /// 「今はオブジェクトがある位置だが、プレイヤーがそれを押すことで、プレイヤーの移動先となる座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToPushingObjectPoint = false;
  // TODO: 実装は少し手間がかかる
  /// 「今は敵または移動するオブジェクトがある位置だが、その敵やオブジェクトが移動することが確定しているため、実際には移動可能な座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToMovingEnemyPoint = true;

  /// ステージ上範囲->出現床/ブロックのマップ（範囲が重複する場合は先に存在するキーを優先）
  static Map<PointRange, BlockFloorPattern> blockFloorMap = {
    PointDistanceRange(Point(0, 0), 8): BlockFloorPattern.allBlockLevel1,
    PointDistanceRange(Point(0, 0), 10): BlockFloorPattern.floor2BlockLevel1,
    PointDistanceRange(Point(0, 0), 100):
        BlockFloorPattern.floor2Block10Level2BlockLevel1,
  };

  /// ステージ上範囲->ブロック破壊時の出現オブジェクトのマップ（範囲が重複する場合は先に存在するキーを優先）
  static Map<PointRange, ObjInBlock> objInBlockMap = {
    PointDistanceRange(Point(0, 0), 5): ObjInBlock.jewel1_2,
    PointRectRange(Point(-10, -10), Point(-5, -5)):
        ObjInBlock.jewel1_2SpikeOrTrap1,
    PointRectRange(Point(5, 5), Point(10, 10)):
        ObjInBlock.jewel1_2BeltGuardianSwordsman1,
    PointDistanceRange(Point(0, 0), 10): ObjInBlock.jewel1_2,
    PointDistanceRange(Point(0, 0), 15): ObjInBlock.jewel1_2Wizard1,
    PointDistanceRange(Point(0, 0), 100): ObjInBlock.jewel1_2Guardian1,
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
}
