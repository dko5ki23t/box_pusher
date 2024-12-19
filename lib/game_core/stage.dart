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

  /// 画面前面に表示する物（スコア加算表示等）のzインデックス
  static const frontPriority = 4;

  bool isReady = false;

  late StageObjFactory _objFactory;

  /// マージ時のエフェクト画像
  late Image mergeEffectImg;

  /// 静止物
  Map<Point, StageObj> staticObjs = {};

  // TODO: あまり美しくないのでできれば廃止する
  /// effectを追加する際、動きを合わせる基となるエフェクトを持つStageObj（不可視）
  List<StageObj> effectBase = [];

  /// 箱
  StageObjList boxes = StageObjList();

  /// 敵
  StageObjList enemies = StageObjList();

  /// ワープの場所リスト
  List<Point> warpPoints = [];

  /// コンベアの場所リスト
  List<Point> beltPoints = [];

  /// ブロック破壊時に出現した各アイテムの累計個数
  Map<StageObjTypeLevel, int> appearedItemsMap = {};

  /// Config().blockFloorMapおよびobjInBlockMapを元に計算したブロック破壊時出現オブジェクトの個数
  Map<PointRange, Distribution<StageObjTypeLevel>> calcedObjInBlockMap = {};

  /// Config().blockFloorMapを元に計算したブロック/床の個数
  Map<PointRange, Distribution<StageObjTypeLevel>> calcedBlockFloorMap = {};

  /// マージした回数
  int mergedCount = 0;

  /// 次オブジェクトが出現するまでのマージ回数
  int remainMergeCount = 0;

  /// 次マージ時に出現するオブジェクト
  final List<StageObj> nextMergeItems = [];

  /// プレイヤー
  late Player player;

  /// ゲームオーバーになったかどうか
  bool isGameover = false;

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

  /// スコア(加算途中の、表示上のスコア)
  double _scoreVisual = 0;

  /// スコア加算スピード(スコア/s)
  double _scorePlusSpeed = 0;

  /// スコア加算時間(s)
  final double _scorePlusTime = 0.3;

  /// コイン数の最大値
  static int maxCoinNum = 99;

  int _coinNum = 0;

  /// 所持しているコイン数
  set coinNum(int num) {
    _coinNum = num.clamp(0, maxCoinNum);
  }

  int get coinNum => _coinNum;

  /// スコアの最大値
  static int maxScore = 99999999;

  int _score = 0;

  /// スコア
  set score(int s) {
    _score = s.clamp(0, maxScore);
    _addedScore += (_score - _scoreVisual).round();
    _scorePlusSpeed = (_score - _scoreVisual) / _scorePlusTime;
  }

  int get score => _score;

  /// スコア(加算途中の、表示上のスコア)
  int get scoreVisual => _scoreVisual.round();

  /// 前回get呼び出し時から増えたスコア
  int _addedScore = 0;

  /// 前回get呼び出し時から増えたスコア
  int get addedScore {
    int ret = _addedScore;
    _addedScore = 0;
    return ret;
  }

  /// テストモードかどうか
  final bool testMode;

  Stage({required this.testMode}) {
    _objFactory = StageObjFactory();
  }

  Future<void> onLoad() async {
    await _objFactory.onLoad();
    mergeEffectImg = await Flame.images.load('merge_effect.png');
    isReady = true;
  }

  /// ステージオブジェクトを生成
  /// デフォルトではWorldにステージオブジェクトのSpriteAnimationComponentを追加する
  StageObj createObject({
    required StageObjTypeLevel typeLevel,
    required Point pos,
    required World gameWorld,
    Move vector = Move.down,
    bool addToGameWorld = true,
  }) {
    final ret =
        _objFactory.create(typeLevel: typeLevel, pos: pos, vector: vector);
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
    required World gameWorld,
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
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    assert(isReady, 'Stage.onLoad() is not called!');
    effectBase = [
      _objFactory.create(
          typeLevel: StageObjTypeLevel(type: StageObjType.jewel, level: 1),
          pos: Point(0, 0))
    ];
    effectBase.first.animationComponent.opacity = 0.0;
    gameWorld.add(effectBase.first.animationComponent);
    // 前回のステージ情報が保存されているなら
    if (stageData.containsKey('score')) {
      _setStageDataFromSaveData(gameWorld, camera, stageData);
    } else {
      _setStageDataFromInitialData(gameWorld, camera);
    }
  }

  Map<String, dynamic> encodeStageData() {
    final Map<String, dynamic> ret = {};
    ret['score'] = score;
    ret['coin'] = coinNum;
    ret['stageLT'] = stageLT.encode();
    ret['stageRB'] = stageRB.encode();
    final Map<String, dynamic> encodedCOIBM = {};
    for (final entry in calcedObjInBlockMap.entries) {
      encodedCOIBM[entry.key.toString()] = entry.value.encode();
    }
    ret['calcedObjInBlockMap'] = encodedCOIBM;
    final Map<String, dynamic> encodedCBFM = {};
    for (final entry in calcedBlockFloorMap.entries) {
      encodedCBFM[entry.key.toString()] = entry.value.encode();
    }
    ret['calcedBlockFloorMap'] = encodedCBFM;
    final Map<String, dynamic> staticObjsMap = {};
    for (final entry in staticObjs.entries) {
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
  void _updateNextMergeItem({required World gameWorld}) {
    List<StageObjTypeLevel> tls = Config().mergeAppearObjMap.values.last;
    bool existAppearObj = false;
    for (final entry in Config().mergeAppearObjMap.entries) {
      remainMergeCount = max(entry.key - mergedCount, 0);
      if (remainMergeCount > 0) {
        tls = entry.value;
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
        gameWorld: gameWorld,
        addToGameWorld: false,
      ));
    }
  }

  /// 指定した範囲のブロックを破壊する
  void breakBlocks(Point basePoint, bool Function(Block) canBreakBlockFunc,
      PointRange range, World gameWorld) {
    // 指定された範囲のブロックを破壊する
    // 破壊後のブロックから出現するオブジェクトはbasePointの位置によって決定する
    /// 破壊されたブロックの位置のリスト
    final List<Point> breaked = [];
    final List<Component> breakingAnimations = [];

    for (final p in range.set) {
      // ステージの範囲外
      if (!PointRectRange(stageLT, stageRB).contains(p)) {
        continue;
      }
      //if (p == basePoint) continue;
      if (get(p).type == StageObjType.block &&
          canBreakBlockFunc(get(p) as Block)) {
        breakingAnimations.add((get(p) as Block).createBreakingBlock());
        // TODO: 敵が生み出したブロック（に限らず）破壊したブロックの種類によって出現するアイテムを分けれるように設定できるようにすべし
        if (get(p).level < 100) {
          // 敵が生み出したブロック以外のみアイテム出現位置に含める
          breaked.add(p);
        }
        setStaticType(p, StageObjType.none, gameWorld);
        if (Config().setObjInBlockWithDistributionAlgorithm) {
          // 分布に従ってブロック破壊時出現オブジェクトを決める場合、
          // 破壊した対象のブロックが持つオブジェクトを分布から決定する
          final targetField = Config().getObjInBlockMapEntry(p).key;
          final item = calcedObjInBlockMap[targetField]!.getOne()?.copy();
          if (item != null) {
            if (item.type == StageObjType.jewel) {
              // 宝石は位置によってレベルを変える
              item.level = Config().getJewelLevel(p);
            }
            if (item.type == StageObjType.treasureBox) {
              setStaticType(p, StageObjType.treasureBox, gameWorld);
            } else if (item.type == StageObjType.warp) {
              setStaticType(p, StageObjType.warp, gameWorld);
              warpPoints.add(p);
            } else if (item.type == StageObjType.belt) {
              setStaticType(p, StageObjType.belt, gameWorld);
              assert(get(p).runtimeType == Belt,
                  'Beltじゃない(=Beltの上に何か載ってる)、ありえない！');
              get(p).vector = MoveExtent.straights.sample(1).first;
              beltPoints.add(p);
            } else {
              final adding =
                  createObject(typeLevel: item, pos: p, gameWorld: gameWorld);
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
              pos: jewelAppear,
              gameWorld: gameWorld),
        );
      }

      // その他オブジェクトの出現について
      // 該当範囲内での出現個数制限を調べる
      List<StageObjTypeLevel> items = [];
      final objMaxNumPattern = Config().getMaxObjNumFromBlock(basePoint);
      for (final itemAndNum in pattern.itemsNumMap.entries) {
        // ブロック破壊で出現するオブジェクトそれぞれに対し、制限内の個数分だけitemsに加える
        int addingNum = itemAndNum.value;
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
            bool canAppear = Random().nextBool();
            final appear = breakedRemain.sample(1).first;
            if (canAppear) {
              if (item.type == StageObjType.treasureBox) {
                setStaticType(appear, StageObjType.treasureBox, gameWorld);
              } else if (item.type == StageObjType.treasureBox) {
                setStaticType(appear, StageObjType.treasureBox, gameWorld);
                warpPoints.add(appear);
              } else if (item.type == StageObjType.belt) {
                setStaticType(appear, StageObjType.belt, gameWorld);
                assert(get(appear).runtimeType == Belt,
                    'Beltじゃない(=Beltの上に何か載ってる)、ありえない！');
                get(appear).vector = MoveExtent.straights.sample(1).first;
                beltPoints.add(appear);
              } else {
                final adding = createObject(
                    typeLevel: item, pos: appear, gameWorld: gameWorld);
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
    World gameWorld, {
    int breakLeftOffset = -1,
    int breakTopOffset = -1,
    int breakRightOffset = 1,
    int breakBottomOffset = 1,
    bool onlyDelete = false,
  }) {
    // マージ位置を中心に四角形範囲のブロックを破壊する
    breakBlocks(
      pos,
      (block) => Config.canBreakBlock(block, merging),
      PointRectRange(pos + Point(breakLeftOffset, breakTopOffset),
          pos + Point(breakRightOffset, breakBottomOffset)),
      gameWorld,
    );
    mergedCount++;
    // ステージ上にアイテムをランダムに配置
    if (remainMergeCount - 1 == 0) {
      // ステージ中央から時計回りに渦巻き状に移動して床があればランダムでアイテム設置
      Point p = Point(0, 0);
      List<Point> decidedPoints = [];
      final maxMoveCount = max(stageWidth, stageHeight);
      // whileでいいが、念のため
      for (int moveCount = 1; moveCount < maxMoveCount; moveCount++) {
        // 上に移動
        for (int i = 0; i < moveCount; i++) {
          p += Move.up.point;
          if (get(p).type == StageObjType.none &&
              Random().nextInt(maxMoveCount) < moveCount) {
            decidedPoints.add(p.copy());
            if (decidedPoints.length >= nextMergeItems.length) break;
          }
        }
        if (decidedPoints.length >= nextMergeItems.length) break;
        // 右に移動
        for (int i = 0; i < moveCount; i++) {
          p += Move.right.point;
          if (get(p).type == StageObjType.none &&
              Random().nextInt(maxMoveCount) < moveCount) {
            decidedPoints.add(p.copy());
            if (decidedPoints.length >= nextMergeItems.length) break;
          }
        }
        if (decidedPoints.length >= nextMergeItems.length) break;
        // 下に移動
        for (int i = 0; i < moveCount + 1; i++) {
          p += Move.down.point;
          if (get(p).type == StageObjType.none &&
              Random().nextInt(maxMoveCount) < moveCount) {
            decidedPoints.add(p.copy());
            if (decidedPoints.length >= nextMergeItems.length) break;
          }
        }
        if (decidedPoints.length >= nextMergeItems.length) break;
        // 左に移動
        for (int i = 0; i < moveCount + 1; i++) {
          p += Move.left.point;
          if (get(p).type == StageObjType.none &&
              Random().nextInt(maxMoveCount) < moveCount) {
            decidedPoints.add(p.copy());
            if (decidedPoints.length >= nextMergeItems.length) break;
          }
        }
        if (decidedPoints.length >= nextMergeItems.length) break;
      }
      for (int i = 0; i < decidedPoints.length; i++) {
        final nextMergeItem = nextMergeItems[i];
        final item = createObject(
            typeLevel: StageObjTypeLevel(
              type: nextMergeItem.type,
              level: nextMergeItem.level,
            ),
            pos: decidedPoints[i],
            gameWorld: gameWorld);
        if (item.isEnemy) {
          enemies.add(item);
        } else {
          boxes.add(item);
        }
      }
      // 次のマージ時出現アイテムを作成
      _updateNextMergeItem(gameWorld: gameWorld);
    } else {
      if (remainMergeCount > 0) remainMergeCount--;
    }

    // スコア加算
    int gettingScore = pow(2, (merging.level - 1)).toInt() * 100;
    score += gettingScore;

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
        position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2),
      ),
    );

    // 効果音を鳴らす
    Audio.playSound(Sound.merge);
  }

  StageObj get(Point p) {
    final box = boxes.firstWhereOrNull((element) => element.pos == p);
    final enemy = enemies.firstWhereOrNull((element) => element.pos == p);
    // TODO:ゴーストのためだけにこの条件ここに書いてていい？
    if (enemy != null &&
        !(enemy.type == StageObjType.ghost && (enemy as Ghost).ghosting)) {
      return enemy;
    } else if (box != null) {
      return box;
    } else {
      return staticObjs[p]!;
    }
  }

  void setStaticType(Point p, StageObjType type, World gameWorld,
      {int level = 1}) {
    gameWorld.remove(staticObjs[p]!.animationComponent);
    staticObjs[p] = createObject(
        typeLevel: StageObjTypeLevel(type: type, level: level),
        pos: p,
        gameWorld: gameWorld);
  }

  /// オブジェクトの位置を設定
  void setObjectPosition(StageObj obj, {Vector2? offset}) =>
      _objFactory.setPosition(obj, offset: offset);

  void _setStageDataFromSaveData(
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    // ステージ範囲設定
    stageLT = Point.decode(stageData['stageLT']);
    stageRB = Point.decode(stageData['stageRB']);
    // スコア設定
    _score = stageData['score'];
    _scoreVisual = _score.toDouble();
    // コイン数設定
    coinNum = stageData['coin'];
    // 分布(数)設定
    calcedBlockFloorMap.clear();
    for (final entry
        in (stageData['calcedBlockFloorMap'] as Map<String, dynamic>).entries) {
      calcedBlockFloorMap[PointRange.fromStr(entry.key)] =
          Distribution.decode(entry.value, StageObjTypeLevel.fromStr);
    }
    calcedObjInBlockMap.clear();
    for (final entry
        in (stageData['calcedObjInBlockMap'] as Map<String, dynamic>).entries) {
      calcedObjInBlockMap[PointRange.fromStr(entry.key)] =
          Distribution.decode(entry.value, StageObjTypeLevel.fromStr);
    }

    // 各種ステージオブジェクト設定
    staticObjs.clear();
    for (final entry
        in (stageData['staticObjs'] as Map<String, dynamic>).entries) {
      staticObjs[Point.decode(entry.key)] =
          createObjectFromMap(entry.value, gameWorld: gameWorld);
    }
    for (final e in stageData['boxes'] as List<dynamic>) {
      boxes.add(createObjectFromMap(e, gameWorld: gameWorld));
    }
    for (final e in stageData['enemies'] as List<dynamic>) {
      enemies.add(createObjectFromMap(e, gameWorld: gameWorld));
    }
    warpPoints = [
      for (final e in stageData['warpPoints'] as List<dynamic>) Point.decode(e)
    ];
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
    _updateNextMergeItem(gameWorld: gameWorld);
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

  void _setStageDataFromInitialData(World gameWorld, CameraComponent camera) {
    // ステージ範囲設定
    stageLT = Point(-6, -20);
    stageRB = Point(6, 20);
    // スコア初期化
    _score = 0;
    _scoreVisual = 0;
    // マージ数初期化
    mergedCount = 0;
    // ブロック破壊時出現アイテム個数初期化
    appearedItemsMap.clear();
    // 次マージ時に出現するアイテム初期化
    _updateNextMergeItem(gameWorld: gameWorld);
    // 各分布の初期化
    if (Config().setObjInBlockWithDistributionAlgorithm) {
      prepareDistributions();
    }
    staticObjs.clear();
    boxes.forceClear();
    enemies.forceClear();
    for (int y = stageLT.y; y <= stageRB.y; y++) {
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        if (x == 0 && y == 0) {
          // プレイヤー初期位置、床
          staticObjs[Point(x, y)] = createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y),
              gameWorld: gameWorld);
        } else if ((x == 0 && -2 <= y && y <= 2) ||
            (y == 0 && -2 <= x && x <= 2)) {
          // プレイヤー初期位置の上下左右2マス、宝石
          staticObjs[Point(x, y)] = createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y),
              gameWorld: gameWorld);
          boxes.add(createObject(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.jewel,
              ),
              pos: Point(x, y),
              gameWorld: gameWorld));
        } else {
          // その他は定めたパターンに従う
          createAndSetStaticObjWithPattern(Point(x, y), gameWorld);
        }
      }
    }

    // プレイヤー作成
    player = _objFactory.createPlayer(pos: Point(0, 0), vector: Move.down);
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
    // 見かけ上のスコア更新
    _scoreVisual += _scorePlusSpeed * dt;
    if (_scoreVisual > _score) {
      _scoreVisual = _score.toDouble();
    }
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
      staticObjs[belt]!.update(dt, moveInput, gameWorld, camera, this,
          playerStartMoving, playerEndMoving, prohibitedPoints);
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
    // これらはプレイヤーの移動開始/完了時のみ動かす
    if (playerStartMoving || playerEndMoving) {
      final currentBoxes = [...boxes.iterable];
      for (final box in currentBoxes) {
        box.update(dt, player.moving, gameWorld, camera, this,
            playerStartMoving, playerEndMoving, prohibitedPoints);
      }
    }

    // 無効になったオブジェクト/敵を削除
    boxes.removeAllInvalidObjects(gameWorld);
    enemies.removeAllInvalidObjects(gameWorld);

    // 移動完了時
    if (playerEndMoving) {
      // 移動によって新たな座標が見えそうなら追加する
      // 左端
      if (camera.canSee(
          staticObjs[Point(stageLT.x, player.pos.y)]!.animationComponent)) {
        // ステージ上限範囲を超えないように
        if (stageLT.x > stageMaxLT.x) {
          stageLT.x--;
          for (int y = stageLT.y; y <= stageRB.y; y++) {
            createAndSetStaticObjWithPattern(Point(stageLT.x, y), gameWorld);
          }
        }
      }
      // 右端
      if (camera.canSee(
          staticObjs[Point(stageRB.x, player.pos.y)]!.animationComponent)) {
        // ステージ上限範囲を超えないように
        if (stageRB.x < stageMaxRB.x) {
          stageRB.x++;
          for (int y = stageLT.y; y <= stageRB.y; y++) {
            createAndSetStaticObjWithPattern(Point(stageRB.x, y), gameWorld);
          }
        }
      }
      // 上端
      if (camera.canSee(
          staticObjs[Point(player.pos.x, stageLT.y)]!.animationComponent)) {
        // ステージ上限範囲を超えないように
        if (stageLT.y > stageMaxLT.y) {
          stageLT.y--;
          for (int x = stageLT.x; x <= stageRB.x; x++) {
            createAndSetStaticObjWithPattern(Point(x, stageLT.y), gameWorld);
          }
        }
      }
      // 下端
      if (camera.canSee(
          staticObjs[Point(player.pos.x, stageRB.y)]!.animationComponent)) {
        // ステージ上限範囲を超えないように
        if (stageRB.y < stageMaxRB.y) {
          stageRB.y++;
          for (int x = stageLT.x; x <= stageRB.x; x++) {
            createAndSetStaticObjWithPattern(Point(x, stageRB.y), gameWorld);
          }
        }
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
    // TODO: コンフィグでものすごく広い範囲指定してると激重になるのどうするか
    // 先に床/ブロックの分布
    for (final entry in Config().blockFloorMap.entries) {
      if (!calcedBlockFloorMap.containsKey(entry.key)) {
        final Map<StageObjTypeLevel, int> percents = {
          for (final e in entry.value.floorPercents.entries) e.key: e.value,
          for (final e in entry.value.blockPercents.entries)
            StageObjTypeLevel(type: StageObjType.block, level: e.key): e.value
        };
        Set set = entry.key.set;
        for (final t in calcedBlockFloorMap.keys) {
          if (t == entry.key) break;
          set = set.difference(t.set);
        }
        calcedBlockFloorMap[entry.key] = Distribution.fromPercent(
            percents, set.length, RoundMode.randomRound);
      }
    }
    // 続いてブロック破壊時出現オブジェクトの分布
    for (final entry in Config().objInBlockMap.entries) {
      if (!calcedObjInBlockMap.containsKey(entry.key)) {
        final targetField = entry.key;
        final targetOIB = entry.value;
        // 対象範囲にブロックがどれだけ含まれるか数える
        int blockNum = 0;
        for (final e in calcedBlockFloorMap.entries) {
          double ratio =
              targetField.set.intersection(e.key.set).length / e.key.set.length;
          // TODO: ブロックの種類増えたら困る
          blockNum += randomRound((e.value.getTotalNum(
                      StageObjTypeLevel(type: StageObjType.block, level: 1)) +
                  e.value.getTotalNum(
                      StageObjTypeLevel(type: StageObjType.block, level: 2)) +
                  e.value.getTotalNum(
                      StageObjTypeLevel(type: StageObjType.block, level: 3)) +
                  e.value.getTotalNum(
                      StageObjTypeLevel(type: StageObjType.block, level: 4))) *
              ratio);
        }
        final percents = {
          StageObjTypeLevel(type: StageObjType.jewel): targetOIB.jewelPercent
        };
        percents.addAll(targetOIB.itemsPercentMap);
        calcedObjInBlockMap[targetField] =
            Distribution.fromPercent(percents, blockNum, RoundMode.randomRound);
      }
    }
  }

  /// 引数で指定した位置に、パターンに従った静止物を生成する
  void createAndSetStaticObjWithPattern(Point pos, World gameWorld,
      {bool addToGameWorld = true}) {
    if (Config().fixedStaticObjMap.containsKey(pos)) {
      // 固定位置のオブジェクト
      staticObjs[pos] = createObject(
          typeLevel: Config().fixedStaticObjMap[pos]!,
          pos: pos,
          gameWorld: gameWorld,
          addToGameWorld: addToGameWorld);
      return;
    } else {
      // その他は定めたパターンに従う
      if (Config().setObjInBlockWithDistributionAlgorithm) {
        for (final pattern in Config().blockFloorMap.entries) {
          if (pattern.key.contains(pos)) {
            staticObjs[pos] = createObject(
                typeLevel: calcedBlockFloorMap[pattern.key]!.getOne() ??
                    StageObjTypeLevel(type: StageObjType.none),
                pos: pos,
                gameWorld: gameWorld,
                addToGameWorld: addToGameWorld);
            return;
          }
        }
        log('位置(${pos.x}, ${pos.y})に対応する床/ブロックの割合の設定がないため、硬いブロックを生成しました。');
        staticObjs[pos] = createObject(
            typeLevel: StageObjTypeLevel(type: StageObjType.block, level: 4),
            pos: pos,
            gameWorld: gameWorld,
            addToGameWorld: addToGameWorld);
        return;
      } else {
        for (final pattern in Config().blockFloorMap.entries) {
          if (pattern.key.contains(pos)) {
            int rand = Random().nextInt(100);
            int threshold = 0;
            for (final floorPercent in pattern.value.floorPercents.entries) {
              threshold += floorPercent.value;
              if (rand < threshold) {
                staticObjs[pos] = createObject(
                    typeLevel: floorPercent.key,
                    pos: pos,
                    gameWorld: gameWorld,
                    addToGameWorld: addToGameWorld);
                return;
              }
            }
            for (final p in pattern.value.blockPercents.entries) {
              threshold += p.value;
              if (rand < threshold) {
                staticObjs[pos] = createObject(
                    typeLevel: StageObjTypeLevel(
                      type: StageObjType.block,
                      level: p.key,
                    ),
                    pos: pos,
                    gameWorld: gameWorld,
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
            staticObjs[pos] = createObject(
                typeLevel: StageObjTypeLevel(type: StageObjType.none),
                pos: pos,
                gameWorld: gameWorld,
                addToGameWorld: addToGameWorld);
            return;
          }
        }
        log('位置(${pos.x}, ${pos.y})に対応する床/ブロックの割合の設定がないため、硬いブロックを生成しました。');
        staticObjs[pos] = createObject(
            typeLevel: StageObjTypeLevel(type: StageObjType.block, level: 4),
            pos: pos,
            gameWorld: gameWorld,
            addToGameWorld: addToGameWorld);
        return;
      }
    }
  }

  void setHandAbility(bool isOn) {
    if (isOn) {
      player.pushableNum = -1;
    } else {
      player.pushableNum = 1;
    }
  }

  bool getHandAbility() {
    return player.pushableNum == -1;
  }

  void setLegAbility(bool isOn) {
    player.isLegAbilityOn = isOn;
  }

  bool getLegAbility() {
    return player.isLegAbilityOn;
  }

  bool getPocketAbility() {
    return player.isPocketAbilityOn;
  }

  void usePocketAbility(World gameWorld) {
    player.usePocketAbility(this, gameWorld);
  }

  /// 現在のポケット能力で有しているオブジェクトの画像
  SpriteAnimation? getPocketAbilitySpriteAnimation() {
    if (!player.isPocketAbilityOn || player.pocketItem == null) {
      return null;
    }
    return player.pocketItem!.animationComponent.animation;
  }

  void setArmerAbility(bool isOn) {
    player.isArmerAbilityOn = isOn;
  }

  bool getArmerAbility() {
    return player.isArmerAbilityOn;
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
