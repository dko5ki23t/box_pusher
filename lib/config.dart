import 'dart:convert';
import 'dart:developer';

import 'package:flame/components.dart' hide Block;
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;

const String baseConfigFileName = 'assets/texts/config_base.json';
const String blockFloorMapConfigFileName =
    'assets/texts/config_block_floor_map.csv';
const String objInBlockMapConfigFileName =
    'assets/texts/config_obj_in_block_map.csv';
const String maxObjNumFromBlockMapConfigFileName =
    'assets/texts/config_max_obj_num_from_block_map.csv';
const String jewelLevelInBlockMapConfigFileName =
    'assets/texts/config_jewel_level_in_block_map.csv';
const String fixedStaticObjMapConfigFileName =
    'assets/texts/config_fixed_static_obj_map.csv';
const String mergeAppearObjMapConfigFileName =
    'assets/texts/config_merge_appear_obj_map.csv';

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

  /// プレイヤーの方へ動くor向く、通れない場合はゴースト化する/通れるならゴースト解除する
  followPlayerWithGhosting,

  /// ランダムに動く(オブジェクトがあれば押す)orその場にとどまる
  walkAndPushRandomOrStop,
}

class BlockFloorPattern {
  /// 床の割合
  final Map<StageObjTypeLevel, int> floorPercents;

  /// ブロックのレベル->出現割合のMap
  final Map<int, int> blockPercents;

  BlockFloorPattern(this.floorPercents, this.blockPercents);

  BlockFloorPattern.fromStrings(List<String> data)
      : floorPercents = {},
        blockPercents = {} {
    final List<int?> intData = [
      for (int i = 0; i < 7; i++) int.tryParse(data[i])
    ];
    if (intData[0] != null) {
      floorPercents[StageObjTypeLevel(type: StageObjType.none)] = intData[0]!;
    }
    if (intData[1] != null) {
      floorPercents[StageObjTypeLevel(type: StageObjType.water)] = intData[1]!;
    }
    if (intData[2] != null) {
      floorPercents[StageObjTypeLevel(type: StageObjType.magma)] = intData[2]!;
    }
    if (intData[3] != null) {
      blockPercents[1] = intData[3]!;
    }
    if (intData[4] != null) {
      blockPercents[2] = intData[4]!;
    }
    if (intData[5] != null) {
      blockPercents[3] = intData[5]!;
    }
    if (intData[6] != null) {
      blockPercents[4] = intData[6]!;
    }
  }
}

class NumsAndPercent {
  final int min;
  final int max;
  final int percent;

  NumsAndPercent(
    this.min,
    this.max,
    this.percent,
  );
}

class ObjInBlock {
  /// 破壊した数の内、宝石が含まれる割合
  final int jewelPercent;

  /// 宝石以外で出現するアイテム全体の最大個数
  final int itemsMaxNum;

  /// 宝石以外で出現するアイテムとその割合・最大最小個数
  final Map<StageObjTypeLevel, NumsAndPercent> itemsPercentAndNumsMap;

  ObjInBlock(
    this.jewelPercent,
    this.itemsMaxNum,
    this.itemsPercentAndNumsMap,
  );

  ObjInBlock.fromStrings(List<String> data)
      : jewelPercent = int.parse(data[0]),
        itemsMaxNum = int.parse(data[1]),
        itemsPercentAndNumsMap = {} {
    for (int i = 2; i < data.length; i += 5) {
      itemsPercentAndNumsMap[StageObjTypeLevel(
          type: StageObjTypeExtent.fromStr(data[i]),
          level: int.parse(data[i + 1]))] = NumsAndPercent(
        int.parse(data[i + 2]),
        int.parse(data[i + 3]),
        int.parse(data[i + 4]),
      );
    }
  }
}

class Config {
  static final Config _instance = Config._internal();

  static const String gameTextFamily = 'NotoSansJP';

  static const TextStyle gameTextStyle =
      TextStyle(fontFamily: Config.gameTextFamily, color: Color(0xff000000));

  factory Config() => _instance;

  Config._internal();

  bool _isReady = false;

  /// デバッグモードで編集できるパラメータ
  int debugStageWidth = 200;
  int debugStageHeight = 200;
  List<int> debugStageWidthClamps = [12, 200];
  List<int> debugStageHeightClamps = [40, 200];
  int debugEnemyDamageInMerge = 0;
  int debugEnemyDamageInExplosion = 0;
  bool debugPrepareAllStageDataAtFirst = true;

  /// 敵はプレイヤーとぶつかる（同じマスに移動する）ことができるか
  bool debugEnemyCanCollidePlayer = true;

  Future<List<List<String>>> _importCSV(String filename) async {
    List<List<String>> ret = [];
    final data = await rootBundle.loadString(filename);
    List<String> lines = const LineSplitter().convert(data);
    for (final line in lines) {
      ret.add([for (final raw in line.split(',')) raw.trim()]);
    }
    return ret;
  }

  /// assetのファイルからコンフィグ情報を読み込む。
  /// 各変数使う前に必ず呼び出すこと
  Future<void> initialize() async {
    if (_isReady) return;
    final data = await rootBundle.loadString(baseConfigFileName);
    final jsonData = json.decode(data);
    allowEnemyMoveToPushingObjectPoint =
        jsonData['allowEnemyMoveToPushingObjectPoint']['value'];
    allowEnemyMoveToMovingEnemyPoint =
        jsonData['allowEnemyMoveToMovingEnemyPoint']['value'];
    wideDiagonalMoveButton = jsonData['wideDiagonalMoveButton']['value'];
    showAddedScoreOnScore = jsonData['showAddedScoreOnScore']['value'];
    showAddedScoreOnMergePos = jsonData['showAddedScoreOnMergePos']['value'];
    allowMoveStraightWithoutLegAbility =
        jsonData['allowMoveStraightWithoutLegAbility']['value'];
    setObjInBlockWithDistributionAlgorithm =
        jsonData['setObjInBlockWithDistributionAlgorithm']['value'];
    var vectorData = jsonData['addedScoreEffectMove']['value'];
    addedScoreEffectMove = Vector2(vectorData['x'], vectorData['y']);
    bombNotStartAreaWidth = jsonData['bombNotStartAreaWidth']['value'];
    bombExplodingAreaWidth = jsonData['bombExplodingAreaWidth']['value'];
    builderBuildBlockTurn = jsonData['builderBuildBlockTurn']['value'];
    blockFloorMap =
        loadBlockFloorMap(await _importCSV(blockFloorMapConfigFileName));
    objInBlockMap =
        loadObjInBlockMap(await _importCSV(objInBlockMapConfigFileName));
    maxObjNumFromBlockMap = loadAndSumMaxObjectNumFromBlockMap(
        await _importCSV(maxObjNumFromBlockMapConfigFileName));
    jewelLevelInBlockMap = loadJewelLevelInBlockMap(
        await _importCSV(jewelLevelInBlockMapConfigFileName));
    fixedStaticObjMap =
        loadFixedObjMap(await _importCSV(fixedStaticObjMapConfigFileName));
    mergeAppearObjMap = loadMergeAppearObjMap(
        await _importCSV(mergeAppearObjMapConfigFileName));
    _isReady = true;
  }

  /// 「今はオブジェクトがある位置だが、プレイヤーがそれを押すことで、プレイヤーの移動先となる座標」
  /// に敵が移動することを許すかどうか
  late bool allowEnemyMoveToPushingObjectPoint;

  // TODO: 実装は少し手間がかかる
  /// 「今は敵または移動するオブジェクトがある位置だが、その敵やオブジェクトが移動することが確定しているため、実際には移動可能な座標」
  /// に敵が移動することを許すかどうか
  late bool allowEnemyMoveToMovingEnemyPoint;

  /// 斜め移動ボタンの範囲を広く取るかどうか（広く取ると上下左右のボタンを台形にして小さくするので複雑になるし、斜めボタンを誤タップしやすくなる）
  late bool wideDiagonalMoveButton;

  /// スコア加算表示(+100とか)を現在のスコアの上に表示するかどうか
  late bool showAddedScoreOnScore;

  /// スコア加算表示(+100とか)をマージ位置に表示するかどうか
  late bool showAddedScoreOnMergePos;

  /// 足の能力がオフなのに斜め移動をしたとき、上下左右いずれかの移動に切り替えるかどうか(falseなら移動できない)
  late bool allowMoveStraightWithoutLegAbility;

  /// ブロック破壊時出現オブジェクトを分布で計算するアルゴリズムで決めるか(falseの場合、破壊時に毎回確率で出現オブジェクトを決める)
  late bool setObjInBlockWithDistributionAlgorithm;

  /// スコア加算表示(+100とか)エフェクトの移動量
  late Vector2 addedScoreEffectMove;

  /// ボムが起爆しない正方形範囲の辺の長さ(必ず奇数で)
  late int bombNotStartAreaWidth;

  /// ボムの爆発正方形範囲の辺の長さ(必ず奇数で)
  late int bombExplodingAreaWidth;

  /// ブロックを置く敵がブロックを置く間隔（ターン数）
  late int builderBuildBlockTurn;

  /// ステージ上範囲->出現床/ブロックのマップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, BlockFloorPattern> blockFloorMap;

  Map<PointRange, BlockFloorPattern> loadBlockFloorMap(
      List<List<String>> data) {
    final Map<PointRange, BlockFloorPattern> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          BlockFloorPattern.fromStrings([for (int j = 6; j < 13; j++) vals[j]]);
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「出現床/ブロック」のMapを返す
  /// 見つからない場合は最後のEntryを返す
  BlockFloorPattern getBlockFloorPattern(Point pos) {
    for (final pattern in blockFloorMap.entries) {
      if (pattern.key.contains(pos)) {
        return pattern.value;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するblockFloorPatternが見つからなかった。');
    return blockFloorMap.values.last;
  }

  /// ステージ上範囲->ブロック破壊時の出現オブジェクトのマップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, ObjInBlock> objInBlockMap;

  Map<PointRange, ObjInBlock> loadObjInBlockMap(List<List<String>> data) {
    final Map<PointRange, ObjInBlock> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          ObjInBlock.fromStrings(
              [for (int j = 6; j < vals.length; j++) vals[j]]);
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「ブロック破壊時の出現オブジェクト」のMapEntryを返す
  /// 見つからない場合は最後のEntryを返す
  MapEntry<PointRange, ObjInBlock> getObjInBlockMapEntry(Point pos) {
    for (final objInBlock in objInBlockMap.entries) {
      if (objInBlock.key.contains(pos)) {
        return objInBlock;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するobjInBlockが見つからなかった。');
    return objInBlockMap.entries.last;
  }

  /// ステージ上範囲->ブロック破壊時に出現する特定オブジェクトの個数制限
  late final Map<PointRange, Map<StageObjTypeLevel, int>> maxObjNumFromBlockMap;

  Map<PointRange, Map<StageObjTypeLevel, int>>
      loadAndSumMaxObjectNumFromBlockMap(List<List<String>> data) {
    final Map<PointRange, Map<StageObjTypeLevel, int>> ret = {};
    final Map<StageObjTypeLevel, int> currentValues = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      final range =
          PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]]);
      for (int j = 6; j < vals.length; j += 3) {
        final typeLevel = StageObjTypeLevel(
            type: StageObjTypeExtent.fromStr(vals[j]),
            level: int.parse(vals[j + 1]));
        if (currentValues.containsKey(typeLevel)) {
          currentValues[typeLevel] =
              currentValues[typeLevel]! + int.parse(vals[j + 2]);
        } else {
          currentValues[typeLevel] = int.parse(vals[j + 2]);
        }
      }
      ret[range] = {for (final e in currentValues.entries) e.key: e.value};
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「ブロック破壊時に出現する特定オブジェクトの個数制限」のMapを返す
  /// 見つからない場合は最後のEntryを返す
  Map<StageObjTypeLevel, int> getMaxObjNumFromBlock(Point pos) {
    for (final objMaxNum in maxObjNumFromBlockMap.entries) {
      if (objMaxNum.key.contains(pos)) {
        return objMaxNum.value;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するmaxObjNumFromBlockが見つからなかった。');
    return maxObjNumFromBlockMap.values.last;
  }

  /// ステージ上範囲->ブロック破壊時の出現宝石のレベル（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, int> jewelLevelInBlockMap;

  Map<PointRange, int> loadJewelLevelInBlockMap(List<List<String>> data) {
    final Map<PointRange, int> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          int.parse(vals[6]);
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「ブロック破壊時の出現宝石のレベル」を返す
  /// 見つからない場合は最後のEntryのレベルを返す
  int getJewelLevel(Point pos) {
    for (final entry in jewelLevelInBlockMap.entries) {
      if (entry.key.contains(pos)) {
        return entry.value;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するjewelLevelが見つからなかった。');
    return jewelLevelInBlockMap.values.last;
  }

  /// マージしたオブジェクトが、対象のブロックを破壊できるかどうか
  static bool canBreakBlock(Block block, StageObjTypeLevel mergeTypeLevel) {
    if (mergeTypeLevel.type == StageObjType.block) {
      return true;
    }
    switch (block.level) {
      case 1:
        return true;
      case 2:
        return mergeTypeLevel.level >= 4;
      case 3:
        return mergeTypeLevel.level >= 8;
      case 4:
        return mergeTypeLevel.level >= 13;
      // ここからは敵が生み出すブロック
      case 101:
        return mergeTypeLevel.level >= 4;
      case 102:
        return mergeTypeLevel.level >= 8;
      case 103:
        return mergeTypeLevel.level >= 13;
      default:
        return false;
    }
  }

  /// 固定位置オブジェクトのマップ
  late Map<Point, StageObjTypeLevel> fixedStaticObjMap;

  Map<Point, StageObjTypeLevel> loadFixedObjMap(List<List<String>> data) {
    final Map<Point, StageObjTypeLevel> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      ret[Point(int.parse(vals[0]), int.parse(vals[1]))] = StageObjTypeLevel(
          type: StageObjTypeExtent.fromStr(vals[2]),
          level: int.tryParse(vals[3]) ?? 1);
    }
    return ret;
  }

  /// マージ回数->出現オブジェクトのマップ
  late Map<int, List<StageObjTypeLevel>> mergeAppearObjMap;

  Map<int, List<StageObjTypeLevel>> loadMergeAppearObjMap(
      List<List<String>> data) {
    final Map<int, List<StageObjTypeLevel>> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      final List<StageObjTypeLevel> objs = [];
      for (int j = 1; j < vals.length; j += 2) {
        objs.add(StageObjTypeLevel(
            type: StageObjTypeExtent.fromStr(vals[j]),
            level: int.tryParse(vals[j + 1]) ?? 1));
      }
      ret[int.parse(vals[0])] = objs;
    }
    return ret;
  }
}
