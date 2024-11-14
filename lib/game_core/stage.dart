import 'dart:math';

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/components/opacity_effect_text_component.dart';
import 'package:box_pusher/game_core/setting_variables.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
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

  /// 動く物のzインデックス
  static const dynamicPriority = 2;

  /// 画面前面に表示する物（スコア加算表示等）のzインデックス
  static const frontPriority = 3;

  bool isReady = false;

  late StageObjFactory objFactory;

  /// マージ時のエフェクト画像
  late Image mergeEffectImg;

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

  Stage() {
    objFactory = StageObjFactory();
  }

  Future<void> onLoad() async {
    await objFactory.onLoad();
    mergeEffectImg = await Flame.images.load('merge_effect.png');
    isReady = true;
  }

  /// ステージを生成する
  void initialize(
      World gameWorld, CameraComponent camera, Map<String, dynamic> stageData) {
    assert(isReady, 'Stage.onLoad() is not called!');
    effectBase = [
      objFactory.create(
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
        //
        if (get(p).type == StageObjType.block &&
            SettingVariables.canBreakBlock(get(p) as Block, box)) {
          breakingAnimations.add((get(p) as Block).createBreakingBlock());
          setStaticType(p, StageObjType.none, gameWorld);
          breaked.add(p);
        }
      }
    }
    // 引数位置を元に、どういうオブジェクトが出現するか決定
    late ObjInBlock pattern;
    int jewelLevel = 1;
    for (final objInBlock in SettingVariables.objInBlockMap.entries) {
      if (objInBlock.key.contains(pos)) {
        pattern = objInBlock.value;
        break;
      }
    }
    for (final level in SettingVariables.jewelLevelInBlockMap.entries) {
      if (level.key.contains(pos)) {
        jewelLevel = level.value;
        break;
      }
    }

    /// 破壊後に出現する(追加する)オブジェクトのリスト
    final List<StageObj> adding = [];

    /// 破壊されたブロック位置のうち、まだオブジェクトが出現していない位置のリスト
    final breakedRemain = [...breaked];

    // 宝石の出現について
    // 破壊したブロックの数/2(切り上げ)個の宝石を出現させる
    final jewelAppears =
        breaked.sample((breaked.length * pattern.jewelPercent / 100).ceil());
    breakedRemain.removeWhere((element) => jewelAppears.contains(element));
    for (final jewelAppear in jewelAppears) {
      adding.add(objFactory.create(
          typeLevel: StageObjTypeLevel(
            type: StageObjType.jewel,
            level: jewelLevel,
          ),
          pos: jewelAppear));
      boxes.add(adding.last);
    }

    // その他オブジェクトの出現について
    if (pattern.items1.isNotEmpty) {
      for (int i = 0; i < pattern.itemsMaxNum1; i++) {
        // リストの中から出現させるアイテムを選ぶ
        StageObjTypeLevel typeLevel = pattern.items1.sample(1).first;
        // 宝石出現以外の位置に最大1個アイテムを出現させる
        if (breakedRemain.isNotEmpty) {
          bool canAppear = Random().nextBool();
          final appear = breakedRemain.sample(1).first;
          if (canAppear) {
            if (typeLevel.type == StageObjType.treasureBox) {
              setStaticType(appear, StageObjType.treasureBox, gameWorld);
            } else if (typeLevel.type == StageObjType.treasureBox) {
              setStaticType(appear, StageObjType.treasureBox, gameWorld);
              warpPoints.add(appear);
            } else if (typeLevel.type == StageObjType.belt) {
              setStaticType(appear, StageObjType.belt, gameWorld);
              assert(get(appear).runtimeType == Belt,
                  'Beltじゃない(=Beltの上に何か載ってる)、ありえない！');
              get(appear).vector = MoveExtent.straights.sample(1).first;
              beltPoints.add(appear);
            } else {
              adding.add(objFactory.create(typeLevel: typeLevel, pos: appear));
              if (adding.last.isEnemy) {
                enemies.add(adding.last);
              } else {
                boxes.add(adding.last);
              }
            }
            // アイテム出現場所を取り除く
            breakedRemain.remove(appear);
          }
        }
      }
    }
    gameWorld.addAll([for (final e in adding) e.animationComponent]);

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
    int gettingScore = pow(2, (box.level - 1)).toInt() * 100;
    score += gettingScore;

    // スコア加算表示
    if (gettingScore > 0 && SettingVariables.showAddedScoreOnMergePos) {
      final addingScoreText = OpacityEffectTextComponent(
        text: "+$gettingScore",
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Aboreto',
            color: Color(0xff000000),
          ),
        ),
      );
      gameWorld.add(RectangleComponent(
        priority: frontPriority,
        anchor: Anchor.center,
        position: Vector2(pos.x * cellSize.x, pos.y * cellSize.y) +
            cellSize / 2 -
            SettingVariables.addedScoreEffectMove,
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
                SettingVariables.addedScoreEffectMove,
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
      gameWorld.remove(box.animationComponent);
      boxes.remove(box);
    } else {
      // 当該位置のオブジェクトを消す
      final merged = boxes.firstWhere((element) => element.pos == pos);
      gameWorld.remove(merged.animationComponent);
      boxes.remove(merged);
      // 移動したオブジェクトのレベルを上げる
      box.level++;
    }

    // 破壊したブロックのアニメーションを描画
    gameWorld.addAll(breakingAnimations);

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
    gameWorld.remove(staticObjs[p]!.animationComponent);
    staticObjs[p] = objFactory.create(
        typeLevel: StageObjTypeLevel(type: type, level: level), pos: p);
    gameWorld.add(staticObjs[p]!.animationComponent);
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
    gameWorld.addAll([for (final e in staticObjs.values) e.animationComponent]);
    gameWorld.addAll([for (final e in boxes) e.animationComponent]);
    gameWorld.addAll([for (final e in enemies) e.animationComponent]);
    // プレイヤー作成
    player = objFactory.createFromMap(stageData['player']) as Player;
    player.pushableNum = stageData['handAbility'];
    player.isLegAbilityOn = stageData['legAbility'];
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
                type: StageObjType.jewel,
              ),
              pos: Point(x, y)));
        } else {
          // その他は定めたパターンに従う
          staticObjs[Point(x, y)] = createStaticObjWithPattern(Point(x, y));
        }
      }
    }
    gameWorld.addAll([for (final e in staticObjs.values) e.animationComponent]);
    gameWorld.addAll([for (final e in boxes) e.animationComponent]);
    //gameWorld.addAll([for (final e in enemies) e.animationComponent]);

    // プレイヤー作成
    player = objFactory.create(
        typeLevel: StageObjTypeLevel(type: StageObjType.player, level: 1),
        pos: Point(0, 0)) as Player;
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
    for (final enemy in enemies) {
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
      // TODO: 敵がお互いにすれ違ってマージしない場合あり
      // TODO: レベルがMAXでマージできない場合はそもそも同じマスに移動できないようにするべき
      final List<Point> mergingPosList = [];
      final List<StageObj> mergedEnemies = [];
      for (final enemy in enemies) {
        if (mergingPosList.contains(enemy.pos)) {
          continue;
        }
        final t = enemies.where((element) =>
            element != enemy &&
            element.pos == enemy.pos &&
            element.isSameTypeLevel(enemy));
        if (t.isNotEmpty) {
          mergingPosList.add(enemy.pos);
          mergedEnemies.add(enemy);
          // マージされた敵を削除
          gameWorld.remove(enemy.animationComponent);
          // レベルを上げる
          t.first.animationComponent
              .removeAll(t.first.animationComponent.children);
          t.first.level++;
        }
      }
      // マージされた敵を削除
      for (final enemy in mergedEnemies) {
        enemies.remove(enemy);
      }
    }
    // オブジェクト更新(罠：敵を倒す、ガーディアン：周囲の敵を倒す)
    // これらはプレイヤーの移動完了時のみ動かす
    // update()でboxesリストが変化する可能性がある(ボムの爆発等)ためコピーを使う
    if (playerEndMoving) {
      final boxesCopied = [for (final box in boxes) box];
      for (final box in boxesCopied) {
        box.update(dt, player.moving, gameWorld, camera, this,
            playerStartMoving, playerEndMoving, prohibitedPoints);
      }
    }

    // 移動完了時
    if (before != Move.none && player.moving == Move.none) {
      // 移動によって新たな座標が見えそうなら追加する
      // 左端
      if (camera.canSee(
          staticObjs[Point(stageLT.x, player.pos.y)]!.animationComponent)) {
        stageLT.x--;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = createStaticObjWithPattern(Point(stageLT.x, y));
          staticObjs[Point(stageLT.x, y)] = adding;
          gameWorld.add(adding.animationComponent);
        }
      }
      // 右端
      if (camera.canSee(
          staticObjs[Point(stageRB.x, player.pos.y)]!.animationComponent)) {
        stageRB.x++;
        for (int y = stageLT.y; y <= stageRB.y; y++) {
          final adding = createStaticObjWithPattern(Point(stageRB.x, y));
          staticObjs[Point(stageRB.x, y)] = adding;
          gameWorld.add(adding.animationComponent);
        }
      }
      // 上端
      if (camera.canSee(
          staticObjs[Point(player.pos.x, stageLT.y)]!.animationComponent)) {
        stageLT.y--;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = createStaticObjWithPattern(Point(x, stageLT.y));
          staticObjs[Point(x, stageLT.y)] = adding;
          gameWorld.add(adding.animationComponent);
        }
      }
      // 下端
      if (camera.canSee(
          staticObjs[Point(player.pos.x, stageRB.y)]!.animationComponent)) {
        stageRB.y++;
        for (int x = stageLT.x; x <= stageRB.x; x++) {
          final adding = createStaticObjWithPattern(Point(x, stageRB.y));
          staticObjs[Point(x, stageRB.y)] = adding;
          gameWorld.add(adding.animationComponent);
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

  /// 引数で指定した位置に、パターンに従った静止物を生成する
  StageObj createStaticObjWithPattern(Point point) {
    if (SettingVariables.animalsPoints.containsKey(point)) {
      // 動物がいる位置（固定位置）
      return objFactory.create(
          typeLevel: StageObjTypeLevel(
            type: SettingVariables.animalsPoints[point]!,
          ),
          pos: point);
    } else {
      // その他は定めたパターンに従う
      for (final pattern in SettingVariables.blockFloorMap.entries) {
        if (pattern.key.contains(point)) {
          int rand = Random().nextInt(100);
          int threshold = pattern.value.floorPercent;
          if (rand < threshold) {
            return objFactory.create(
                typeLevel: StageObjTypeLevel(
                  type: StageObjType.none,
                ),
                pos: point);
          }
          for (final p in pattern.value.blockPercents.entries) {
            threshold += p.value;
            if (rand < threshold) {
              return objFactory.create(
                  typeLevel: StageObjTypeLevel(
                    type: StageObjType.block,
                    level: p.key,
                  ),
                  pos: point);
            }
          }
          assert(false, 'arienai!');
        }
      }
    }
    assert(false, 'arienai!');
    return objFactory.create(
        typeLevel: StageObjTypeLevel(
          type: StageObjType.block,
        ),
        pos: point);
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
