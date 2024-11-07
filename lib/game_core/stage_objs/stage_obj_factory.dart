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
import 'package:box_pusher/game_core/stage_objs/magma.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:box_pusher/game_core/stage_objs/spike.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/swordsman.dart';
import 'package:box_pusher/game_core/stage_objs/trap.dart';
import 'package:box_pusher/game_core/stage_objs/treasure_box.dart';
import 'package:box_pusher/game_core/stage_objs/block.dart';
import 'package:box_pusher/game_core/stage_objs/warp.dart';
import 'package:box_pusher/game_core/stage_objs/water.dart';
import 'package:box_pusher/game_core/stage_objs/wizard.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class StageObjFactory {
  bool isReady = false;
  late final Image errorImg;
  late final Image jewelsImg;
  late final Image archersImg;
  late final Image attackArchersImg;
  late final Image arrowImg;
  late final Image beltImg;
  late final Image blockImg;
  late final Image drillImg;
  late final Image floorImg;
  late final Image bombImg;
  late final Image guardianImg;
  late final Image guardianAttackDImg;
  late final Image guardianAttackLImg;
  late final Image guardianAttackRImg;
  late final Image guardianAttackUImg;
  late final Image magmaImg;
  late final Image playerImg;
  late final Image spikeImg;
  late final Image swordsmanImg;
  late final Image swordsmanAttackDImg;
  late final Image swordsmanAttackLImg;
  late final Image swordsmanAttackRImg;
  late final Image swordsmanAttackUImg;
  late final Image swordsmanRoundAttackDImg;
  late final Image swordsmanRoundAttackLImg;
  late final Image swordsmanRoundAttackRImg;
  late final Image swordsmanRoundAttackUImg;
  late final Image trapImg;
  late final Image treasureBoxImg;
  late final Image warpImg;
  late final Image waterImg;
  late final Image wizardImg;
  late final Image attackWizardImg;
  late final Image magicImg;
  late final Image gorillaImg;

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
    jewelsImg = await Flame.images.load(Jewel.imageFileName);
    archersImg = await Flame.images.load(Archer.imageFileName);
    attackArchersImg = await Flame.images.load(Archer.attackImageFileName);
    arrowImg = await Flame.images.load(Archer.arrowImageFileName);
    beltImg = await Flame.images.load(Belt.imageFileName);
    blockImg = await Flame.images.load(Block.imageFileName);
    bombImg = await Flame.images.load(Bomb.imageFileName);
    drillImg = await Flame.images.load(Drill.imageFileName);
    floorImg = await Flame.images.load(Floor.imageFileName);
    guardianImg = await Flame.images.load(Guardian.imageFileName);
    guardianAttackDImg = await Flame.images.load(Guardian.attackDImageFileName);
    guardianAttackLImg = await Flame.images.load(Guardian.attackLImageFileName);
    guardianAttackRImg = await Flame.images.load(Guardian.attackRImageFileName);
    guardianAttackUImg = await Flame.images.load(Guardian.attackUImageFileName);
    magmaImg = await Flame.images.load(Magma.imageFileName);
    playerImg = await Flame.images.load(Player.imageFileName);
    spikeImg = await Flame.images.load(Spike.imageFileName);
    swordsmanImg = await Flame.images.load(Guardian.imageFileName);
    swordsmanAttackDImg =
        await Flame.images.load(Swordsman.attackDImageFileName);
    swordsmanAttackLImg =
        await Flame.images.load(Swordsman.attackLImageFileName);
    swordsmanAttackRImg =
        await Flame.images.load(Swordsman.attackRImageFileName);
    swordsmanAttackUImg =
        await Flame.images.load(Swordsman.attackUImageFileName);
    swordsmanRoundAttackDImg =
        await Flame.images.load(Swordsman.roundAttackDImageFileName);
    swordsmanRoundAttackLImg =
        await Flame.images.load(Swordsman.roundAttackLImageFileName);
    swordsmanRoundAttackRImg =
        await Flame.images.load(Swordsman.roundAttackRImageFileName);
    swordsmanRoundAttackUImg =
        await Flame.images.load(Swordsman.roundAttackUImageFileName);
    trapImg = await Flame.images.load(Trap.imageFileName);
    treasureBoxImg = await Flame.images.load(TreasureBox.imageFileName);
    warpImg = await Flame.images.load(Warp.imageFileName);
    waterImg = await Flame.images.load(Water.imageFileName);
    wizardImg = await Flame.images.load(Wizard.imageFileName);
    attackWizardImg = await Flame.images.load(Wizard.attackImageFileName);
    magicImg = await Flame.images.load(Wizard.magicImageFileName);
    gorillaImg = await Flame.images.load(Gorilla.imageFileName);
    isReady = true;
  }

  StageObj create({
    required StageObjTypeLevel typeLevel,
    required Point pos,
    Move vector = Move.down,
  }) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
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

    if (typeLevel.type == StageObjType.jewel ||
        typeLevel.type == StageObjType.trap ||
        typeLevel.type == StageObjType.drill ||
        typeLevel.type == StageObjType.bomb ||
        typeLevel.type == StageObjType.guardian) {
      final controller = scaleEffect.controller;
      baseMergable ??= controller;
      controller.advance((isBaseMergableReverse
              ? (1.0 - baseMergable!.progress)
              : baseMergable!.progress) *
          Stage.mergableZoomDuration);
    }

    switch (typeLevel.type) {
      case StageObjType.none:
        return Floor(
            floorImg: floorImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.jewel:
        return Jewel(
          jewelImg: jewelsImg,
          errorImg: errorImg,
          scale: scale,
          scaleEffect: scaleEffect,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.trap:
        return Trap(
            trapImg: trapImg,
            errorImg: errorImg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.player:
        return Player(
            playerImg: playerImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.block:
        return Block(
            blockImg: blockImg,
            pos: pos,
            level: typeLevel.level,
            errorImg: errorImg);
      case StageObjType.spike:
        return Spike(
            spikeImg: spikeImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.drill:
        return Drill(
            drillImg: drillImg,
            errorImg: errorImg,
            pos: pos,
            scale: scale,
            scaleEffect: scaleEffect,
            level: typeLevel.level);
      case StageObjType.treasureBox:
        return TreasureBox(
            treasureBoxImg: treasureBoxImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.warp:
        return Warp(
            warpImg: warpImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.bomb:
        return Bomb(
            bombImg: bombImg,
            errorImg: errorImg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.belt:
        return Belt(
            levelToAnimationImg: beltImg,
            pos: pos,
            level: typeLevel.level,
            errorImg: errorImg,
            vector: vector);
      case StageObjType.guardian:
        return Guardian(
            guardianImg: guardianImg,
            attackDImg: guardianAttackDImg,
            attackLImg: guardianAttackLImg,
            attackRImg: guardianAttackRImg,
            attackUImg: guardianAttackUImg,
            errorImg: errorImg,
            scale: scale,
            scaleEffect: scaleEffect,
            pos: pos,
            level: typeLevel.level)
          ..vector = vector;
      case StageObjType.water:
        return Water(
            waterImg: waterImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.magma:
        return Magma(
            magmaImg: magmaImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.swordsman:
        return Swordsman(
          swordsmanImg: swordsmanImg,
          attackDImg: swordsmanAttackDImg,
          attackLImg: swordsmanAttackLImg,
          attackRImg: swordsmanAttackRImg,
          attackUImg: swordsmanAttackUImg,
          roundAttackDImg: swordsmanRoundAttackDImg,
          roundAttackLImg: swordsmanRoundAttackLImg,
          roundAttackRImg: swordsmanRoundAttackRImg,
          roundAttackUImg: swordsmanRoundAttackUImg,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.archer:
        return Archer(
          levelToAnimationImg: archersImg,
          levelToAttackAnimationImg: attackArchersImg,
          arrowImg: arrowImg,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.wizard:
        return Wizard(
          wizardImg: wizardImg,
          attackImg: attackWizardImg,
          magicImg: magicImg,
          errorImg: errorImg,
          pos: pos,
          level: typeLevel.level,
        )..vector = vector;
      case StageObjType.gorilla:
        return Gorilla(
            gorillaImg: gorillaImg,
            errorImg: errorImg,
            pos: pos,
            level: typeLevel.level);
    }
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
      typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
      pos: Point.decode(src['pos']),
      vector: Move.values[src['vector']],
    );
  }

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.animationComponent.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }
}
