import 'dart:convert';

import 'package:flame/components.dart' hide Block;
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
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

class ObjInBlock {
  /// 破壊した数の内、宝石が含まれる割合
  final int jewelPercent;

  /// 宝石以外で出現するアイテム
  final List<StageObjTypeLevel> items1;

  /// 宝石以外で出現するアイテムの最大個数
  final int itemsMaxNum1;

  ObjInBlock(this.jewelPercent, this.items1, this.itemsMaxNum1);

  ObjInBlock.fromStrings(List<String> data)
      : jewelPercent = int.parse(data[0]),
        items1 = [],
        itemsMaxNum1 = int.parse(data[1]) {
    for (int i = 2; i < data.length; i += 2) {
      items1.add(StageObjTypeLevel(
          type: StageObjTypeExtent.fromStr(data[i]),
          level: int.parse(data[i + 1])));
    }
  }
}

class Config {
  static final Config _instance = Config._internal();

  factory Config() => _instance;

  Config._internal();

  bool _isReady = false;

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

  /// ステージ上範囲->ブロック破壊時の出現オブジェクトのマップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, ObjInBlock> objInBlockMap = {
    PointDistanceRange(Point(0, 0), 5): ObjInBlock(50, [], 0),
    PointDistanceRange(Point(0, 0), 10): ObjInBlock(
        50,
        [
          StageObjTypeLevel(type: StageObjType.spike),
          StageObjTypeLevel(type: StageObjType.trap)
        ],
        2),
    PointRectRange(Point(5, 5), Point(20, 20)): ObjInBlock(
        40,
        [
          StageObjTypeLevel(type: StageObjType.belt),
          StageObjTypeLevel(type: StageObjType.guardian),
          StageObjTypeLevel(type: StageObjType.swordsman)
        ],
        1),
    PointRectRange(Point(-5, -5), Point(-20, -20)): ObjInBlock(
        40,
        [
          StageObjTypeLevel(type: StageObjType.drill),
          StageObjTypeLevel(type: StageObjType.guardian),
          StageObjTypeLevel(type: StageObjType.swordsman)
        ],
        1),
    PointDistanceRange(Point(0, 0), 20): ObjInBlock(
        40,
        [
          StageObjTypeLevel(type: StageObjType.swordsman),
          StageObjTypeLevel(type: StageObjType.guardian),
          StageObjTypeLevel(type: StageObjType.bomb),
        ],
        1),
    PointDistanceRange(Point(0, 0), 25): ObjInBlock(
        40,
        [
          StageObjTypeLevel(type: StageObjType.swordsman, level: 2),
          StageObjTypeLevel(type: StageObjType.archer),
          StageObjTypeLevel(type: StageObjType.drill),
          StageObjTypeLevel(type: StageObjType.trap),
          StageObjTypeLevel(type: StageObjType.bomb),
          StageObjTypeLevel(type: StageObjType.warp),
        ],
        2),
    PointDistanceRange(Point(0, 0), 100):
        ObjInBlock(50, [StageObjTypeLevel(type: StageObjType.guardian)], 0),
  };

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

  /// マージしたオブジェクトが、対象のブロックを破壊できるかどうか
  static bool canBreakBlock(Block block, StageObj mergeObj) {
    if (mergeObj.type == StageObjType.block) return true;
    switch (block.level) {
      case 1:
        return true;
      case 2:
        return mergeObj.level >= 4;
      case 3:
        return mergeObj.level >= 8;
      case 4:
        return mergeObj.level >= 13;
      // ここからは敵が生み出すブロック
      case 101:
        return mergeObj.level >= 4;
      case 102:
        return mergeObj.level >= 8;
      case 103:
        return mergeObj.level >= 13;
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
