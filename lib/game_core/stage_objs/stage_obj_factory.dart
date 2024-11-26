import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
import 'package:box_pusher/game_core/stage_objs/gorilla.dart';
import 'package:box_pusher/game_core/stage_objs/jewel.dart';
import 'package:box_pusher/game_core/stage_objs/drill.dart';
import 'package:box_pusher/game_core/stage_objs/floor.dart';
import 'package:box_pusher/game_core/stage_objs/guardian.dart';
import 'package:box_pusher/game_core/stage_objs/kangaroo.dart';
import 'package:box_pusher/game_core/stage_objs/magma.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/rabbit.dart';
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
  late final Image attackArchersImg;
  late final Image arrowImg;
  late final List<Map<Move, Image>> guardianAttackImgs;
  late final List<Map<Move, Image>> swordsmanAttackImgs;
  late final List<Image> swordsmanRoundAttackImgs;
  late final Image attackWizardImg;
  late final Image magicImg;
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
    attackArchersImg = await Flame.images.load(Archer.attackImageFileName);
    arrowImg = await Flame.images.load(Archer.arrowImageFileName);
    guardianAttackImgs = [];
    for (final names in Guardian.attackImageFileNames) {
      Map<Move, Image> images = {};
      for (final entry in names.entries) {
        images[entry.key] = await Flame.images.load(entry.value);
      }
      guardianAttackImgs.add(images);
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
    attackWizardImg = await Flame.images.load(Wizard.attackImageFileName);
    magicImg = await Flame.images.load(Wizard.magicImageFileName);
    isReady = true;
  }

  StageObj create({
    required StageObjTypeLevel typeLevel,
    required Point pos,
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
            pos: pos,
            level: typeLevel.level);
      case StageObjType.jewel:
        return Jewel(
          jewelImg: baseImages[type]!,
          errorImg: errorImg,
          scale: scale,
          scaleEffect: scaleEffect,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.trap:
        return Trap(
            trapImg: baseImages[type]!,
            errorImg: errorImg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.player:
        assert(
            isReady, 'Playerはこの関数で作成せず、StageObjFactory.createPlayer()で作成すること。');
        return Player(
            playerImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.block:
        return Block(
            blockImg: baseImages[type]!,
            pos: pos,
            level: typeLevel.level,
            errorImg: errorImg);
      case StageObjType.spike:
        return Spike(
            spikeImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.drill:
        return Drill(
            drillImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            scale: scale,
            scaleEffect: scaleEffect,
            level: typeLevel.level);
      case StageObjType.treasureBox:
        return TreasureBox(
            treasureBoxImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.warp:
        return Warp(
            warpImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.bomb:
        return Bomb(
            bombImg: baseImages[type]!,
            errorImg: errorImg,
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
            vector: vector);
      case StageObjType.guardian:
        return Guardian(
            guardianImg: baseImages[type]!,
            attackImgs: guardianAttackImgs,
            errorImg: errorImg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.water:
        return Water(
            waterImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.magma:
        return Magma(
            magmaImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.swordsman:
        return Swordsman(
          swordsmanImg: baseImages[type]!,
          attackImgs: swordsmanAttackImgs,
          roundAttackImgs: swordsmanRoundAttackImgs,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.archer:
        return Archer(
          levelToAnimationImg: baseImages[type]!,
          levelToAttackAnimationImg: attackArchersImg,
          arrowImg: arrowImg,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.wizard:
        return Wizard(
          wizardImg: baseImages[type]!,
          attackImg: attackWizardImg,
          magicImg: magicImg,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.gorilla:
        return Gorilla(
            gorillaImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.rabbit:
        return Rabbit(
            rabbitImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.kangaroo:
        return Kangaroo(
            kangarooImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.turtle:
        return Turtle(
            turtleImg: baseImages[type]!,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
    }
  }

  Player createPlayer({
    required Point pos,
    required Move vector,
  }) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
    return Player(
      playerImg: baseImages[StageObjType.player]!,
      errorImg: errorImg,
      pos: pos,
    )..vector = vector;
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
      typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
      pos: Point.decode(src['pos']),
      vector: Move.values[src['vector']],
    );
  }

  Player createPlayerFromMap(Map<String, dynamic> src) {
    return createPlayer(
      pos: Point.decode(src['pos']),
      vector: Move.values[src['vector']],
    )
      ..pushableNum = src['handAbility']
      ..isLegAbilityOn = src['legAbility']
      ..isPocketAbilityOn = src['pocketAbility']
      ..pocketItem =
          src['pocketItem'] != null ? createFromMap(src['pocketItem']) : null;
  }

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.animationComponent.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }
}
