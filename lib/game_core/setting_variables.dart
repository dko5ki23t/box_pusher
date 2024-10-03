enum EnemyMovePattern {
  /// 完全にランダムに動く
  walkRandom,

  /// ランダムに動くorその場にとどまる
  walkRandomOrStop,
}

enum ObjInBlock {
  /// 破壊した数/2(切り上げ)個の宝石が出現
  jewel1_2,

  /// 破壊した数/2(切り上げ)個の宝石、敵/罠いずれかが1個以下出現
  jewel1_2SpikeOrTrap1,

  /// 破壊した数/2(切り上げ)個の宝石、ドリルが1個以下出現
  jewel1_2Drill1,

  /// 破壊した数/2(切り上げ)個の宝石、宝箱が1個以下出現
  jewel1_2Treasure,

  /// 破壊した数/2(切り上げ)個の宝石、ワープが1個以下出現
  jewel1_2Warp,
}

class SettingVariables {
  /// 「今はオブジェクトがある位置だが、プレイヤーがそれを押すことで、プレイヤーの移動先となる座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToPushingObjectPoint = false;
  // TODO: 実装は少し手間がかかる
  /// 「今は敵または移動するオブジェクトがある位置だが、その敵やオブジェクトが移動することが確定しているため、実際には移動可能な座標」
  /// に敵が移動することを許すかどうか
  static bool allowEnemyMoveToMovingEnemyPoint = true;

  /// 中心(ゲーム開始地点)からの距離->ブロック破壊時の出現オブジェクトのマップ
  static Map<int, ObjInBlock> objInBlockMap = {
    0: ObjInBlock.jewel1_2,
    6: ObjInBlock.jewel1_2Warp,
  };

  /// 中心(ゲーム開始地点)からの距離->ブロック破壊時の出現宝石のレベル
  static Map<int, int> jewelLevelInBlockMap = {
    0: 1,
    5: 2,
    10: 3,
  };
}
