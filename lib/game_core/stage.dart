import 'dart:math';

import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
import 'package:box_pusher/game_core/stage_objs/box.dart';
import 'package:box_pusher/game_core/stage_objs/drill.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/guardian.dart';
import 'package:box_pusher/game_core/stage_objs/magma.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/swordsman.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/treasure_box.dart';
import 'package:box_pusher/game_core/stage_objs/wall.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:box_pusher/game_core/stage_objs/water.dart';
import 'package:box_pusher/game_core/stage_objs/wizard.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

class StageObjFactory {
  final Map<StageObjType, SpriteAnimation> stageSpriteAnimatinos;
  final SpriteAnimation breakingBlockAnimation;
  final SpriteAnimation explodingBombAnimation;
  final SpriteAnimation swordsmanLeftAnimation;
  final SpriteAnimation swordsmanRightAnimation;
  final SpriteAnimation swordsmanUpAnimation;
  final SpriteAnimation swordsmanDownAnimation;
  final SpriteAnimation swordsmanLeftAttackAnimation;
  final SpriteAnimation swordsmanRightAttackAnimation;
  final SpriteAnimation swordsmanUpAttackAnimation;
  final SpriteAnimation swordsmanDownAttackAnimation;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラ
  EffectController? baseMergable;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラが逆再生中かどうか
  bool isBaseMergableReverse = false;

  void setReverse() {
    isBaseMergableReverse = !isBaseMergableReverse;
  }

  StageObjFactory({
    required this.stageSpriteAnimatinos,
    required this.breakingBlockAnimation,
    required this.explodingBombAnimation,
    required this.swordsmanLeftAnimation,
    required this.swordsmanRightAnimation,
    required this.swordsmanUpAnimation,
    required this.swordsmanDownAnimation,
    required this.swordsmanLeftAttackAnimation,
    required this.swordsmanRightAttackAnimation,
    required this.swordsmanUpAttackAnimation,
    required this.swordsmanDownAttackAnimation,
  });

  StageObj create({required StageObjTypeLevel typeLevel, required Point pos}) {
    int priority = Stage.staticPriority;
    // TODO: mergableとかで判定
    double angle = 0;
    Move beltV = Move.up;
    switch (typeLevel.type) {
      case StageObjType.box:
      case StageObjType.trap:
      case StageObjType.drill:
      case StageObjType.player:
      case StageObjType.spike:
      case StageObjType.bomb:
      case StageObjType.guardian:
      case StageObjType.swordsman:
      case StageObjType.archer:
      case StageObjType.wizard:
        priority = Stage.dynamicPriority;
        break;
      case StageObjType.none:
      case StageObjType.wall:
      case StageObjType.treasureBox:
      case StageObjType.warp:
      case StageObjType.beltU:
      case StageObjType.water:
      case StageObjType.magma:
        priority = Stage.staticPriority;
        break;
      case StageObjType.beltL:
        priority = Stage.staticPriority;
        beltV = Move.left;
        angle = -0.5 * pi;
        break;
      case StageObjType.beltR:
        priority = Stage.staticPriority;
        beltV = Move.right;
        angle = 0.5 * pi;
        break;
      case StageObjType.beltD:
        priority = Stage.staticPriority;
        beltV = Move.down;
        angle = pi;
        break;
    }

    final animation = SpriteAnimationComponent(
      animation: stageSpriteAnimatinos[typeLevel.type],
      priority: priority,
      // TODO: mergableとかで判定
      scale: (typeLevel.type == StageObjType.box ||
                  typeLevel.type == StageObjType.trap ||
                  typeLevel.type == StageObjType.drill ||
                  typeLevel.type == StageObjType.bomb ||
                  typeLevel.type == StageObjType.guardian) &&
              isBaseMergableReverse
          ? Vector2.all(Stage.mergableZoomRate)
          : Vector2.all(1.0),
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: TextComponent(
            text: typeLevel.level > 1 ? typeLevel.level.toString() : '',
            textRenderer: TextPaint(
              style: const TextStyle(
                fontFamily: 'Aboreto',
                color: Color(0xff000000),
              ),
            ),
          ),
        ),
        if (typeLevel.type == StageObjType.box ||
            typeLevel.type == StageObjType.trap ||
            typeLevel.type == StageObjType.drill ||
            typeLevel.type == StageObjType.bomb ||
            typeLevel.type == StageObjType.guardian)
          ScaleEffect.by(
            isBaseMergableReverse
                ? Vector2.all(1.0 / Stage.mergableZoomRate)
                : Vector2.all(Stage.mergableZoomRate),
            EffectController(
              onMax: baseMergable == null ? setReverse : null,
              onMin: baseMergable == null ? setReverse : null,
              duration: Stage.mergableZoomDuration,
              reverseDuration: Stage.mergableZoomDuration,
              infinite: true,
            ),
          ),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      angle: angle,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
    if (typeLevel.type == StageObjType.box ||
        typeLevel.type == StageObjType.trap ||
        typeLevel.type == StageObjType.drill ||
        typeLevel.type == StageObjType.bomb ||
        typeLevel.type == StageObjType.guardian) {
      final controller = (animation.children.last as Effect).controller;
      baseMergable ??= controller;
      controller.advance((isBaseMergableReverse
              ? (1.0 - baseMergable!.progress)
              : baseMergable!.progress) *
          Stage.mergableZoomDuration);
    }

    switch (typeLevel.type) {
      case StageObjType.none:
        return Floor(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.box:
        return Box(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.trap:
        return Trap(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.player:
        return Player(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.wall:
        return Wall(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.spike:
        return Spike(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.drill:
        return Drill(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.treasureBox:
        return TreasureBox(
            animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.warp:
        return Warp(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.bomb:
        return Bomb(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.beltL:
      case StageObjType.beltR:
      case StageObjType.beltU:
      case StageObjType.beltD:
        return Belt(
            animation: animation,
            pos: pos,
            level: typeLevel.level,
            vector: beltV);
      case StageObjType.guardian:
        return Guardian(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.water:
        return Water(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.magma:
        return Magma(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.swordsman:
        return Swordsman(
          animation: animation,
          leftAnimation: swordsmanLeftAnimation,
          rightAnimation: swordsmanRightAnimation,
          upAnimation: swordsmanUpAnimation,
          downAnimation: swordsmanDownAnimation,
          leftAttackAnimation: swordsmanLeftAttackAnimation,
          rightAttackAnimation: swordsmanRightAttackAnimation,
          upAttackAnimation: swordsmanUpAttackAnimation,
          downAttackAnimation: swordsmanDownAttackAnimation,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.archer:
        return Archer(animation: animation, pos: pos, level: typeLevel.level);
      case StageObjType.wizard:
        return Wizard(animation: animation, pos: pos, level: typeLevel.level);
    }
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
        typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
        pos: Point.decode(src['pos']));
  }

  SpriteAnimationComponent createBreakingBlock(Point pos) {
    return SpriteAnimationComponent(
      animation: breakingBlockAnimation,
      priority: Stage.dynamicPriority,
      children: [
        OpacityEffect.by(
          -1.0,
          EffectController(duration: 0.5),
        ),
        RemoveEffect(delay: 1.0),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
  }

  SpriteAnimationComponent createExplodingBomb(Point pos) {
    return SpriteAnimationComponent(
      animation: explodingBombAnimation,
      priority: Stage.dynamicPriority,
      children: [
        OpacityEffect.by(
          -1.0,
          EffectController(duration: 0.8),
        ),
        ScaleEffect.by(
          Vector2.all(Stage.bombZoomRate),
          EffectController(
            duration: Stage.bombZoomDuration,
            reverseDuration: Stage.bombZoomDuration,
            infinite: true,
          ),
        ),
        RemoveEffect(delay: 1.0),
      ],
      size: Stage.cellSize,
      anchor: Anchor.center,
      position: (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize / 2),
    );
  }

  SpriteAnimation getSpriteAnimation(StageObjType type) =>
      stageSpriteAnimatinos[type]!;

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.animation.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }
}

class Stage {
  /// マスのサイズ
  static Vector2 get cellSize => Vector2(32.0, 32.0);

  /// プレイヤーの移動速度
  static const double playerSpeed = 96.0;

  /// 常に動くオブジェクトのアニメーションステップ時間
  static const double objectStepTime = 0.4;

  static const double swordsmanAttackStepTime = 32.0 / playerSpeed / 5;

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

  /// 動く物のzインデックス
  static const dynamicPriority = 2;

  final Image stageImg;
  final Image playerImg;
  final Image spikeImg;
  final Image blockImg;
  final Image bombImg;
  final Image beltImg;
  final Image swordsmanImg;
  final Image swordsmanAttackDImg;
  final Image swordsmanAttackUImg;
  final Image swordsmanAttackLImg;
  final Image swordsmanAttackRImg;

  late StageObjFactory objFactory;

  /// 静止物
  Map<Point, StageObj> staticObjs = {};

  // TODO: あまり美しくないのでできれば廃止する
  /// effectを追加する際、動きを合わせる基となるエフェクトを持つStageObj（不可視）
  List<StageObj> effectBase = [];

  /// 箱
  List<StageObj> boxes = [];

  /// 敵
  List<StageObj> enemies = [];

  /// ワープの場所リスト
  List<Point> warpPoints = [];

  /// コンベアの場所リスト
  List<Point> beltPoints = [];

  /// プレイヤー
  late Player player;

  /// ゲームオーバーになったかどうか
  bool isGameover = false;

  /// ステージの左上座標(プレイヤーの動きにつれて拡張されていく)
  Point stageLT = Point(0, 0);

  /// ステージの右下座標(プレイヤーの動きにつれて拡張されていく)
  Point stageRB = Point(0, 0);

  /// スコア
  int _score = 0;

  /// スコア(加算途中の、表示上のスコア)
  double _scoreVisual = 0;

  /// スコア加算スピード(スコア/s)
  double _scorePlusSpeed = 0;

  /// スコア加算時間(s)
  final double _scorePlusTime = 0.3;

  set score(int s) {
    _score = s;
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

  /// 所持しているコイン数
  int coinNum = 0;

  Stage({
    required this.stageImg,
    required this.playerImg,
    required this.spikeImg,
    required this.blockImg,
    required this.bombImg,
    required this.beltImg,
    required this.swordsmanImg,
    required this.swordsmanAttackDImg,
    required this.swordsmanAttackUImg,
    required this.swordsmanAttackLImg,
    required this.swordsmanAttackRImg,
  }) {
    final Map<StageObjType, SpriteAnimation> stageSprites = {};
    stageSprites[StageObjType.none] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(0, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.wall] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(160, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.trap] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(32, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.box] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(96, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.player] = SpriteAnimation.fromFrameData(
      playerImg,
      SpriteAnimationData.sequenced(
          amount: 2, stepTime: objectStepTime, textureSize: cellSize),
    );
    stageSprites[StageObjType.spike] = SpriteAnimation.fromFrameData(
      spikeImg,
      SpriteAnimationData.sequenced(
          amount: 2, stepTime: objectStepTime, textureSize: cellSize),
    );
    stageSprites[StageObjType.drill] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(224, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.treasureBox] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(416, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.warp] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(480, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.bomb] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(512, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.beltL] = stageSprites[StageObjType.beltR] =
        stageSprites[StageObjType.beltU] =
            stageSprites[StageObjType.beltD] = SpriteAnimation.fromFrameData(
      beltImg,
      SpriteAnimationData.sequenced(
          amount: 4, stepTime: objectStepTime, textureSize: cellSize),
    );
    stageSprites[StageObjType.guardian] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(576, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.water] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(608, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.magma] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(640, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.swordsman] = SpriteAnimation.spriteList([
      Sprite(swordsmanImg, srcPosition: Vector2(0, 0), srcSize: cellSize),
      Sprite(swordsmanImg, srcPosition: Vector2(32, 0), srcSize: cellSize),
    ], stepTime: objectStepTime);
    stageSprites[StageObjType.archer] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(704, 0), srcSize: cellSize)],
        stepTime: 1.0);
    stageSprites[StageObjType.wizard] = SpriteAnimation.spriteList(
        [Sprite(stageImg, srcPosition: Vector2(736, 0), srcSize: cellSize)],
        stepTime: 1.0);

    objFactory = StageObjFactory(
      stageSpriteAnimatinos: stageSprites,
      breakingBlockAnimation: SpriteAnimation.spriteList(
          [Sprite(blockImg, srcPosition: Vector2(32, 0), srcSize: cellSize)],
          stepTime: 1.0),
      explodingBombAnimation: SpriteAnimation.spriteList(
          [Sprite(bombImg, srcPosition: Vector2(32, 0), srcSize: cellSize)],
          stepTime: 1.0),
      swordsmanLeftAnimation: SpriteAnimation.spriteList([
        Sprite(swordsmanImg, srcPosition: Vector2(128, 0), srcSize: cellSize),
        Sprite(swordsmanImg, srcPosition: Vector2(160, 0), srcSize: cellSize),
      ], stepTime: objectStepTime),
      swordsmanRightAnimation: SpriteAnimation.spriteList([
        Sprite(swordsmanImg, srcPosition: Vector2(192, 0), srcSize: cellSize),
        Sprite(swordsmanImg, srcPosition: Vector2(224, 0), srcSize: cellSize),
      ], stepTime: objectStepTime),
      swordsmanUpAnimation: SpriteAnimation.spriteList([
        Sprite(swordsmanImg, srcPosition: Vector2(64, 0), srcSize: cellSize),
        Sprite(swordsmanImg, srcPosition: Vector2(96, 0), srcSize: cellSize),
      ], stepTime: objectStepTime),
      swordsmanDownAnimation: SpriteAnimation.spriteList([
        Sprite(swordsmanImg, srcPosition: Vector2(0, 0), srcSize: cellSize),
        Sprite(swordsmanImg, srcPosition: Vector2(32, 0), srcSize: cellSize),
      ], stepTime: objectStepTime),
      swordsmanDownAttackAnimation: SpriteAnimation.fromFrameData(
        swordsmanAttackDImg,
        SpriteAnimationData.sequenced(
            amount: 5,
            stepTime: swordsmanAttackStepTime,
            textureSize: Vector2(96.0, 64.0)),
      ),
      swordsmanUpAttackAnimation: SpriteAnimation.fromFrameData(
        swordsmanAttackUImg,
        SpriteAnimationData.sequenced(
            amount: 5,
            stepTime: swordsmanAttackStepTime,
            textureSize: Vector2(96.0, 64.0)),
      ),
      swordsmanLeftAttackAnimation: SpriteAnimation.fromFrameData(
        swordsmanAttackLImg,
        SpriteAnimationData.sequenced(
            amount: 5,
            stepTime: swordsmanAttackStepTime,
            textureSize: Vector2(64.0, 96.0)),
      ),
      swordsmanRightAttackAnimation: SpriteAnimation.fromFrameData(
        swordsmanAttackRImg,
        SpriteAnimationData.sequenced(
            amount: 5,
            stepTime: swordsmanAttackStepTime,
            textureSize: Vector2(64.0, 96.0)),
      ),
    );
  }

  /// ステージを生成する
  void initialize(
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    effectBase = [
      objFactory.create(
          typeLevel: StageObjTypeLevel(type: StageObjType.box, level: 1),
          pos: Point(0, 0))
    ];
    effectBase.first.animation.opacity = 0.0;
    gameWorld.add(effectBase.first.animation);
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
    ret['stageLT'] = stageLT.encode();
    ret['stageRB'] = stageRB.encode();
    final Map<String, dynamic> staticObjsMap = {};
    for (final entry in staticObjs.entries) {
      staticObjsMap[entry.key.encode()] = entry.value.encode();
    }
    ret['staticObjs'] = staticObjsMap;
    final List<Map<String, dynamic>> boxesList = [
      for (final e in boxes) e.encode()
    ];
    ret['boxes'] = boxesList;
    final List<Map<String, dynamic>> enemiesList = [
      for (final e in enemies) e.encode()
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
    ret['handAbility'] = player.pushableNum;
    ret['legAbility'] = player.isLegAbilityOn;
    return ret;
  }

  void merge(
    Point pos,
    StageObj box,
    World gameWorld, {
    int breakLeftOffset = -1,
    int breakTopOffset = -1,
    int breakRightOffset = 1,
    int breakBottomOffset = 1,
    bool onlyDelete = false,
  }) {
    // 引数位置を中心として周囲のブロックを爆破する
    /// 破壊されたブロックの位置のリスト
    final List<Point> breaked = [];
    final List<Component> breakingAnimations = [];

    for (int y = pos.y + breakTopOffset; y <= pos.y + breakBottomOffset; y++) {
      for (int x = pos.x + breakLeftOffset;
          x <= pos.x + breakRightOffset;
          x++) {
        if (x < stageLT.x || x > stageRB.x) continue;
        if (y < stageLT.y || y > stageRB.y) continue;
        final p = Point(x, y);
        if (p == pos) continue;
        if (get(p).type == StageObjType.wall &&
            get(p).level <= box.typeLevel.level) {
          setStaticType(p, StageObjType.none, gameWorld);
          breakingAnimations.add(objFactory.createBreakingBlock(p));
          breaked.add(p);
        }
      }
    }
    // 引数位置を元に、どういうオブジェクトが出現するか決定
    final distance = pos.distance();
    ObjInBlock pattern = ObjInBlock.jewel1_2;
    int jewelLevel = 1;
    for (final objInBlock in SettingVariables.objInBlockMap.entries) {
      if (objInBlock.key <= distance) {
        pattern = objInBlock.value;
      }
    }
    for (final level in SettingVariables.jewelLevelInBlockMap.entries) {
      if (level.key <= distance) {
        jewelLevel = level.value;
      }
    }

    /// 破壊後に出現する(追加する)オブジェクトのリスト
    final List<StageObj> adding = [];

    /// 破壊されたブロック位置のうち、まだオブジェクトが出現していない位置のリスト
    final breakedRemain = [...breaked];

    // 宝石の出現について
    switch (pattern) {
      case ObjInBlock.jewel1_2:
      case ObjInBlock.jewel1_2SpikeOrTrap1:
      case ObjInBlock.jewel1_2Drill1:
      case ObjInBlock.jewel1_2Treasure1:
      case ObjInBlock.jewel1_2Warp1:
      case ObjInBlock.jewel1_2Bomb1:
      case ObjInBlock.jewel1_2BeltGuardianSwordsman1:
        // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
        final jewelAppears = breaked.sample((breaked.length / 2).ceil());
        breakedRemain.removeWhere((element) => jewelAppears.contains(element));
        for (final jewelAppear in jewelAppears) {
          adding.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.box,
                level: jewelLevel,
              ),
              pos: jewelAppear));
          boxes.add(adding.last);
        }
        break;
    }

    // その他オブジェクトの出現について
    switch (pattern) {
      case ObjInBlock.jewel1_2:
        break;
      case ObjInBlock.jewel1_2SpikeOrTrap1:
        // 宝石出現以外の位置に最大1個の敵/罠を出現させる
        if (breakedRemain.isNotEmpty) {
          int spikeOrTrap = Random().nextInt(4);
          final appear = breakedRemain.sample(1).first;
          if (spikeOrTrap == 0) {
            adding.add(objFactory.create(
                typeLevel:
                    StageObjTypeLevel(type: StageObjType.spike, level: 1),
                pos: appear));
            enemies.add(adding.last);
          } else if (spikeOrTrap == 1) {
            adding.add(objFactory.create(
                typeLevel: StageObjTypeLevel(type: StageObjType.trap, level: 1),
                pos: appear));
            boxes.add(adding.last);
          }
        }
        break;
      case ObjInBlock.jewel1_2Drill1:
        // 宝石出現以外の位置に最大1個のドリルを出現させる
        if (breakedRemain.isNotEmpty) {
          bool drill = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (drill) {
            adding.add(objFactory.create(
                typeLevel:
                    StageObjTypeLevel(type: StageObjType.drill, level: 1),
                pos: appear));
            boxes.add(adding.last);
          }
        }
        break;
      case ObjInBlock.jewel1_2Treasure1:
        // 宝石出現以外の位置に最大1個の宝箱を出現させる
        if (breakedRemain.isNotEmpty) {
          bool treasure = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (treasure) {
            setStaticType(appear, StageObjType.treasureBox, gameWorld);
          }
        }
        break;
      case ObjInBlock.jewel1_2Warp1:
        // 宝石出現以外の位置に最大1個のワープを出現させる
        if (breakedRemain.isNotEmpty) {
          bool warp = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (warp) {
            setStaticType(appear, StageObjType.warp, gameWorld);
            warpPoints.add(appear);
          }
        }
        break;
      case ObjInBlock.jewel1_2Bomb1:
        // 宝石出現以外の位置に最大1個のボムを出現させる
        if (breakedRemain.isNotEmpty) {
          bool bomb = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (bomb) {
            adding.add(objFactory.create(
                typeLevel: StageObjTypeLevel(type: StageObjType.bomb, level: 1),
                pos: appear));
            boxes.add(adding.last);
          }
        }
        break;
      case ObjInBlock.jewel1_2BeltGuardianSwordsman1:
        // 宝石出現以外の位置にコンベア/ガーディアン/剣を持つ敵をそれぞれ最大1個出現させる
        for (final StageObjType type in [
          StageObjType.swordsman,
          StageObjType.beltL,
          StageObjType.guardian,
        ]) {
          if (breakedRemain.isNotEmpty) {
            bool isAppear = Random().nextBool();
            final appear = breakedRemain.sample(1).first;
            if (isAppear) {
              if (type == StageObjType.beltL) {
                final trueType = [
                  StageObjType.beltL,
                  StageObjType.beltR,
                  StageObjType.beltU,
                  StageObjType.beltD,
                ].sample(1).first;
                setStaticType(appear, trueType, gameWorld);
                beltPoints.add(appear);
              } else {
                adding.add(objFactory.create(
                    typeLevel: StageObjTypeLevel(type: type, level: 1),
                    pos: appear));
                switch (type) {
                  case StageObjType.guardian:
                    boxes.add(adding.last);
                    break;
                  case StageObjType.swordsman:
                    enemies.add(adding.last);
                    break;
                  default:
                    break;
                }
              }
            }
            breakedRemain.remove(appear);
          }
        }
        break;
    }
    gameWorld.addAll([for (final e in adding) e.animation]);

    // TODO:削除というか別の方法で
    // 床をランダムに水やマグマに変える
    /*for (final pos in breaked) {
      final StageObjType type = [
        StageObjType.none,
        StageObjType.none,
        StageObjType.none,
        StageObjType.water,
        StageObjType.magma,
      ].sample(1).first;
      setStaticType(pos, type, gameWorld);
    }*/

    // スコア加算
    score += box.typeLevel.level * 100;

    if (onlyDelete) {
      // 対象オブジェクトを消す
      gameWorld.remove(box.animation);
      boxes.remove(box);
    } else {
      // 当該位置のオブジェクトを消す
      final merged = boxes.firstWhere((element) => element.pos == pos);
      gameWorld.remove(merged.animation);
      boxes.remove(merged);
      // 移動したオブジェクトのレベルを上げる
      (box.animation.children.first.children.first as TextComponent).text =
          (++box.typeLevel.level).toString();
    }

    // 破壊したブロックのアニメーションを描画
    gameWorld.addAll(breakingAnimations);
  }

  StageObjTypeLevel get(Point p) {
    final box = boxes.firstWhereOrNull((element) => element.pos == p);
    final enemy = enemies.firstWhereOrNull((element) => element.pos == p);
    if (enemy != null) {
      return enemy.typeLevel;
    } else if (box != null) {
      return box.typeLevel;
    } else {
      return staticObjs[p]!.typeLevel;
    }
  }

  StageObj getObject(Point p) {
    final box = boxes.firstWhereOrNull((element) => element.pos == p);
    final enemy = enemies.firstWhereOrNull((element) => element.pos == p);
    if (enemy != null) {
      return enemy;
    } else if (box != null) {
      return box;
    } else {
      return staticObjs[p]!;
    }
  }

  void setStaticType(Point p, StageObjType type, World gameWorld,
      {int level = 1}) {
    gameWorld.remove(staticObjs[p]!.animation);
    staticObjs[p] = objFactory.create(
        typeLevel: StageObjTypeLevel(type: type, level: level), pos: p);
    gameWorld.add(staticObjs[p]!.animation);
  }

  void _setStageDataFromSaveData(
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    // ステージ範囲設定
    stageLT = Point.decode(stageData['stageLT']);
    stageRB = Point.decode(stageData['stageRB']);
    // スコア設定
    _score = stageData['score'];
    _scoreVisual = _score.toDouble();

    // 各種ステージオブジェクト設定
    staticObjs.clear();
    for (final entry
        in (stageData['staticObjs'] as Map<String, dynamic>).entries) {
      staticObjs[Point.decode(entry.key)] =
          objFactory.createFromMap(entry.value);
    }
    boxes = [
      for (final e in stageData['boxes'] as List<dynamic>)
        objFactory.createFromMap(e)
    ];
    enemies = [
      for (final e in stageData['enemies'] as List<dynamic>)
        objFactory.createFromMap(e)
    ];
    warpPoints = [
      for (final e in stageData['warpPoints'] as List<dynamic>) Point.decode(e)
    ];
    beltPoints = [
      for (final e in stageData['beltPoints'] as List<dynamic>) Point.decode(e)
    ];
    gameWorld.addAll([for (final e in staticObjs.values) e.animation]);
    gameWorld.addAll([for (final e in boxes) e.animation]);
    gameWorld.addAll([for (final e in enemies) e.animation]);
    // プレイヤー作成
    player = objFactory.createFromMap(stageData['player']) as Player;
    player.pushableNum = stageData['handAbility'];
    player.isLegAbilityOn = stageData['legAbility'];
    gameWorld.addAll([player.animation]);
    // カメラはプレイヤーに追従
    camera.follow(
      player.animation,
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
    staticObjs.clear();
    boxes.clear();
    enemies.clear();
    for (int y = stageLT.y; y <= stageRB.y; y++) {
      for (int x = stageLT.x; x <= stageRB.x; x++) {
        if (x == 0 && y == 0) {
          // プレイヤー初期位置、床
          staticObjs[Point(x, y)] = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y));
        } else if ((x == 0 && -2 <= y && y <= 2) ||
            (y == 0 && -2 <= x && x <= 2)) {
          // プレイヤー初期位置の上下左右2マス、宝石
          staticObjs[Point(x, y)] = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.none,
              ),
              pos: Point(x, y));
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.box,
              ),
              pos: Point(x, y)));
        } else {
          // その他、ブロック
          staticObjs[Point(x, y)] = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, y));
        }
      }
    }
    gameWorld.addAll([for (final e in staticObjs.values) e.animation]);
    gameWorld.addAll([for (final e in boxes) e.animation]);
    //gameWorld.addAll([for (final e in enemies) e.animation]);

    // プレイヤー作成
    player = objFactory.create(
        typeLevel: StageObjTypeLevel(type: StageObjType.player, level: 1),
        pos: Point(0, 0)) as Player;
    gameWorld.addAll([player.animation]);
    // カメラはプレイヤーに追従
    camera.follow(
      player.animation,
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
    final List<Point> prohibitedPoints = [];
    // プレイヤー更新
    player.update(
        dt, moveInput, gameWorld, camera, this, false, prohibitedPoints);
    bool playerStartMoving =
        (before == Move.none && player.moving != Move.none);
    // コンベア更新
    for (final belt in beltPoints) {
      staticObjs[belt]!.update(dt, moveInput, gameWorld, camera, this,
          playerStartMoving, prohibitedPoints);
    }
    // 敵更新
    for (final enemy in enemies) {
      enemy.update(dt, player.moving, gameWorld, camera, this,
          playerStartMoving, prohibitedPoints);
    }
    if (playerStartMoving) {
      // 動き始めたらプレイヤーに再フォーカス
      camera.follow(
        player.animation,
        maxSpeed: cameraMaxSpeed,
      );
    }
    {
      // 同じレベルの敵同士が同じ位置になったらマージしてレベルアップ
      // TODO: 敵がお互いにすれ違ってマージしない場合あり
      final List<Point> mergingPosList = [];
      final List<StageObj> mergedEnemies = [];
      for (final enemy in enemies) {
        if (mergingPosList.contains(enemy.pos)) {
          continue;
        }
        final t = enemies.where((element) =>
            element != enemy &&
            element.pos == enemy.pos &&
            element.typeLevel.type == StageObjType.spike &&
            element.typeLevel.level == enemy.typeLevel.level);
        if (t.isNotEmpty) {
          mergingPosList.add(enemy.pos);
          mergedEnemies.add(enemy);
          // マージされた敵を削除
          gameWorld.remove(enemy.animation);
          // レベルを上げる
          t.first.animation.removeAll(t.first.animation.children);
          t.first.animation.add(
            AlignComponent(
              alignment: Anchor.center,
              child: TextComponent(
                text: (++t.first.typeLevel.level).toString(),
                textRenderer: TextPaint(
                  style: const TextStyle(
                    fontFamily: 'Aboreto',
                    color: Color(0xff000000),
                  ),
                ),
              ),
            ),
          );
        }
      }
      // マージされた敵を削除
      for (final enemy in mergedEnemies) {
        enemies.remove(enemy);
      }
    }
    // オブジェクト更新(罠：敵を倒す、ガーディアン：周囲の敵を倒す)
    // TODO: これらは他オブジェクトの移動完了時のみ動かせばよい
    // update()でboxesリストが変化する可能性がある(ボムの爆発等)ためコピーを使う
    final boxesCopied = [for (final box in boxes) box];
    for (final box in boxesCopied) {
      box.update(dt, player.moving, gameWorld, camera, this, playerStartMoving,
          prohibitedPoints);
    }

    // 移動完了時
    if (before != Move.none && player.moving == Move.none) {
      // 移動によって新たな座標が見えそうなら追加する
      // 左端
      if (camera
          .canSee(staticObjs[Point(stageLT.x, player.pos.y)]!.animation)) {
        stageLT.x--;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageLT.x, y));
          staticObjs[Point(stageLT.x, y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 右端
      if (camera
          .canSee(staticObjs[Point(stageRB.x, player.pos.y)]!.animation)) {
        stageRB.x++;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(stageRB.x, y));
          staticObjs[Point(stageRB.x, y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 上端
      if (camera
          .canSee(staticObjs[Point(player.pos.x, stageLT.y)]!.animation)) {
        stageLT.y--;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageLT.y));
          staticObjs[Point(x, stageLT.y)] = adding;
          gameWorld.add(adding.animation);
        }
      }
      // 下端
      if (camera
          .canSee(staticObjs[Point(player.pos.x, stageRB.y)]!.animation)) {
        stageRB.y++;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = objFactory.create(
              typeLevel: StageObjTypeLevel(
                type: StageObjType.wall,
              ),
              pos: Point(x, stageRB.y));
          staticObjs[Point(x, stageRB.y)] = adding;
          gameWorld.add(adding.animation);
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

  bool isClear() {
    return false;
  }

  double get cameraMaxSpeed {
    return max((stageRB - stageLT).x, (stageRB - stageLT).y) * 2 * cellSize.x;
  }
}
