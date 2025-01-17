import 'dart:developer';
import 'dart:math' hide log;

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/components/opacity_effect_text_component.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/ghost.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj_factory.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart' hide Block;
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

/// 有効なオブジェクトのみを扱えるようにするリスト
class StageObjList {
  final List<StageObj> _objs = [];

  void add(StageObj obj) => _objs.add(obj);

  Iterable<StageObj> get iterable => _objs.where((element) => element.valid);
  int get length => iterable.length;
  Iterable<StageObj> where(bool Function(StageObj) test) =>
      iterable.where(test);
  StageObj firstWhere(bool Function(StageObj) test) =>
      iterable.firstWhere(test);
  StageObj? firstWhereOrNull(bool Function(StageObj) test) =>
      iterable.firstWhereOrNull(test);

  /// 基本的には使用禁止。代わりに対象StageObjのremove()を呼び出す。
  bool forceRemove(Object? e) => _objs.remove(e);

  /// 基本的には使用禁止。代わりに対象StageObjのremove()を呼び出す。
  void forceRemoveWhere(bool Function(StageObj) test) =>
      _objs.removeWhere(test);

  /// 基本的には使用禁止。代わりに対象StageObjのremove()を呼び出す。
  void forceClear() => _objs.clear();

  /// すべての要素をWorldから削除してリストもクリアする
  void clean(World gameWorld) {
    for (final obj in _objs) {
      gameWorld.remove(obj.animationComponent);
    }
    _objs.clear();
  }

  /// 無効になったオブジェクトを一括削除
  void removeAllInvalidObjects(World gameWorld) {
    for (final obj in _objs
        .where((element) => !element.valid || !element.validAfterFrame)) {
      gameWorld.remove(obj.animationComponent);
    }
    _objs.removeWhere((element) => !element.valid || !element.validAfterFrame);
  }
}

/// ブロック/床の出現個数を保持
class BlockFloorNums {
  /// 床の個数
  final Map<StageObjTypeLevel, int> floorNums;

  /// ブロックのレベル->出現個数のMap
  final Map<int, int> blockNums;

  BlockFloorNums(this.floorNums, this.blockNums);
}

/// マージの範囲、ブロック破壊判定、敵へのダメージ
class MergeAffect {
  final Point basePoint; // 起点
  final PointRange range;
  final bool Function(Block) canBreakBlockFunc;
  final int enemyDamage;

  MergeAffect({
    required this.basePoint,
    required this.range,
    required this.canBreakBlockFunc,
    required this.enemyDamage,
  });
}

class SetAndDistribution<T> {
  final Set set;
  final Future<Distribution<T>> distribution;

  SetAndDistribution(this.set, this.distribution);
}

class Score extends ValueWithAddingTime {
  Score(int initialScore)
      : super(
          initialValue: initialScore,
          completeAddingTime: 0.3,
          maxValue: Stage.maxScore,
        );
}

class Coin extends ValueWithAddingTime {
  Coin(int initialCoin)
      : super(
          initialValue: initialCoin,
          completeAddingTime: 0.3,
          maxValue: Stage.maxCoin,
        );
}

class Stage {
  /// マスのサイズ
  static Vector2 get cellSize => Vector2(32.0, 32.0);

  /// プレイヤーの移動速度
  static const double playerSpeed = 96.0;

  /// 常に動くオブジェクトのアニメーションステップ時間
  static const double objectStepTime = 0.4;

  /// マージ可能なオブジェクトの拡大/縮小の時間(s)
  static const double mergableZoomDuration = 0.8;

  /// マージ可能なオブジェクトの拡大/縮小率
  static const double mergableZoomRate = 0.9;

  /// ボム爆発スプライトの拡大/縮小の時間(s)
  static const double bombZoomDuration = 0.2;

  /// ボム爆発スプライトの拡大/縮小率
  static const double bombZoomRate = 0.6;

  /// 静止物のzインデックス
  static const staticPriority = 1;

  /// 動かせる物のzインデックス（トラップなど）
  static const dynamicPriority = 2;

  /// 動く物のzインデックス（プレイヤー、敵など）
  static const movingPriority = 3;

  /// 動く物より前のzインデックス（スモーカーの煙など）
  static const frontMovingPriority = 4;

  /// 画面前面に表示する物（スコア加算表示等）のzインデックス
  static const frontPriority = 5;

  bool isReady = false;

  late StageObjFactory _objFactory;

  /// マージ時のエフェクト画像
  late Image mergeEffectImg;

  /// マージ一定数達成時オブジェクト出現のエフェクト画像
  late Image spawnEffectImg;

  /// コイン獲得時エフェクト用のコイン画像
  late Image coinImg;

  /// 静止物
  final Map<Point, StageObj> _staticObjs = {};

  // TODO: あまり美しくないのでできれば廃止する
  /// effectを追加する際、動きを合わせる基となるエフェクトを持つStageObj（不可視）
  List<StageObj> effectBase = [];

  /// 箱
  StageObjList boxes = StageObjList();

  /// 敵
  StageObjList enemies = StageObjList();

  /// ショップ
  List<StageObj> shops = [];

  /// ワープの場所リスト
  List<Point> warpPoints = [];

  /// コンベアの場所リスト
  List<Point> beltPoints = [];

  /// ブロック破壊時に出現した各アイテムの累計個数
  Map<StageObjTypeLevel, int> appearedItemsMap = {};

  /// Config().blockFloorMapおよびobjInBlockMapを元に計算したブロック破壊時出現オブジェクトの個数
  Map<PointRange, Distribution<StageObjTypeLevel>> objInBlockDistribution = {};

  /// Config().blockFloorMapを元に計算したブロック/床の個数と、座標の集合
  Map<PointRange, Distribution<StageObjTypeLevel>> blockFloorDistribution = {};

  /// マージした回数
  int mergedCount = 0;

  /// 次オブジェクトが出現するまでのマージ回数
  int remainMergeCount = 0;

  /// 次マージ時に出現するオブジェクト
  final List<StageObj> nextMergeItems = [];

  /// 各update()で更新する、マージによる効果(範囲と敵へのダメージ)
  final List<MergeAffect> mergeAffects = [];

  /// プレイヤー
  late Player player;

  bool _isGameover = false;

  /// ゲームオーバーになったかどうか
  bool get isGameover => _isGameover;
  set isGameover(bool b) {
    _isGameover = b;
    if (b) {
      // ※※ ダメージを受けた時はattackのアニメーションに変更する ※※
      player.attacking = true;
    }
  }

  /// ステージの左上座標(プレイヤーの動きにつれて拡張されていく)
  Point stageLT = Point(0, 0);

  /// ステージの右下座標(プレイヤーの動きにつれて拡張されていく)
  Point stageRB = Point(0, 0);

  /// ステージの左上上限座標
  Point stageMaxLT = Point(-100, -100);

  /// ステージの右下上限座標
  Point stageMaxRB = Point(100, 100);

  /// ステージの横幅
  int get stageWidth => stageRB.x - stageLT.x;

  /// ステージの縦幅
  int get stageHeight => stageRB.y - stageLT.y;

  /// スコアの最大値
  static int maxScore = 99999999;

  /// スコア
  Score score = Score(0);

  /// コイン数の最大値
  static int maxCoin = 999;

  /// 所持しているコイン
  Coin coins = Coin(0);

  /// テストモードかどうか
  final bool testMode;

  /// 【テストモード】出現床/ブロックの分布範囲表示
  List<Component> blockFloorMapView = [];

  /// 【テストモード】ブロック破壊時出現オブジェクトの分布範囲表示
  List<Component> objInBlockMapView = [];

  /// ゲームワールド
  final World gameWorld;

  /// 敵による攻撃の座標->攻撃のレベル
  final Map<Point, int> enemyAttackPoints = {};

  Stage({required this.testMode, required this.gameWorld}) {
    _objFactory = StageObjFactory();
  }

  Future<void> onLoad() async {
    await _objFactory.onLoad();
    mergeEffectImg = await Flame.images.load('merge_effect.png');
    spawnEffectImg = await Flame.images.load('spawn_effect.png');
    coinImg = await Flame.images.load('coin.png');
    isReady = true;
  }

  /// ステージオブジェクトを生成
  /// デフォルトではWorldにステージオブジェクトのSpriteAnimationComponentを追加する
  StageObj createObject({
    required StageObjTypeLevel typeLevel,
    required Point pos,
    Move vector = Move.down,
    bool addToGameWorld = true,
  }) {
    final ret = _objFactory.create(
        typeLevel: typeLevel, pos: pos, vector: vector, savedArg: 0);
    // ComponentをWorldに追加
    if (addToGameWorld) {
      gameWorld.add(ret.animationComponent);
    }
    return ret;
  }

  /// ステージオブジェクトをMapから生成
  /// デフォルトではWorldにステージオブジェクトのSpriteAnimationComponentを追加する
  StageObj createObjectFromMap(
    Map<String, dynamic> src, {
    bool addToGameWorld = true,
  }) {
    final ret = _objFactory.createFromMap(src);
    // ComponentをWorldに追加
    if (addToGameWorld) {
      gameWorld.add(ret.animationComponent);
    }
    return ret;
  }

  /// ステージを生成する
  void initialize(
      CameraComponent camera, Map<String, dynamic> stageData, bool t) {
    assert(isReady, 'Stage.onLoad() is not called!');
    isGameover = false;
    effectBase = [
      _objFactory.create(
          typeLevel: StageObjTypeLevel(type: StageObjType.jewel, level: 1),
          pos: Point(0, 0),
          savedArg: 0)
    ];
    effectBase.first.animationComponent.opacity = 0.0;
    gameWorld.add(effectBase.first.animationComponent);
    // 前回のステージ情報が保存されているなら
    if (stageData.containsKey('score')) {
      _setStageDataFromSaveData(camera, stageData);
    } else {
      _setStageDataFromInitialData(camera);
    }
    if (testMode) {
      // 【テストモード】各範囲の分布表示
      _createDistributionView();
    }
  }

  Future<Map<String, dynamic>> encodeStageData() async {
    final Map<String, dynamic> ret = {};
    ret['score'] = score.actual;
    ret['coin'] = coins.actual;
    ret['stageLT'] = stageLT.encode();
    ret['stageRB'] = stageRB.encode();
    final Map<String, dynamic> encodedCOIBM = {};
    for (final entry in objInBlockDistribution.entries) {
      encodedCOIBM[entry.key.toString()] = entry.value.encode();
    }
    ret['calcedObjInBlockMap'] = encodedCOIBM;
    final Map<String, dynamic> encodedCBFM = {};
    for (final entry in blockFloorDistribution.entries) {
      encodedCBFM[entry.key.toString()] = entry.value.encode();
    }
    ret['calcedBlockFloorMap'] = encodedCBFM;
    final Map<String, dynamic> staticObjsMap = {};
    for (final entry in _staticObjs.entries) {
      staticObjsMap[entry.key.encode()] = entry.value.encode();
    }
    ret['staticObjs'] = staticObjsMap;
    final List<Map<String, dynamic>> boxesList = [
      for (final e in boxes.iterable) e.encode()
    ];
    ret['boxes'] = boxesList;
    final List<Map<String, dynamic>> enemiesList = [
      for (final e in enemies.iterable) e.encode()
    ];
    ret['enemies'] = enemiesList;
    final List<String> warpPointsList = [
      for (final e in warpPoints) e.encode()
    ];
    ret['warpPoints'] = warpPointsList;
    final List<String> beltPointsList = [
      for (final e in beltPoints) e.encode()
    ];
    ret['beltPoints'] = beltPointsList;
    ret['player'] = player.encode();
    final List<Map<String, dynamic>> appearedItemsList = [
      for (final e in appearedItemsMap.keys) e.encode()
    ];
    ret['appearedItems'] = appearedItemsList;
    final List<int> appearedItemsCountList = appearedItemsMap.values.toList();
    ret['appearedItemsCounts'] = appearedItemsCountList;
    ret['remainMergeCount'] = remainMergeCount;
    ret['mergedCount'] = mergedCount;
    return ret;
  }

  /// 次のマージ時出現アイテムを更新
  void _updateNextMergeItem() {
    // 同じカウントで出現するアイテム群が複数設定されていたら、ランダムに選ぶ
    List<StageObjTypeLevel> tls =
        Config().mergeAppearObjMap.values.last.sample(1).first;
    bool existAppearObj = false;
    for (final entry in Config().mergeAppearObjMap.entries) {
      remainMergeCount = max(entry.key - mergedCount, 0);
      if (remainMergeCount > 0) {
        // 同じカウントで出現するアイテム群が複数設定されていたら、ランダムに選ぶ
        tls = entry.value.sample(1).first;
        existAppearObj = true;
        break;
      }
    }
    // コンフィグで設定した最後のエントリーなら、5回マージごとに出現するようにする(無限)
    if (!existAppearObj) {
      remainMergeCount = 5;
    }
    nextMergeItems.clear();
    for (final tl in tls) {
      nextMergeItems.add(createObject(
        typeLevel: tl,
        pos: Point(0, 0),
        addToGameWorld: false,
      ));
    }
  }

  /// ステージの範囲を拡大する
  void expandStageSize(Point newLT, Point newRB) {
    // 左端拡大
    for (int i = 0; i < stageLT.x - newLT.x; i++) {
      if (stageLT.x <= stageMaxLT.x) break;
      stageLT.x--;
      for (int y = stageLT.y; y <= stageRB.y; y++) {
        createAndSetStaticObjWithPattern(Point(stageLT.x, y));
      }
    }
    // 右端拡大
    for (int i = 0; i < newRB.x - stageRB.x; i++) {
      if (stageRB.x >= stageMaxRB.x) break;
      stageRB.x++;
      for (int y = stageLT.y; y <= stageRB.y; y++) {
        createAndSetStaticObjWithPattern(Point(stageRB.x, y));
      }
    }
    // 上端拡大
    for (int i = 0; i < stageLT.y - newLT.y; i++) {
      if (stageLT.y <= stageMaxLT.y) break;
      stageLT.y--;
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        createAndSetStaticObjWithPattern(Point(x, stageLT.y));
      }
    }
    // 下端拡大
    for (int i = 0; i < newRB.y - stageRB.y; i++) {
      if (stageRB.y >= stageMaxRB.y) break;
      stageRB.y++;
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        createAndSetStaticObjWithPattern(Point(x, stageRB.y));
      }
    }
  }

  /// コイン加算表示(0枚なら表示しない)
  void showGotCoinEffect(int coins, Point pos) {
    if (coins > 0 && Config().showGotCoinsOnEnemyPos) {
      final gotCoinsText = OpacityEffectTextComponent(
        text: "+$coins",
        textRenderer: TextPaint(
          style: Config.gameTextStyle,
        ),
      );
      gameWorld.add(RectangleComponent(
        priority: Stage.frontPriority,
        size: Vector2(32.0, 16.0),
        anchor: Anchor.center,
        position: Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 -
            Config().addedScoreEffectMove,
        paint: Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill,
        children: [
          RectangleComponent(
            paint: Paint()
              ..color = Colors.transparent
              ..style = PaintingStyle.fill,
          ),
          AlignComponent(
              alignment: Anchor.centerLeft,
              child:
                  SpriteComponent.fromImage(coinImg, scale: Vector2.all(0.5))),
          AlignComponent(
            alignment: Anchor.centerRight,
            child: gotCoinsText,
          ),
          SequenceEffect([
            MoveEffect.by(
                Config().addedScoreEffectMove,
                EffectController(
                  duration: 0.3,
                )),
            OpacityEffect.fadeOut(EffectController(duration: 0.5),
                target: gotCoinsText),
            RemoveEffect(),
          ]),
        ],
      ));
    }
  }

  /// オブジェクト出現エフェクト表示
  void showSpawnEffect(Point pos) {
    // 出現エフェクトを描画
    gameWorld.add(
      SpriteComponent(
        sprite: Sprite(spawnEffectImg),
        priority: Stage.dynamicPriority,
        scale: Vector2(0.8, 1.0),
        children: [
          ScaleEffect.by(
            Vector2(1.5, 1.0),
            EffectController(duration: 0.5),
          ),
          OpacityEffect.by(
            -1.0,
            EffectController(duration: 1.0),
          ),
          RemoveEffect(delay: 1.0),
        ],
        size: Stage.cellSize,
        anchor: Anchor.center,
        position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2),
      ),
    );
    // 効果音を鳴らす
    Audio().playSound(Sound.spawn);
  }

  /// 指定した範囲のブロックを破壊する
  void breakBlocks(Point basePoint, bool Function(Block) canBreakBlockFunc,
      PointRange range) async {
    // 指定された範囲のブロックを破壊する
    // 破壊後のブロックから出現するオブジェクトはbasePointの位置によって決定する
    /// 破壊されたブロックの位置のリスト
    final List<Point> breaked = [];
    final List<Component> breakingAnimations = [];

    for (final p in range.set) {
      //if (p == basePoint) continue;
      final gotTypeLevel =
          StageObjTypeLevel(type: get(p).type, level: get(p).level);
      if (gotTypeLevel.type == StageObjType.block &&
          canBreakBlockFunc(get(p) as Block)) {
        breakingAnimations.add((get(p) as Block).createBreakingBlock());
        // TODO: 敵が生み出したブロック（に限らず）破壊したブロックの種類によって出現するアイテムを分けれるように設定できるようにすべし
        if (gotTypeLevel.level < 100) {
          // 敵が生み出したブロック以外のみアイテム出現位置に含める
          breaked.add(p);
        }
        setStaticType(p, StageObjType.none);
        if (gotTypeLevel.level < 100 &&
            Config().setObjInBlockWithDistributionAlgorithm) {
          // 分布に従ってブロック破壊時出現オブジェクトを決める場合、
          // 破壊した対象のブロックが持つオブジェクトを分布から決定する
          final targetField = Config().getObjInBlockMapEntry(p).key;
          final item = objInBlockDistribution[targetField]!.getOne()?.copy();
          // 該当範囲内での出現個数制限を調べる
          final objMaxNumPattern = Config().getMaxObjNumFromBlock(p);
          bool isOver = objMaxNumPattern.containsKey(item) &&
              appearedItemsMap.containsKey(item) &&
              objMaxNumPattern[item]! <= appearedItemsMap[item]!;
          if (item != null && !isOver) {
            if (item.type == StageObjType.jewel) {
              // 宝石は位置によってレベルを変える
              item.level = Config().getJewelLevel(p);
            }
            if (item.type == StageObjType.treasureBox) {
              setStaticType(p, StageObjType.treasureBox);
            } else if (item.type == StageObjType.warp) {
              setStaticType(p, StageObjType.warp);
              warpPoints.add(p);
              // ワープの番号を設定
              (_staticObjs[p] as Warp).setWarpNo(warpPoints.length);
            } else if (item.type == StageObjType.belt) {
              setStaticType(p, StageObjType.belt);
              assert(get(p).runtimeType == Belt,
                  'Beltじゃない(=Beltの上に何か載ってる)、ありえない！');
              get(p).vector = MoveExtent.straights.sample(1).first;
              beltPoints.add(p);
            } else {
              final adding = createObject(typeLevel: item, pos: p);
              if (adding.isEnemy) {
                enemies.add(adding);
              } else {
                boxes.add(adding);
              }
            }
            // 出現したアイテムを記録
            if (appearedItemsMap.containsKey(item)) {
              appearedItemsMap[item] = appearedItemsMap[item]! + 1;
            } else {
              appearedItemsMap[item] = 1;
            }
          }
        }
      }
    }
    // 破壊したブロックのアニメーションを描画
    gameWorld.addAll(breakingAnimations);

    if (!Config().setObjInBlockWithDistributionAlgorithm) {
      // basePointを元に、どういうオブジェクトが出現するか決定
      ObjInBlock pattern = Config().getObjInBlockMapEntry(basePoint).value;
      int jewelLevel = Config().getJewelLevel(basePoint);

      /// 破壊されたブロック位置のうち、まだオブジェクトが出現していない位置のリスト
      final breakedRemain = [...breaked];

      // 宝石の出現について
      // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
      final jewelAppears =
          breaked.sample((breaked.length * pattern.jewelPercent / 100).ceil());
      breakedRemain.removeWhere((element) => jewelAppears.contains(element));
      for (final jewelAppear in jewelAppears) {
        boxes.add(
          createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.jewel,
                level: jewelLevel,
              ),
              pos: jewelAppear),
        );
      }

      // その他オブジェクトの出現について
      // 該当範囲内での出現個数制限を調べる
      List<StageObjTypeLevel> items = [];
      final objMaxNumPattern = Config().getMaxObjNumFromBlock(basePoint);
      for (final itemAndNum in pattern.itemsPercentAndNumsMap.entries) {
        // ブロック破壊で出現するオブジェクトそれぞれに対し、制限内の個数分だけitemsに加える
        int addingNum = itemAndNum.value.max;
        final item = itemAndNum.key;
        if (objMaxNumPattern.containsKey(item) &&
            appearedItemsMap.containsKey(item)) {
          addingNum =
              max(addingNum, objMaxNumPattern[item]! - appearedItemsMap[item]!);
        }
        items.addAll([for (int i = 0; i < addingNum; i++) item]);
      }
      if (items.isNotEmpty) {
        for (int i = 0; i < pattern.itemsMaxNum; i++) {
          // リストの中から出現させるアイテムを選ぶ
          StageObjTypeLevel item = items.sample(1).first;
          // 宝石出現以外の位置に最大1個アイテムを出現させる
          if (breakedRemain.isNotEmpty) {
            bool canAppear = Config().random.nextBool();
            final appear = breakedRemain.sample(1).first;
            if (canAppear) {
              if (item.type == StageObjType.treasureBox) {
                setStaticType(appear, StageObjType.treasureBox);
              } else if (item.type == StageObjType.warp) {
                setStaticType(appear, StageObjType.warp);
                warpPoints.add(appear);
                // ワープの番号を設定
                (_staticObjs[appear] as Warp).setWarpNo(warpPoints.length);
              } else if (item.type == StageObjType.belt) {
                setStaticType(appear, StageObjType.belt);
                assert(get(appear).runtimeType == Belt,
                    'Beltじゃない(=Beltの上に何か載ってる)、ありえない！');
                get(appear).vector = MoveExtent.straights.sample(1).first;
                beltPoints.add(appear);
              } else {
                final adding = createObject(typeLevel: item, pos: appear);
                if (adding.isEnemy) {
                  enemies.add(adding);
                } else {
                  boxes.add(adding);
                }
              }
              // アイテム出現場所を取り除く
              breakedRemain.remove(appear);
              // 出現したアイテムを記録
              if (appearedItemsMap.containsKey(item)) {
                appearedItemsMap[item] = appearedItemsMap[item]! + 1;
              } else {
                appearedItemsMap[item] = 1;
              }
            }
          }
        }
      }
    }
  }

  void merge(
    Point pos,
    StageObj merging,
    World gameWorld,
    MergeAffect mergeAffect, {
    bool onlyDelete = false,
    bool countMerge = true, // マージ数としてカウントするか
    bool addScore = true, // スコア加算するか
  }) {
    // update()の最後にブロック破壊＆敵へのダメージを処理する
    mergeAffects.add(
      mergeAffect,
    );

    if (countMerge) {
      // マージ回数およびオブジェクト出現までのマージ回数をインクリメント/デクリメント
      mergedCount++;
      remainMergeCount--;
    }

    if (addScore) {
      // スコア加算
      int gettingScore = pow(2, (merging.level - 1)).toInt() * 100;
      score.actual += gettingScore;

      // スコア加算表示
      if (gettingScore > 0 && Config().showAddedScoreOnMergePos) {
        final addingScoreText = OpacityEffectTextComponent(
          text: "+$gettingScore",
          textRenderer: TextPaint(
            style: Config.gameTextStyle,
          ),
        );
        gameWorld.add(RectangleComponent(
          priority: frontPriority,
          anchor: Anchor.center,
          position: Vector2(pos.x * cellSize.x, pos.y * cellSize.y) +
              cellSize / 2 -
              Config().addedScoreEffectMove,
          paint: Paint()
            ..color = Colors.transparent
            ..style = PaintingStyle.fill,
          children: [
            RectangleComponent(
              paint: Paint()
                ..color = Colors.transparent
                ..style = PaintingStyle.fill,
            ),
            AlignComponent(
              alignment: Anchor.center,
              child: addingScoreText,
            ),
            SequenceEffect([
              MoveEffect.by(
                  Config().addedScoreEffectMove,
                  EffectController(
                    duration: 0.3,
                  )),
              OpacityEffect.fadeOut(EffectController(duration: 0.5),
                  target: addingScoreText),
              RemoveEffect(),
            ]),
          ],
        ));
      }
    }

    if (onlyDelete) {
      // 対象オブジェクトを消す
      merging.remove();
    } else {
      // 当該位置のオブジェクトを消す
      final merged = boxes.firstWhere((element) => element.pos == pos);
      merged.remove();
      // 移動したオブジェクトのレベルを上げる
      merging.level++;
    }

    if (!onlyDelete) {
      // マージエフェクトを描画
      gameWorld.add(
        SpriteComponent(
          sprite: Sprite(mergeEffectImg),
          priority: Stage.dynamicPriority,
          scale: Vector2.all(0.8),
          children: [
            ScaleEffect.by(
              Vector2.all(1.5),
              EffectController(duration: 0.5),
            ),
            OpacityEffect.by(
              -1.0,
              EffectController(duration: 1.0),
            ),
            RemoveEffect(delay: 1.0),
          ],
          size: Stage.cellSize,
          anchor: Anchor.center,
          position:
              (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                  Stage.cellSize / 2),
        ),
      );
    }

    // 効果音を鳴らす
    Audio().playSound(Sound.merge);
  }

  /// マージ一定回数達成によってオブジェクトを出現させる
  void spawnMergeCountObject() {
    // ステージ上にアイテムをランダムに配置
    // ステージ中央から時計回りに渦巻き状に移動して床があればランダムでアイテム設置
    Point p = Point(0, 0);
    List<Point> decidedPoints = [];
    final maxMoveCount = max(stageWidth, stageHeight);
    // whileでいいが、念のため
    for (int moveCount = 1; moveCount < maxMoveCount; moveCount++) {
      // 特定方向に動いて、ランダムにアイテムを設置する処理
      void moveAndSet(Move m, int c) {
        for (int i = 0; i < c; i++) {
          p += m.point;
          if (get(p, detectPlayer: true).type == StageObjType.none &&
              Config().random.nextInt(maxMoveCount) < c) {
            decidedPoints.add(p.copy());
            if (decidedPoints.length >= nextMergeItems.length) break;
          }
        }
      }

      // 上に移動
      moveAndSet(Move.up, moveCount);
      if (decidedPoints.length >= nextMergeItems.length) break;
      // 右に移動
      moveAndSet(Move.right, moveCount);
      if (decidedPoints.length >= nextMergeItems.length) break;
      // 下に移動
      moveAndSet(Move.down, moveCount + 1);
      if (decidedPoints.length >= nextMergeItems.length) break;
      // 左に移動
      moveAndSet(Move.left, moveCount + 1);
      if (decidedPoints.length >= nextMergeItems.length) break;
    }
    for (int i = 0; i < decidedPoints.length; i++) {
      final nextMergeItem = nextMergeItems[i];
      final item = createObject(
          typeLevel: StageObjTypeLevel(
            type: nextMergeItem.type,
            level: nextMergeItem.level,
          ),
          pos: decidedPoints[i]);
      if (item.isEnemy) {
        enemies.add(item);
      } else {
        boxes.add(item);
      }
      // オブジェクト出現エフェクトを表示
      showSpawnEffect(decidedPoints[i]);
    }
  }

  StageObj get(Point p, {bool detectPlayer = false}) {
    if (detectPlayer && player.pos == p) {
      return player;
    }
    final box = boxes.firstWhereOrNull((element) => element.pos == p);
    final enemy = enemies.firstWhereOrNull((element) => element.pos == p);
    // TODO:ゴーストのためだけにこの条件ここに書いてていい？
    if (enemy != null &&
        !(enemy.type == StageObjType.ghost && (enemy as Ghost).ghosting)) {
      return enemy;
    } else if (box != null) {
      return box;
    } else {
      return safeGetStaticObj(p);
    }
  }

  /// 静的オブジェクトを取得する。まだ用意されていない場合は用意する
  StageObj safeGetStaticObj(Point pos) {
    assert(PointRectRange(stageMaxLT, stageMaxRB).contains(pos),
        '[getStaticObj()]ステージの範囲外の取得が試みられた');
    if (!PointRectRange(stageLT, stageRB).contains(pos)) {
      // 対象の座標が存在できるようにステージを拡大
      expandStageSize(
        Point(min(stageLT.x, pos.x), min(stageLT.y, pos.y)),
        Point(max(stageRB.x, pos.x), max(stageRB.y, pos.y)),
      );
    }
    return _staticObjs[pos]!;
  }

  /// プレイヤーが移動中にこの関数を呼び出したとき、
  /// プレイヤーや敵によって押された後の、引数に指定した座標のオブジェクトを取得する
  StageObj getAfterPush(Point p, {bool detectPlayer = false}) {
    final playerMoving = player.moving;
    if (player.moving != Move.none) {
      // プレイヤーの押し
      for (final pushing in player.pushings) {
        if (pushing.pos + playerMoving.point == p) {
          return pushing;
        }
      }
      // 敵の押し
      for (final enemy in enemies.where((e) => e.pushings.isNotEmpty)) {
        for (final pushing in enemy.pushings) {
          if (pushing.pos + enemy.moving.point == p) {
            return pushing;
          }
        }
      }
    }
    return get(p, detectPlayer: detectPlayer);
  }

  /// ワープ後の位置を取得する
  Point getWarpedPoint(Point srcPos, {bool reverse = false}) {
    if (warpPoints.length <= 1) {
      return srcPos.copy();
    }
    // 対象ワープポイントを探す
    int index = warpPoints.indexWhere((element) => element == srcPos);
    if (index < 0) {
      return srcPos.copy();
    }
    // リスト内で次のワープ位置を返す
    if (!reverse) {
      if (++index == warpPoints.length) {
        index = 0;
      }
    } else {
      if (--index < 0) {
        index = warpPoints.length - 1;
      }
    }
    return warpPoints[index].copy();
  }

  void setStaticType(Point p, StageObjType type, {int level = 1}) {
    gameWorld.remove(_staticObjs[p]!.animationComponent);
    _staticObjs[p] = createObject(
        typeLevel: StageObjTypeLevel(type: type, level: level), pos: p);
  }

  /// 敵による攻撃の座標を追加する（ターン終了後に一度に判定する）
  void addEnemyAttackDamage(int power, Set<Point> points) {
    for (final point in points) {
      if (enemyAttackPoints.containsKey(point)) {
        // 既に同じ座標に攻撃がされているなら
        if (Config().sumUpEnemyAttackDamage) {
          // 威力を合算する
          enemyAttackPoints[point] = enemyAttackPoints[point]! + power;
        } else {
          // 最大の威力に書き換える
          enemyAttackPoints[point] = max(enemyAttackPoints[point]!, power);
        }
      } else {
        enemyAttackPoints[point] = power;
      }
    }
  }

  /// オブジェクトの位置を設定
  void setObjectPosition(StageObj obj, {Vector2? offset}) =>
      _objFactory.setPosition(obj, offset: offset);

  void _setStageDataFromSaveData(
      CameraComponent camera, Map<String, dynamic> stageData) async {
    // ステージ範囲設定
    stageLT = Point.decode(stageData['stageLT']);
    stageRB = Point.decode(stageData['stageRB']);
    // スコア設定
    score = Score(stageData['score']);
    // コイン数設定
    coins = Coin(stageData['coin']);
    // 分布(数)設定
    blockFloorDistribution.clear();
    for (final entry
        in (stageData['calcedBlockFloorMap'] as Map<String, dynamic>).entries) {
      blockFloorDistribution[PointRange.fromStr(entry.key)] =
          Distribution.decode(entry.value, StageObjTypeLevel.fromStr);
    }
    objInBlockDistribution.clear();
    for (final entry
        in (stageData['calcedObjInBlockMap'] as Map<String, dynamic>).entries) {
      objInBlockDistribution[PointRange.fromStr(entry.key)] =
          Distribution.decode(entry.value, StageObjTypeLevel.fromStr);
    }

    // 各種ステージオブジェクト設定
    _staticObjs.clear();
    shops.clear();
    for (final entry
        in (stageData['staticObjs'] as Map<String, dynamic>).entries) {
      final staticObj = createObjectFromMap(entry.value);
      if (staticObj.type == StageObjType.shop) {
        shops.add(staticObj);
      }
      _staticObjs[Point.decode(entry.key)] = staticObj;
    }
    // gameWorldのchildrenをすべてremoveしてること前提
    boxes.forceClear();
    for (final e in stageData['boxes'] as List<dynamic>) {
      boxes.add(createObjectFromMap(e));
    }
    enemies.forceClear();
    for (final e in stageData['enemies'] as List<dynamic>) {
      enemies.add(createObjectFromMap(e));
    }
    warpPoints = [
      for (final e in stageData['warpPoints'] as List<dynamic>) Point.decode(e)
    ];
    for (int i = 0; i < warpPoints.length; i++) {
      // ワープの番号を設定
      (_staticObjs[warpPoints[i]] as Warp).setWarpNo(i + 1);
    }
    beltPoints = [
      for (final e in stageData['beltPoints'] as List<dynamic>) Point.decode(e)
    ];
    // ブロック破壊時に出現した各アイテムの累計個数設定
    final appearedItems = stageData['appearedItems'] as List<dynamic>;
    final appearedItemsCounts =
        stageData['appearedItemsCounts'] as List<dynamic>;
    assert(appearedItems.length == appearedItemsCounts.length,
        'ブロック破壊時出現アイテム個数の保存が正しく行われなかった。');
    appearedItemsMap.clear();
    for (int i = 0; i < appearedItems.length; i++) {
      appearedItemsMap[StageObjTypeLevel.decode(appearedItems[i])] =
          appearedItemsCounts[i];
    }
    // マージした回数
    mergedCount = stageData['mergedCount'];
    // マージした回数
    mergedCount = stageData['mergedCount'];
    // マージによる出現アイテム更新
    _updateNextMergeItem();
    // プレイヤー作成
    player = _objFactory.createPlayerFromMap(stageData['player']);
    gameWorld.addAll([player.animationComponent]);
    // カメラはプレイヤーに追従
    camera.follow(
      player.animationComponent,
      maxSpeed: cameraMaxSpeed,
    );
    // カメラの可動域設定
    camera.setBounds(
      Rectangle.fromPoints(
          Vector2(stageLT.x * cellSize.x, stageLT.y * cellSize.y),
          Vector2(stageRB.x * cellSize.x, stageRB.y * cellSize.y)),
    );
  }

  _setStageDataFromInitialData(CameraComponent camera) {
    // ステージ範囲設定
    stageLT = Point(-6, -20);
    stageRB = Point(6, 20);
    // スコア初期化
    score = Score(0);
    // コイン数初期化
    coins = Coin(0);
    // マージ数初期化
    mergedCount = 0;
    // ブロック破壊時出現アイテム個数初期化
    appearedItemsMap.clear();
    // 次マージ時に出現するアイテム初期化
    _updateNextMergeItem();
    // 各分布の初期化
    if (Config().setObjInBlockWithDistributionAlgorithm) {
      prepareDistributions();
    }
    _staticObjs.clear();
    shops.clear();
    boxes.forceClear();
    enemies.forceClear();
    for (int y = stageLT.y; y <= stageRB.y; y++) {
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        if (x == 0 && y == 0) {
          // プレイヤー初期位置、床
          _staticObjs[Point(x, y)] = createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y));
        } else if ((x == 0 && -2 <= y && y <= 2) ||
            (y == 0 && -2 <= x && x <= 2)) {
          // プレイヤー初期位置の上下左右2マス、宝石
          _staticObjs[Point(x, y)] = createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y));
          boxes.add(createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.jewel,
              ),
              pos: Point(x, y)));
        } else {
          // その他は定めたパターンに従う
          createAndSetStaticObjWithPattern(Point(x, y));
        }
      }
    }

    // プレイヤー作成
    player = _objFactory.createPlayer(
        pos: Point(0, 0), vector: Move.down, savedArg: 0);
    gameWorld.add(player.animationComponent);
    // カメラはプレイヤーに追従
    camera.follow(
      player.animationComponent,
      maxSpeed: cameraMaxSpeed,
    );
    // カメラの可動域設定
    camera.setBounds(
      Rectangle.fromPoints(
          Vector2(stageLT.x * cellSize.x, stageLT.y * cellSize.y),
          Vector2(stageRB.x * cellSize.x, stageRB.y * cellSize.y)),
    );
  }

  void update(
      double dt, Move moveInput, World gameWorld, CameraComponent camera) {
    // 表示上のスコア更新
    score.update(dt);
    // 表示上のコイン数更新
    coins.update(dt);
    // クリア済みなら何もしない
    if (isClear()) return;
    Move before = player.moving;
    final Map<Point, Move> prohibitedPoints = {};
    // プレイヤー更新
    player.update(
        dt, moveInput, gameWorld, camera, this, false, false, prohibitedPoints);
    bool playerStartMoving =
        (before == Move.none && player.moving != Move.none);
    bool playerEndMoving = (before != Move.none && player.moving == Move.none);
    // コンベア更新
    for (final belt in beltPoints) {
      _staticObjs[belt]!.update(dt, moveInput, gameWorld, camera, this,
          playerStartMoving, playerEndMoving, prohibitedPoints);
    }
    // プレイヤーの能力使用不可をすべて解除(この後の敵更新で煙によって使用不可にする)
    for (final ability in player.isAbilityForbidden.keys) {
      player.isAbilityForbidden[ability] = false;
    }
    // 敵更新
    final currentEnemies = [...enemies.iterable];
    for (final enemy in currentEnemies) {
      enemy.update(dt, player.moving, gameWorld, camera, this,
          playerStartMoving, playerEndMoving, prohibitedPoints);
    }
    if (playerStartMoving) {
      // 動き始めたらプレイヤーに再フォーカス
      camera.follow(
        player.animationComponent,
        maxSpeed: cameraMaxSpeed,
      );
    }
    {
      // 同じレベルの敵同士が同じ位置になったらマージしてレベルアップ
      final List<Point> mergingPosList = [];
      final List<StageObj> mergedEnemies = [];
      for (final enemy in enemies.iterable) {
        if (mergingPosList.contains(enemy.pos)) {
          continue;
        }
        if (!enemy.mergable) continue;
        final t = enemies.where((element) =>
            element != enemy &&
            element.pos == enemy.pos &&
            element.isSameTypeLevel(enemy));
        if (t.isNotEmpty) {
          mergingPosList.add(enemy.pos);
          mergedEnemies.add(enemy);
          // マージされた敵を削除
          enemy.remove();
          // レベルを上げる
          t.first.level++;
        }
      }
    }
    // オブジェクト更新(罠：敵を倒す、ガーディアン：周囲の敵を倒す)
    //// これらはプレイヤーの移動開始/完了時のみ動かす
    //if (playerStartMoving || playerEndMoving) {
    final currentBoxes = [...boxes.iterable];
    for (final box in currentBoxes) {
      box.update(dt, player.moving, gameWorld, camera, this, playerStartMoving,
          playerEndMoving, prohibitedPoints);
    }
    //}

    // プレイヤーがポケットに入れているオブジェクトも、対応しているなら更新
    if (player.pocketItem != null && player.pocketItem!.updateInPocket) {
      player.pocketItem!.update(dt, player.moving, gameWorld, camera, this,
          playerStartMoving, playerEndMoving, prohibitedPoints);
    }

    // ショップ更新(ショップ情報を吹き出しで表示/非表示)
    for (final shop in shops) {
      shop.update(dt, player.moving, gameWorld, camera, this, playerStartMoving,
          playerEndMoving, prohibitedPoints);
    }

    // 敵の攻撃について処理
    for (final attack in enemyAttackPoints.entries) {
      // プレイヤーに攻撃が当たった
      if (attack.key == player.pos) {
        isGameover = player.hit(attack.value);
      }
      // ガーディアンに攻撃が当たった
      for (final guardian in boxes.where((element) =>
          element.type == StageObjType.guardian && attack.key == element.pos)) {
        if (guardian.hit(attack.value)) {
          // ガーディアン側の処理が残っているかもしれないので、このフレームの最後に消す
          guardian.removeAfterFrame();
        }
      }
    }
    // 敵の攻撃情報をクリア
    enemyAttackPoints.clear();

    // マージによる敵へのダメージ処理
    for (final mergeAffect in mergeAffects) {
      if (mergeAffect.enemyDamage > 0) {
        for (final p in mergeAffect.range.set) {
          final obj = get(p);
          // hit()でレベルを下げる前にコイン数を取得
          int gettableCoins = obj.coins;
          if (obj.isEnemy && obj.hit(mergeAffect.enemyDamage)) {
            // 敵側の処理が残ってるかもしれないので、フレーム処理終了後に消す
            obj.removeAfterFrame();
            // コイン獲得
            coins.actual += gettableCoins;
            showGotCoinEffect(gettableCoins, obj.pos);
          }
        }
      }
    }

    // マージによってブロックを破壊する
    for (final mergeAffect in mergeAffects) {
      breakBlocks(
        mergeAffect.basePoint,
        mergeAffect.canBreakBlockFunc,
        mergeAffect.range,
      );
    }

    // マージによる影響をクリア
    mergeAffects.clear();

    // 一定のマージ回数達成によるオブジェクト出現
    if (remainMergeCount <= 0) {
      spawnMergeCountObject();
      // 次のマージ時出現アイテムを作成
      _updateNextMergeItem();
    }

    // 無効になったオブジェクト/敵を削除
    boxes.removeAllInvalidObjects(gameWorld);
    enemies.removeAllInvalidObjects(gameWorld);

    // 移動完了時
    if (playerEndMoving) {
      // 移動によって新たな座標が見えそうなら追加する
      Point newLT = stageLT.copy();
      Point newRB = stageRB.copy();
      // 左端
      if (camera.canSee(
          _staticObjs[Point(stageLT.x, player.pos.y)]!.animationComponent)) {
        newLT.x--;
      }
      // 右端
      if (camera.canSee(
          _staticObjs[Point(stageRB.x, player.pos.y)]!.animationComponent)) {
        newRB.x++;
      }
      // 上端
      if (camera.canSee(
          _staticObjs[Point(player.pos.x, stageLT.y)]!.animationComponent)) {
        newLT.y--;
      }
      // 下端
      if (camera.canSee(
          _staticObjs[Point(player.pos.x, stageRB.y)]!.animationComponent)) {
        newRB.y++;
      }
      if (newLT != stageLT || newRB != stageRB) {
        expandStageSize(newLT, newRB);
      }
      // カメラの可動範囲更新
      camera.setBounds(
        Rectangle.fromPoints(
            Vector2(stageLT.x * cellSize.x, stageLT.y * cellSize.y),
            Vector2(stageRB.x * cellSize.x, stageRB.y * cellSize.y)),
      );
    }
  }

  void prepareDistributions() {
    // 先に床/ブロックの分布
    blockFloorDistribution.clear();
    blockFloorDistribution.addAll(Config().blockFloorDistribution);
    for (final v in blockFloorDistribution.values) {
      v.reset();
    }
    // 続いてブロック破壊時出現オブジェクトの分布
    objInBlockDistribution.clear();
    objInBlockDistribution.addAll(Config().objInBlockDistribution);
    for (final v in objInBlockDistribution.values) {
      v.reset();
    }
  }

  // 【テストモード】範囲の表示を作成
  void _createDistributionView() {
    int colorIdx = -1;
    for (final entry in blockFloorDistribution.entries) {
      // 表示の色分け
      colorIdx = (++colorIdx) % Config.distributionMapColors.length;
      Color mapColor = Config.distributionMapColors[colorIdx];
      Set set = entry.key.set;
      for (final t in blockFloorDistribution.keys) {
        if (t == entry.key) break;
        set = set.difference(t.set);
      }
      blockFloorMapView.addAll([
        for (final p in set)
          RectangleComponent(
            priority: Stage.frontPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position: (Vector2(p.x * Stage.cellSize.x, p.y * Stage.cellSize.y) +
                Stage.cellSize / 2),
          )..paint = (Paint()
            ..color = mapColor
            ..style = PaintingStyle.fill)
      ]);
    }
    colorIdx = -1;
    for (final entry in objInBlockDistribution.entries) {
      colorIdx = (++colorIdx) % Config.distributionMapColors.length;
      Set set = entry.key.set;
      for (final t in objInBlockDistribution.keys) {
        if (t == entry.key) break;
        set = set.difference(t.set);
      }
      Color mapColor = Config.distributionMapColors[colorIdx];
      objInBlockMapView.addAll([
        for (final p in set)
          RectangleComponent(
            priority: Stage.frontPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position: (Vector2(p.x * Stage.cellSize.x, p.y * Stage.cellSize.y) +
                Stage.cellSize / 2),
          )..paint = (Paint()
            ..color = mapColor
            ..style = PaintingStyle.fill)
      ]);
    }
  }

  /// 引数で指定した位置に、パターンに従った静止物を生成する
  void createAndSetStaticObjWithPattern(Point pos,
      {bool addToGameWorld = true}) async {
    if (Config().fixedStaticObjMap.containsKey(pos)) {
      // 固定位置のオブジェクト
      final staticObj = createObject(
          typeLevel: Config().fixedStaticObjMap[pos]!,
          pos: pos,
          addToGameWorld: addToGameWorld);
      if (staticObj.type == StageObjType.shop) {
        shops.add(staticObj);
      }
      _staticObjs[pos] = staticObj;
      return;
    } else {
      // その他は定めたパターンに従う
      if (Config().setObjInBlockWithDistributionAlgorithm) {
        for (final pattern in blockFloorDistribution.entries) {
          if (pattern.key.contains(pos)) {
            _staticObjs[pos] = createObject(
                typeLevel: pattern.value.getOne() ??
                    StageObjTypeLevel(type: StageObjType.none),
                pos: pos,
                addToGameWorld: addToGameWorld);
            return;
          }
        }
        log('位置(${pos.x}, ${pos.y})に対応する床/ブロックの割合の設定がないため、硬いブロックを生成しました。');
        _staticObjs[pos] = createObject(
            typeLevel: StageObjTypeLevel(type: StageObjType.block, level: 4),
            pos: pos,
            addToGameWorld: addToGameWorld);
        return;
      } else {
        for (final pattern in Config().blockFloorMap.entries) {
          if (pattern.key.contains(pos)) {
            int rand = Config().random.nextInt(100);
            int threshold = 0;
            for (final floorPercent in pattern.value.floorPercents.entries) {
              threshold += floorPercent.value;
              if (rand < threshold) {
                _staticObjs[pos] = createObject(
                    typeLevel: floorPercent.key,
                    pos: pos,
                    addToGameWorld: addToGameWorld);
                return;
              }
            }
            for (final p in pattern.value.blockPercents.entries) {
              threshold += p.value;
              if (rand < threshold) {
                _staticObjs[pos] = createObject(
                    typeLevel: StageObjTypeLevel(
                      type: StageObjType.block,
                      level: p.key,
                    ),
                    pos: pos,
                    addToGameWorld: addToGameWorld);
                return;
              }
            }
            log('床/ブロックの割合の合計が100になっていないため、床を生成しました。\n割合の設定値：');
            for (final floorPercent in pattern.value.floorPercents.entries) {
              log('${floorPercent.key.type.str}: ${floorPercent.value}');
            }
            for (final blockPercent in pattern.value.blockPercents.entries) {
              log('Block level ${blockPercent.key}: ${blockPercent.value}');
            }
            _staticObjs[pos] = createObject(
                typeLevel: StageObjTypeLevel(type: StageObjType.none),
                pos: pos,
                addToGameWorld: addToGameWorld);
            return;
          }
        }
        log('位置(${pos.x}, ${pos.y})に対応する床/ブロックの割合の設定がないため、硬いブロックを生成しました。');
        _staticObjs[pos] = createObject(
            typeLevel: StageObjTypeLevel(type: StageObjType.block, level: 4),
            pos: pos,
            addToGameWorld: addToGameWorld);
        return;
      }
    }
  }

  void setHandAbility(bool isOn) {
    player.isAbilityAquired[PlayerAbility.hand] = isOn;
  }

  bool getHandAbility() {
    return player.pushableNum == -1;
  }

  void setLegAbility(bool isOn) {
    player.isAbilityAquired[PlayerAbility.leg] = isOn;
  }

  bool getLegAbility() {
    return player.isAbilityAvailable(PlayerAbility.leg);
  }

  bool getPocketAbility() {
    return player.isAbilityAvailable(PlayerAbility.pocket);
  }

  void usePocketAbility(World gameWorld) {
    player.usePocketAbility(this, gameWorld);
  }

  /// 現在のポケット能力で有しているオブジェクトの画像
  SpriteAnimation? getPocketAbilitySpriteAnimation() {
    if (!player.isAbilityAquired[PlayerAbility.pocket]! ||
        player.pocketItem == null) {
      return null;
    }
    return player.pocketItem!.animationComponent.animation;
  }

  void setArmerAbility(bool isOn) {
    player.isAbilityAquired[PlayerAbility.armer] = isOn;
  }

  bool getArmerAbility() {
    return player.isAbilityAvailable(PlayerAbility.armer);
  }

  int getArmerAbilityRecoveryTurns() {
    return player.armerRecoveryTurns;
  }

  /// 次マージ時に出現するオブジェクトの画像
  List<SpriteAnimation?> getNextMergeItemSpriteAnimations() {
    return [
      for (final nextMergeItem in nextMergeItems)
        nextMergeItem.animationComponent.animation
    ];
  }

  bool isClear() {
    return false;
  }

  double get cameraMaxSpeed {
    return max((stageRB - stageLT).x, (stageRB - stageLT).y) * 2 * cellSize.x;
  }
}
