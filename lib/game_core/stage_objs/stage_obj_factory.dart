import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
import 'package:box_pusher/game_core/stage_objs/builder.dart';
import 'package:box_pusher/game_core/stage_objs/canon.dart';
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
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/swordsman.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/treasure_box.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/turtle.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:box_pusher/game_core/stage_objs/water.dart';
import 'package:box_pusher/game_core/stage_objs/wizard.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class StageObjFactory {
  bool isReady = false;
  late final Image errorImg;
  late final List<Image> attackArchersImgs;
  late final Image arrowImg;
  late final List<Map<Move, Image>> guardianSwordForwardAttackImgs;
  late final Map<int, Image> guardianSwordRoundAttackImgs;
  late final Map<int, Image> guardianSubAttackImgs;
  late final Map<int, Image> guardianArrowMagicAttackImgs;
  late final List<Map<Move, Image>> swordsmanAttackImgs;
  late final List<Image> swordsmanRoundAttackImgs;
  late final List<Image> attackWizardImgs;
  late final Image magicImg;
  late final Image canonballImg;
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
    attackArchersImgs = [
      for (final name in Archer.attackImageFileNames)
        await Flame.images.load(name)
    ];
    arrowImg = await Flame.images.load(Archer.arrowImageFileName);
    guardianSwordForwardAttackImgs = [];
    for (final names in Guardian.swordFowardAttackImageFileNames) {
      Map<Move, Image> images = {};
      for (final entry in names.entries) {
        images[entry.key] = await Flame.images.load(entry.value);
      }
      guardianSwordForwardAttackImgs.add(images);
    }
    guardianSwordRoundAttackImgs = {};
    for (final entry in Guardian.swordRoundAttackImageFileNames.entries) {
      guardianSwordRoundAttackImgs[entry.key] =
          await Flame.images.load(entry.value);
    }
    guardianSubAttackImgs = {};
    for (final entry in Guardian.subAttackImageFileNames.entries) {
      guardianSubAttackImgs[entry.key] = await Flame.images.load(entry.value);
    }
    guardianArrowMagicAttackImgs = {};
    for (final entry in Guardian.arrowMagicImageFileNames.entries) {
      guardianArrowMagicAttackImgs[entry.key] =
          await Flame.images.load(entry.value);
    }
    swordsmanAttackImgs = [];
    for (final names in Swordsman.attackImgFileNames) {
      Map<Move, Image> images = {};
      for (final entry in names.entries) {
        images[entry.key] = await Flame.images.load(entry.value);
      }
      swordsmanAttackImgs.add(images);
    }
    swordsmanRoundAttackImgs = [
      for (final name in Swordsman.roundAttackImgFileNames)
        await Flame.images.load(name)
    ];
    attackWizardImgs = [
      for (final name in Wizard.attackImageFileNames)
        await Flame.images.load(name)
    ];
    magicImg = await Flame.images.load(Wizard.magicImageFileName);
    canonballImg = await Flame.images.load(Canon.canonballFileName);
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
        type == StageObjType.guardian) {
      final controller = scaleEffect.controller;
      baseMergable ??= controller;
      controller.advance((isBaseMergableReverse
              ? (1.0 - baseMergable!.progress)
              : baseMergable!.progress) *
          Stage.mergableZoomDuration);
    }

    switch (type) {
      case StageObjType.none:
        return Floor(
            floorImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.jewel:
        return Jewel(
          jewelImg: baseImages[type]!,
          errorImg: errorImg,
          savedArg: savedArg,
          scale: scale,
          scaleEffect: scaleEffect,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.trap:
        return Trap(
            trapImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.player:
        throw ('Playerはこの関数で作成せず、StageObjFactory.createPlayer()で作成すること。');
      case StageObjType.block:
        return Block(
          blockImg: baseImages[type]!,
          pos: pos,
          level: typeLevel.level,
          errorImg: errorImg,
          savedArg: savedArg,
        );
      case StageObjType.spike:
        return Spike(
            spikeImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.drill:
        return Drill(
            drillImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            scale: scale,
            scaleEffect: scaleEffect,
            level: typeLevel.level);
      case StageObjType.treasureBox:
        return TreasureBox(
            treasureBoxImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.warp:
        return Warp(
            warpImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.bomb:
        return Bomb(
            bombImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.belt:
        return Belt(
            levelToAnimationImg: baseImages[type]!,
            pos: pos,
            level: typeLevel.level,
            errorImg: errorImg,
            savedArg: savedArg,
            vector: vector);
      case StageObjType.guardian:
        return Guardian(
            guardianImg: baseImages[type]!,
            swordForwardAttackImgs: guardianSwordForwardAttackImgs,
            swordRoundAttackImgs: guardianSwordRoundAttackImgs,
            subAttackImgs: guardianSubAttackImgs,
            arrowMagicImgs: guardianArrowMagicAttackImgs,
            errorImg: errorImg,
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.water:
        return Water(
            waterImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.magma:
        return Magma(
            magmaImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.swordsman:
        return Swordsman(
          swordsmanImg: baseImages[type]!,
          attackImgs: swordsmanAttackImgs,
          roundAttackImgs: swordsmanRoundAttackImgs,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.archer:
        return Archer(
          levelToAnimationImg: baseImages[type]!,
          levelToAttackAnimationImgs: attackArchersImgs,
          arrowImg: arrowImg,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.wizard:
        return Wizard(
          wizardImg: baseImages[type]!,
          attackImgs: attackWizardImgs,
          magicImg: magicImg,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.ghost:
        return Ghost(
            ghostImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.builder:
        return Builder(
          builderImg: baseImages[type]!,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
        )..vector = vector;
      case StageObjType.pusher:
        return Pusher(
          pusherImg: baseImages[type]!,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
        )..vector = vector;
      case StageObjType.smoker:
        return Smoker(
            smokerImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.smoke:
        return Smoke(
          smokeImg: baseImages[type]!,
          errorImg: errorImg,
          savedArg: savedArg,
          pos: pos,
          lastingTurns: Smoker.smokeTurns,
          level: typeLevel.level,
        );
      case StageObjType.gorilla:
        return Gorilla(
            gorillaImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.rabbit:
        return Rabbit(
            rabbitImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.kangaroo:
        return Kangaroo(
            kangarooImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.turtle:
        return Turtle(
            turtleImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.girl:
        return Girl(
            girlImg: baseImages[type]!,
            errorImg: errorImg,
            savedArg: savedArg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.shop:
        return Shop(
          shopImg: baseImages[type]!,
          errorImg: errorImg,
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
            canonImg: baseImages[type]!,
            canonballImg: canonballImg,
            errorImg: errorImg,
            savedArg: savedArg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level,
            vector: vector);
    }
  }

  Player createPlayer({
    required Point pos,
    required Move vector,
    required int savedArg,
  }) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
    return Player(
      playerImg: baseImages[StageObjType.player]!,
      errorImg: errorImg,
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
}
