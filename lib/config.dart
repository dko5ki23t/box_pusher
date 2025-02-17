import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flame/components.dart' hide Block;
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

const String baseConfigFileName = 'assets/texts/config_base.json';
const String blockFloorMapConfigFileName =
    'assets/texts/config_block_floor_map.csv';
const String objInBlockMapConfigFileName =
    'assets/texts/config_obj_in_block_map.csv';
const String blockFloorDistributionConfigFileName =
    'assets/texts/config_block_floor_distribution.csv';
const String objInBlockDistributionConfigFileName =
    'assets/texts/config_obj_in_block_distribution.csv';
const String floorInBlockDistributionConfigFileName =
    'assets/texts/config_floor_in_block_distribution.csv';
const String maxObjNumFromBlockMapConfigFileName =
    'assets/texts/config_max_obj_num_from_block_map.csv';
const String jewelLevelInBlockMapConfigFileName =
    'assets/texts/config_jewel_level_in_block_map.csv';
const String fixedStaticObjMapConfigFileName =
    'assets/texts/config_fixed_static_obj_map.csv';
const String mergeAppearObjMapConfigFileName =
    'assets/texts/config_merge_appear_obj_map.csv';
const String shopInfoConfigFileName = 'assets/texts/config_shop_info.csv';

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

  /// プレイヤーの方へ動くor向く、直線3マスを攻撃する
  followPlayerAttackStraight3,

  /// プレイヤーの方へ動くor向く、直線5マスを攻撃する
  followPlayerAttackStraight5,

  /// プレイヤーの方へ動くor向く、前方3方向の直線5マスを攻撃する
  followPlayerAttack3Straight5,

  /// プレイヤーの方へ動くor向く、攻撃範囲より遠ければワープする、直線5マスを攻撃する
  followWarpPlayerAttackStraight5,

  /// プレイヤーの方へ動くor向く、通れない場合はゴースト化する/通れるならゴースト解除する
  followPlayerWithGhosting,

  /// ランダムに動く(オブジェクトがあれば押す)orその場にとどまる
  walkAndPushRandomOrStop,
}

/// プレイヤー操作ボタンタイプ
enum PlayerControllButtonType {
  /// ジョイスティック
  joyStick,

  /// 画面端にボタン配置
  onScreenEdge,

  /// 画面下部にまとめて配置
  onScreenBottom,

  /// 画面下部にまとめて配置(上下左右と斜めは切り替えボタンで表示を切り替える)
  onScreenBottom2,

  /// ボタンなし
  noButton,
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

/// ショップの情報
class ShopInfo {
  int payCoins;
  Map<StageObjTypeLevel, int> payObj;
  StageObjTypeLevel getObj;

  ShopInfo(
      {required this.payCoins, required this.payObj, required this.getObj});
}

class Config {
  static final Config _instance = Config._internal();

  static const String gameTextFamily = 'NotoSansJP';

  static const TextStyle gameTextStyle =
      TextStyle(fontFamily: Config.gameTextFamily, color: Color(0xff000000));

  factory Config() => _instance;

  Config._internal();

  bool _isReady = false;

  // デバッグモードで編集できるパラメータ
  /// ステージの最大横幅
  int debugStageWidth = 100;

  /// ステージの最大高さ
  int debugStageHeight = 100;

  /// ステージの最大横幅の設定可能範囲
  List<int> debugStageWidthClamps = [12, 200];

  /// ステージの最大高さの設定可能範囲
  List<int> debugStageHeightClamps = [40, 200];

  /// マージ時に敵に与えるダメージ
  int debugEnemyDamageInMerge = 0;

  /// 爆弾爆発時に敵に与えるダメージ
  int debugEnemyDamageInExplosion = 0;

  /// 敵はプレイヤーとぶつかる（同じマスに移動する）ことができるか
  bool debugEnemyCanCollidePlayer = true;

  /// 乱数のシード
  int? _debugRandomSeed;
  int? get debugRandomSeed => _debugRandomSeed;
  set debugRandomSeed(int? v) {
    _debugRandomSeed = v;
    random = Random(v);
  }

  /// プレイヤー操作ボタンのタイプ
  PlayerControllButtonType playerControllButtonType =
      PlayerControllButtonType.onScreenBottom;

  /// ゲーム音量(0~100)
  int audioVolume = 100;

  /// チュートリアル表示が必要か
  bool showTutorial = true;

  late Random random;

  /// 分布表示に使用する色
  static final distributionMapColors = [
    Colors.pink.withAlpha(0x80),
    Colors.lightGreen.withAlpha(0x80),
    Colors.lightBlue.withAlpha(0x80),
    Colors.purple.withAlpha(0x80),
    Colors.black.withAlpha(0x80),
  ];

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
    showGotCoinsOnEnemyPos = jsonData['showGotCoinsOnEnemyPos']['value'];
    showAddedCoinOnCoin = jsonData['showAddedCoinOnCoin']['value'];
    allowMoveStraightWithoutLegAbility =
        jsonData['allowMoveStraightWithoutLegAbility']['value'];
    setObjInBlockWithDistributionAlgorithm =
        jsonData['setObjInBlockWithDistributionAlgorithm']['value'];
    isArrowPathThrough = jsonData['isArrowPathThrough']['value'];
    sumUpEnemyAttackDamage = jsonData['sumUpEnemyAttackDamage']['value'];
    consumeTrap = jsonData['consumeTrap']['value'];
    hideGameToMenu = jsonData['hideGameToMenu']['value'];
    spawnItemAroundPlayer = jsonData['spawnItemAroundPlayer']['value'];
    mergeDamageBasedMergePower =
        jsonData['mergeDamageBasedMergePower']['value'];
    var vectorData = jsonData['addedScoreEffectMove']['value'];
    addedScoreEffectMove = Vector2(vectorData['x'], vectorData['y']);
    vectorData = jsonData['updateRange']['value'];
    updateRange = Point(vectorData['x'], vectorData['y']);
    updateNearWarpDistance = jsonData['updateNearWarpDistance']['value'];
    bombNotStartAreaWidth = jsonData['bombNotStartAreaWidth']['value'];
    bombExplodingAreaWidth = jsonData['bombExplodingAreaWidth']['value'];
    builderBuildBlockTurn = jsonData['builderBuildBlockTurn']['value'];
    mergeCountForFinalLoop = jsonData['mergeCountForFinalLoop']['value'];
    blockFloorMap =
        loadBlockFloorMap(await _importCSV(blockFloorMapConfigFileName));
    objInBlockMap =
        loadObjInBlockMap(await _importCSV(objInBlockMapConfigFileName));
    blockFloorDistribution = loadBlockFloorDistribution(
        await _importCSV(blockFloorDistributionConfigFileName));
    objInBlockDistribution = loadObjInBlockDistribution(
        await _importCSV(objInBlockDistributionConfigFileName));
    floorInBlockDistribution = loadFloorInBlockDistribution(
        await _importCSV(floorInBlockDistributionConfigFileName));
    maxObjNumFromBlockMap = loadAndSumMaxObjectNumFromBlockMap(
        await _importCSV(maxObjNumFromBlockMapConfigFileName));
    jewelLevelInBlockMap = loadJewelLevelInBlockMap(
        await _importCSV(jewelLevelInBlockMapConfigFileName));
    fixedStaticObjMap =
        loadFixedObjMap(await _importCSV(fixedStaticObjMapConfigFileName));
    mergeAppearObjMap = loadMergeAppearObjMap(
        await _importCSV(mergeAppearObjMapConfigFileName));
    shopInfoMap = loadShopInfo(await _importCSV(shopInfoConfigFileName));
    // ショップ位置周辺マスを固定マスとして登録
    for (final shopPos in shopInfoMap.keys) {
      fixedStaticObjMap[shopPos] =
          StageObjTypeLevel(type: StageObjType.shop, level: 1); // たぬき
      fixedStaticObjMap[shopPos + Point(-1, 1)] =
          StageObjTypeLevel(type: StageObjType.shop, level: 2); // 葉っぱマーク
      fixedStaticObjMap[shopPos + Point(0, 1)] =
          StageObjTypeLevel(type: StageObjType.shop, level: 3); // 矢印
      fixedStaticObjMap[shopPos + Point(1, 1)] =
          StageObjTypeLevel(type: StageObjType.shop, level: 4); // 星マーク
    }
    random = Random(debugRandomSeed);
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

  /// コイン加算表示(+1とか)を現在のコインの上に表示するかどうか
  late bool showAddedCoinOnCoin;

  /// コイン加算表示(+1とか)を敵位置に表示するかどうか
  late bool showGotCoinsOnEnemyPos;

  /// 足の能力がオフなのに斜め移動をしたとき、上下左右いずれかの移動に切り替えるかどうか(falseなら移動できない)
  late bool allowMoveStraightWithoutLegAbility;

  /// ブロック破壊時出現オブジェクトを分布で計算するアルゴリズムで決めるか(falseの場合、破壊時に毎回確率で出現オブジェクトを決める)
  late bool setObjInBlockWithDistributionAlgorithm;

  /// 弓が各オブジェクト（トラップ・敵除く）を貫通するかどうか
  late bool isArrowPathThrough;

  /// 同じマスに複数の敵の攻撃が重なった時、威力を合算するか（falseなら最大値を採用する）
  late bool sumUpEnemyAttackDamage;

  /// トラップで敵を倒すとトラップを消費（レベル下げ）するか
  late bool consumeTrap;

  /// ゲームシーケンスで画面が非表示になるとメニュー画面に遷移するかどうか
  late bool hideGameToMenu;

  /// マージ数一定回数達成時出現アイテムをプレイヤーの現在位置周辺にするかどうか(falseなら座標(0,0))
  late bool spawnItemAroundPlayer;

  /// マージ能力で与える敵へのダメージを、マージしたレベルに応じた値にするかどうか
  late bool mergeDamageBasedMergePower;

  /// スコア加算表示(+100とか)エフェクトの移動量
  late Vector2 addedScoreEffectMove;

  /// update()で更新する範囲（プレイヤー位置を起点としてこの分だけ左上、右下に移動した点で四角形を作る）
  late Point updateRange;

  /// update()で更新する各ワープからの距離
  late int updateNearWarpDistance;

  /// ボムが起爆しない正方形範囲の辺の長さ(必ず奇数で)
  late int bombNotStartAreaWidth;

  /// ボムの爆発正方形範囲の辺の長さ(必ず奇数で)
  late int bombExplodingAreaWidth;

  /// ブロックを置く敵がブロックを置く間隔（ターン数）
  late int builderBuildBlockTurn;

  /// マージ回数で出現するアイテムが最終的に無限ループする際、アイテムが出現するまでのマージ回数
  late int mergeCountForFinalLoop;

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

  /// ステージ上範囲->出現床/ブロックの分布マップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, Distribution<StageObjTypeLevel>> blockFloorDistribution;

  Map<PointRange, Distribution<StageObjTypeLevel>> loadBlockFloorDistribution(
      List<List<String>> data) {
    final Map<PointRange, Distribution<StageObjTypeLevel>> ret = {};
    // 最初の1行は無視
    for (int i = 1; i < data.length; i++) {
      final vals = data[i];
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          Distribution({
        StageObjTypeLevel(type: StageObjType.none): int.parse(vals[7]),
        StageObjTypeLevel(type: StageObjType.water): int.parse(vals[8]),
        StageObjTypeLevel(type: StageObjType.magma): int.parse(vals[9]),
        StageObjTypeLevel(type: StageObjType.block, level: 1):
            int.parse(vals[10]),
        StageObjTypeLevel(type: StageObjType.block, level: 2):
            int.parse(vals[11]),
        StageObjTypeLevel(type: StageObjType.block, level: 3):
            int.parse(vals[12]),
        StageObjTypeLevel(type: StageObjType.block, level: 4):
            int.parse(vals[13]),
      }, int.parse(vals[6]));
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「出現床/ブロック」の分布を返す
  /// 見つからない場合は最後のEntryを返す
  Distribution<StageObjTypeLevel> getBlockFloorDistribution(Point pos) {
    for (final pattern in blockFloorDistribution.entries) {
      if (pattern.key.contains(pos)) {
        return pattern.value;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するDistributionが見つからなかった。');
    return blockFloorDistribution.values.last;
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

  /// ステージ上範囲->ブロック破壊時の出現オブジェクトの分布マップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, Distribution<StageObjTypeLevel>> objInBlockDistribution;

  Map<PointRange, Distribution<StageObjTypeLevel>> loadObjInBlockDistribution(
      List<List<String>> data) {
    final Map<PointRange, Distribution<StageObjTypeLevel>> ret = {};
    // 最初の1行は無視
    for (int i = 1; i < data.length; i++) {
      final vals = data[i];
      final objsMap = {
        StageObjTypeLevel(type: StageObjType.jewel): int.parse(vals[7])
      };
      for (int j = 8; j < vals.length; j += 3) {
        objsMap[StageObjTypeLevel(
            type: StageObjTypeExtent.fromStr(vals[j]),
            level: int.parse(vals[j + 1]))] = int.parse(vals[j + 2]);
      }
      final distr = Distribution(objsMap, int.parse(vals[6]));
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          distr;
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

  /// ステージ上範囲->ブロック破壊時に出現する床の分布マップ（範囲が重複する場合は先に存在するキーを優先）
  late Map<PointRange, Distribution<StageObjTypeLevel>>
      floorInBlockDistribution;

  Map<PointRange, Distribution<StageObjTypeLevel>> loadFloorInBlockDistribution(
      List<List<String>> data) {
    final Map<PointRange, Distribution<StageObjTypeLevel>> ret = {};
    // 最初の1行は無視
    for (int i = 1; i < data.length; i++) {
      final vals = data[i];
      ret[PointRange.createFromStrings([for (int j = 0; j < 6; j++) vals[j]])] =
          Distribution({
        StageObjTypeLevel(type: StageObjType.none): int.parse(vals[7]),
        StageObjTypeLevel(type: StageObjType.water): int.parse(vals[8]),
      }, int.parse(vals[6]));
    }
    return ret;
  }

  /// 引数で指定した座標に該当する「ブロック破壊時の出現床」のMapEntryを返す
  /// 見つからない場合は最後のEntryを返す
  MapEntry<PointRange, Distribution<StageObjTypeLevel>> getFloorInBlockMapEntry(
      Point pos) {
    for (final floorInBlock in floorInBlockDistribution.entries) {
      if (floorInBlock.key.contains(pos)) {
        return floorInBlock;
      }
    }
    log('(${pos.x}, ${pos.y})に対応するfloorInBlockが見つからなかった。');
    return floorInBlockDistribution.entries.last;
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

  /// マージしたオブジェクトの破壊パワー取得
  static int getMergePower(int basePower, StageObj obj) {
    if (obj.level >= 13) {
      return basePower + 4;
    } else if (obj.level >= 8) {
      return basePower + 3;
    } else if (obj.level >= 4) {
      return basePower + 2;
    }
    return basePower + 1;
  }

  /// マージしたオブジェクトが、対象のブロックを破壊できるかどうか
  static bool canBreakBlock(Block block, int mergePower) {
    switch (block.level) {
      case 1:
        return mergePower >= 1;
      case 2:
        return mergePower >= 2;
      case 3:
        return mergePower >= 3;
      case 4:
        return mergePower >= 4;
      // ここからは敵が生み出すブロック
      case 101:
        return mergePower >= 2;
      case 102:
        return mergePower >= 3;
      case 103:
        return mergePower >= 4;
      case Block.unbreakableLevel:
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
  late Map<int, List<List<StageObjTypeLevel>>> mergeAppearObjMap;

  Map<int, List<List<StageObjTypeLevel>>> loadMergeAppearObjMap(
      List<List<String>> data) {
    final Map<int, List<List<StageObjTypeLevel>>> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      final List<StageObjTypeLevel> objs = [];
      for (int j = 1; j < vals.length; j += 2) {
        objs.add(StageObjTypeLevel(
            type: StageObjTypeExtent.fromStr(vals[j]),
            level: int.tryParse(vals[j + 1]) ?? 1));
      }
      if (ret.containsKey(int.parse(vals[0]))) {
        ret[int.parse(vals[0])]!.add(objs);
      } else {
        ret[int.parse(vals[0])] = [objs];
      }
    }
    return ret;
  }

  /// ステージ上の位置->ショップ情報のマップ
  late Map<Point, ShopInfo> shopInfoMap;

  Map<Point, ShopInfo> loadShopInfo(List<List<String>> data) {
    final Map<Point, ShopInfo> ret = {};
    // 最初の2行は無視
    for (int i = 2; i < data.length; i++) {
      final vals = data[i];
      Point shopPos = Point(int.parse(vals[0]), int.parse(vals[1]));
      int payCoins = 0;
      final Map<StageObjTypeLevel, int> payObjs = {};
      if (vals[2] == 'coin') {
        payCoins = int.parse(vals[3]);
      } else {
        payObjs[StageObjTypeLevel(
            type: StageObjTypeExtent.fromStr(vals[2]),
            level: int.parse(vals[3]))] = 1;
      }
      final getObj = StageObjTypeLevel(
          type: StageObjTypeExtent.fromStr(vals[4]), level: int.parse(vals[5]));
      ret[shopPos] =
          ShopInfo(payCoins: payCoins, payObj: payObjs, getObj: getObj);
    }
    return ret;
  }
}
