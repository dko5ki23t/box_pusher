import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/barrierman.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
import 'package:box_pusher/game_core/stage_objs/boneman.dart';
import 'package:box_pusher/game_core/stage_objs/builder.dart';
import 'package:box_pusher/game_core/stage_objs/canon.dart';
import 'package:box_pusher/game_core/stage_objs/fire.dart';
import 'package:box_pusher/game_core/stage_objs/ghost.dart';
import 'package:box_pusher/game_core/stage_objs/girl.dart';
import 'package:box_pusher/game_core/stage_objs/gorilla.dart';
import 'package:box_pusher/game_core/stage_objs/jewel.dart';
import 'package:box_pusher/game_core/stage_objs/drill.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/guardian.dart';
import 'package:box_pusher/game_core/stage_objs/kangaroo.dart';
import 'package:box_pusher/game_core/stage_objs/magma.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/pusher.dart';
import 'package:box_pusher/game_core/stage_objs/rabbit.dart';
import 'package:box_pusher/game_core/stage_objs/shop.dart';
import 'package:box_pusher/game_core/stage_objs/smoke.dart';
import 'package:box_pusher/game_core/stage_objs/smoker.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/spawner.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/swordsman.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/treasure_box.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/turtle.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:box_pusher/game_core/stage_objs/water.dart';
import 'package:box_pusher/game_core/stage_objs/weight.dart';
import 'package:box_pusher/game_core/stage_objs/wizard.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

/// Stageクラスに1つだけ用意する
/// 各ステージオブジェクトの画像やAnimationを管理し、
/// 各ステージオブジェクトのインスタンスを作成する
class StageObjFactory {
  bool isReady = false;
  late final Image errorImg;
  late final Image coinImg;
  Map<StageObjType, Image> baseImages = {};

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラ
  EffectController? baseMergable;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラが逆再生中かどうか
  bool isBaseMergableReverse = false;

  void setReverse() {
    isBaseMergableReverse = !isBaseMergableReverse;
  }

  StageObjFactory();

  Future<void> onLoad() async {
    errorImg = await Flame.images.load('noimage.png');
    for (final objType in StageObjType.values) {
      baseImages[objType] = await Flame.images.load(objType.baseImageFileName);
    }
    await Archer.onLoad(errorImg: errorImg);
    await Barrierman.onLoad(errorImg: errorImg);
    await Belt.onLoad(errorImg: errorImg);
    await Block.onLoad(errorImg: errorImg);
    await Bomb.onLoad(errorImg: errorImg);
    await Boneman.onLoad(errorImg: errorImg);
    await Builder.onLoad(errorImg: errorImg);
    await Canon.onLoad(errorImg: errorImg);
    await Drill.onLoad(errorImg: errorImg);
    await Fire.onLoad(errorImg: errorImg);
    await Floor.onLoad(errorImg: errorImg);
    await Ghost.onLoad(errorImg: errorImg);
    await Girl.onLoad(errorImg: errorImg);
    await Gorilla.onLoad(errorImg: errorImg);
    await Guardian.onLoad(errorImg: errorImg);
    await Jewel.onLoad(errorImg: errorImg);
    await Kangaroo.onLoad(errorImg: errorImg);
    await Magma.onLoad(errorImg: errorImg);
    await Player.onLoad(errorImg: errorImg);
    await Pusher.onLoad(errorImg: errorImg);
    await Rabbit.onLoad(errorImg: errorImg);
    await Shop.onLoad(errorImg: errorImg);
    await Smoke.onLoad(errorImg: errorImg);
    await Smoker.onLoad(errorImg: errorImg);
    await Spawner.onLoad(errorImg: errorImg);
    await Spike.onLoad(errorImg: errorImg);
    await Swordsman.onLoad(errorImg: errorImg);
    await Trap.onLoad(errorImg: errorImg);
    await TreasureBox.onLoad(errorImg: errorImg);
    await Turtle.onLoad(errorImg: errorImg);
    await Warp.onLoad(errorImg: errorImg);
    await Water.onLoad(errorImg: errorImg);
    await Wizard.onLoad(errorImg: errorImg);
    await Weight.onLoad(errorImg: errorImg);
    coinImg = await Flame.images.load('coin.png');
    isReady = true;
  }

  StageObj create({
    required StageObjTypeLevel typeLevel,
    required Point pos,
    required int savedArg,
    Move vector = Move.down,
  }) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
    final type = typeLevel.type;
    Vector2 scale = isBaseMergableReverse
        ? Vector2.all(Stage.mergableZoomRate)
        : Vector2.all(1.0);
    final scaleEffect = ScaleEffect.by(
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
    );

    if (type == StageObjType.jewel ||
        type == StageObjType.trap ||
        type == StageObjType.drill ||
        type == StageObjType.bomb ||
        type == StageObjType.guardian ||
        type == StageObjType.canon ||
        type == StageObjType.boneman) {
      final controller = scaleEffect.controller;
      baseMergable ??= controller;
      controller.advance((isBaseMergableReverse
              ? (1.0 - baseMergable!.progress)
              : baseMergable!.progress) *
          Stage.mergableZoomDuration);
    }

    switch (type) {
      case StageObjType.none:
        return Floor(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.jewel:
        return Jewel(
          savedArg: savedArg,
          scale: scale,
          scaleEffect: scaleEffect,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.trap:
        return Trap(
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.player:
        throw ('Playerはこの関数で作成せず、StageObjFactory.createPlayer()で作成すること。');
      case StageObjType.block:
        return Block(
          pos: pos,
          level: typeLevel.level,
          savedArg: savedArg,
        );
      case StageObjType.spike:
        return Spike(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.drill:
        return Drill(
            savedArg: savedArg,
            pos: pos,
            scale: scale,
            scaleEffect: scaleEffect,
            level: typeLevel.level);
      case StageObjType.treasureBox:
        return TreasureBox(
            savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.warp:
        return Warp(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.bomb:
        return Bomb(
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.belt:
        return Belt(
            pos: pos,
            level: typeLevel.level,
            savedArg: savedArg,
            vector: vector);
      case StageObjType.guardian:
        return Guardian(
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.water:
        return Water(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.magma:
        return Magma(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.swordsman:
        return Swordsman(
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
          setPosition: setPosition,
        )..vector = vector;
      case StageObjType.archer:
        return Archer(
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.wizard:
        return Wizard(
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.ghost:
        return Ghost(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.fire:
        return Fire(
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.builder:
        return Builder(
          savedArg: savedArg,
          pos: pos,
        )..vector = vector;
      case StageObjType.pusher:
        return Pusher(
          savedArg: savedArg,
          pos: pos,
        )..vector = vector;
      case StageObjType.smoker:
        return Smoker(savedArg: savedArg, pos: pos, level: typeLevel.level)
          ..vector = vector;
      case StageObjType.smoke:
        return Smoke(
          savedArg: savedArg,
          pos: pos,
          lastingTurns: Smoker.smokeTurns,
          level: typeLevel.level,
        );
      case StageObjType.gorilla:
        return Gorilla(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.rabbit:
        return Rabbit(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.kangaroo:
        return Kangaroo(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.turtle:
        return Turtle(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.girl:
        return Girl(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.shop:
        return Shop(
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
          coinImg: coinImg,
          getAnimeFunc: (tl) {
            return create(typeLevel: tl, pos: Point(0, 0), savedArg: 0)
                .animationComponent
                .animation!;
          },
        );
      case StageObjType.canon:
        return Canon(
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level,
            vector: vector);
      case StageObjType.spawner:
        return Spawner(savedArg: savedArg, pos: pos, level: typeLevel.level);
      case StageObjType.boneman:
        return Boneman(
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.barrierman:
        return Barrierman(savedArg: savedArg, pos: pos, level: typeLevel.level)
          ..vector = vector;
      case StageObjType.weight:
        return Weight(
          savedArg: savedArg,
          scale: scale,
          scaleEffect: scaleEffect,
          pos: pos,
          level: typeLevel.level,
        );
    }
  }

  Player createPlayer({
    required Point pos,
    required Move vector,
    required int savedArg,
  }) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
    return Player(
      savedArg: savedArg,
      pos: pos,
    )..vector = vector;
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
      typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
      pos: Point.decode(src['pos']),
      vector: Move.values[src['vector']],
      savedArg: src['arg'] ?? 0,
    );
  }

  Player createPlayerFromMap(Map<String, dynamic> src) {
    return createPlayer(
      pos: Point.decode(src['pos']),
      vector: Move.values[src['vector']],
      savedArg: src['arg'] ?? 0,
    )
      ..pushableNum = src['handAbility'] ?? 1
      ..isAbilityAquired[PlayerAbility.hand] = (src['handAbility'] ?? 1) == -1
      ..isAbilityAquired[PlayerAbility.leg] = src['legAbility'] ?? false
      ..isAbilityAquired[PlayerAbility.pocket] = src['pocketAbility'] ?? false
      ..pocketItem =
          src['pocketItem'] != null ? createFromMap(src['pocketItem']) : null
      ..isAbilityAquired[PlayerAbility.armer] = src['armerAbility'] ?? false
      ..armerRecoveryTurns = src['armerRecoveryTurns'] ?? 0
      ..isAbilityAquired[PlayerAbility.eye] = src['eyeAbility'] ?? false
      ..isAbilityAquired[PlayerAbility.merge] = src['mergeAbility'] ?? false;
  }

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.animationComponent.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }

  /// 押せるオブジェクトに共通して付くエフェクトをセットする
  void setScaleEffects(StageObj obj) {
    Vector2 scale = isBaseMergableReverse
        ? Vector2.all(Stage.mergableZoomRate)
        : Vector2.all(1.0);
    final scaleEffect = ScaleEffect.by(
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
    );
    final controller = scaleEffect.controller;
    baseMergable ??= controller;
    controller.advance((isBaseMergableReverse
            ? (1.0 - baseMergable!.progress)
            : baseMergable!.progress) *
        Stage.mergableZoomDuration);
    obj.animationComponent.scale = scale;
    obj.animationComponent.add(scaleEffect);
  }
}
