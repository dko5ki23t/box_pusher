import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/archer.dart';
import 'package:box_pusher/game_core/stage_objs/belt.dart';
import 'package:box_pusher/game_core/stage_objs/bomb.dart';
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
import 'package:flame/components.dart' hide Block;
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;

class StageObjFactory {
  bool isReady = false;
  final Map<StageObjType, SpriteAnimation> stageSpriteAnimatinos;
  final Map<int, SpriteAnimation> breakingBlockAnimations;
  final SpriteAnimation explodingBombAnimation;
  late final Image jewelsImg;
  late final Map<int, SpriteAnimation> jewelLevelToAnimation;
  final Map<int, SpriteAnimation> blockLevelToAnimation;

  /// エラー画像アニメーション（該当アニメーションが無いとき等で使う）
  SpriteAnimation errorAnimation;

  /// 【ガーディアン】向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> guardianAnimation;

  /// 【ガーディアン】攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> guardianAttackAnimation;

  /// 【ガーディアン】攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> guardianAttackAnimationOffset;

  /// 【剣を持つ敵】向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> swordsmanAnimation;

  /// 【剣を持つ敵】攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> swordsmanAttackAnimation;

  /// 【剣を持つ敵】回転斬り攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> swordsmanRoundAttackAnimation;

  /// 【剣を持つ敵】攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> swordsmanAttackAnimationOffset;

  /// 【剣を持つ敵】回転斬り攻撃時アニメーションのオフセット
  final Vector2 swordsmanRoundAttackAnimationOffset;

  /// 【弓を持つ敵】向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> archerAnimation;

  /// 【弓を持つ敵】攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> archerAttackAnimation;

  /// 【弓を持つ敵】攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> archerAttackAnimationOffset;

  /// 【弓を持つ敵】矢のアニメーション
  final SpriteAnimation archerArrowAnimation;

  /// 【魔法使い】向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> wizardAnimation;

  /// 【魔法使い】攻撃時の向きに対応するアニメーション。上下左右のkeyが必須
  final Map<Move, SpriteAnimation> wizardAttackAnimation;

  /// 【魔法使い】攻撃時の向きに対応するアニメーションのオフセット。上下左右のkeyが必須
  final Map<Move, Vector2> wizardAttackAnimationOffset;

  /// 【魔法使い】矢のアニメーション
  final SpriteAnimation wizardMagicAnimation;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラ
  EffectController? baseMergable;

  /// effectを追加する際、動きを合わせる基となるエフェクトのコントローラが逆再生中かどうか
  bool isBaseMergableReverse = false;

  void setReverse() {
    isBaseMergableReverse = !isBaseMergableReverse;
  }

  StageObjFactory({
    required this.errorAnimation,
    required this.stageSpriteAnimatinos,
    required this.blockLevelToAnimation,
    required this.breakingBlockAnimations,
    required this.explodingBombAnimation,
    required this.guardianAnimation,
    required this.guardianAttackAnimation,
    required this.guardianAttackAnimationOffset,
    required this.swordsmanAnimation,
    required this.swordsmanAttackAnimation,
    required this.swordsmanAttackAnimationOffset,
    required this.swordsmanRoundAttackAnimation,
    required this.swordsmanRoundAttackAnimationOffset,
    required this.archerAnimation,
    required this.archerAttackAnimation,
    required this.archerAttackAnimationOffset,
    required this.archerArrowAnimation,
    required this.wizardAnimation,
    required this.wizardAttackAnimation,
    required this.wizardAttackAnimationOffset,
    required this.wizardMagicAnimation,
  });

  Future<void> onLoad() async {
    jewelsImg = await Flame.images.load(Jewel.imageFileName);
    jewelLevelToAnimation = Jewel.levelToAnimation(jewelsImg);
    isReady = true;
  }

  StageObj create({required StageObjTypeLevel typeLevel, required Point pos}) {
    assert(isReady, 'StageObjFactory.onLoad() is not called!');
    int priority = Stage.staticPriority;
    // TODO: mergableとかで判定
    double angle = 0;
    Move beltV = Move.up;
    switch (typeLevel.type) {
      case StageObjType.jewel:
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
      case StageObjType.block:
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
      scale: (typeLevel.type == StageObjType.jewel ||
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
        if (typeLevel.type == StageObjType.jewel ||
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
    if (typeLevel.type == StageObjType.jewel ||
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

    // TODO
    final levelToAnimation = typeLevel.type == StageObjType.jewel
        ? jewelLevelToAnimation
        : typeLevel.type == StageObjType.block
            ? blockLevelToAnimation
            : {0: errorAnimation, 1: animation.animation!};
    levelToAnimation[0] = errorAnimation;

    switch (typeLevel.type) {
      case StageObjType.none:
        return Floor(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.jewel:
        return Jewel(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.trap:
        return Trap(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.player:
        return Player(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.block:
        return Block(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation,
            breakingAnimations: breakingBlockAnimations);
      case StageObjType.spike:
        return Spike(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.drill:
        return Drill(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.treasureBox:
        return TreasureBox(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.warp:
        return Warp(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.bomb:
        return Bomb(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.beltL:
      case StageObjType.beltR:
      case StageObjType.beltU:
      case StageObjType.beltD:
        return Belt(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation,
            vector: beltV);
      case StageObjType.guardian:
        return Guardian(
            animationComponent: animation,
            vectorAnimation: guardianAnimation,
            attackAnimation: guardianAttackAnimation,
            levelToAnimations: levelToAnimation,
            attackAnimationOffset: guardianAttackAnimationOffset,
            pos: pos,
            level: typeLevel.level);
      case StageObjType.water:
        return Water(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.magma:
        return Magma(
            animationComponent: animation,
            pos: pos,
            level: typeLevel.level,
            levelToAnimations: levelToAnimation);
      case StageObjType.swordsman:
        return Swordsman(
          animationComponent: animation,
          vectorAnimation: swordsmanAnimation,
          attackAnimation: swordsmanAttackAnimation,
          attackAnimationOffset: swordsmanAttackAnimationOffset,
          roundAttackAnimation: swordsmanRoundAttackAnimation,
          roundAttackAnimationOffset: swordsmanRoundAttackAnimationOffset,
          levelToAnimations: levelToAnimation,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.archer:
        return Archer(
          animationComponent: animation,
          vectorAnimation: archerAnimation,
          attackAnimation: archerAttackAnimation,
          attackAnimationOffset: archerAttackAnimationOffset,
          arrowAnimation: archerArrowAnimation,
          levelToAnimations: levelToAnimation,
          pos: pos,
          level: typeLevel.level,
        );
      case StageObjType.wizard:
        return Wizard(
          animationComponent: animation,
          vectorAnimation: wizardAnimation,
          attackAnimation: wizardAttackAnimation,
          attackAnimationOffset: wizardAttackAnimationOffset,
          magicAnimation: wizardMagicAnimation,
          pos: pos,
          levelToAnimations: levelToAnimation,
          level: typeLevel.level,
        );
    }
  }

  StageObj createFromMap(Map<String, dynamic> src) {
    return create(
        typeLevel: StageObjTypeLevel.decode(src['typeLevel']),
        pos: Point.decode(src['pos']));
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
    obj.animationComponent.position =
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
            Stage.cellSize / 2 +
            pixel;
  }
}
