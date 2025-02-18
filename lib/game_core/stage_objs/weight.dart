import 'dart:math';
import 'dart:ui';

import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/common.dart';
import 'package:push_and_merge/game_core/stage.dart';
import 'package:push_and_merge/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/widgets.dart' hide Image;

class Weight extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'weight.png';

  static const int weightMaxLevel = 5;

  /// オブジェクトのレベル->向き->アニメーションのマップ（staticにして唯一つ保持、メモリ節約）
  static Map<int, Map<Move, SpriteAnimation>> levelToAnimationsS = {};

  /// 各アニメーション等初期化。インスタンス作成前に1度だけ呼ぶこと
  static Future<void> onLoad({required Image errorImg}) async {
    final baseImg = await Flame.images.load(imageFileName);
    levelToAnimationsS = {
      0: {
        Move.none:
            SpriteAnimation.spriteList([Sprite(errorImg)], stepTime: 1.0),
      },
      for (int i = 1; i <= weightMaxLevel; i++)
        i: {
          Move.none: SpriteAnimation.spriteList([
            Sprite(baseImg, srcPosition: Vector2(0, 0), srcSize: Stage.cellSize)
          ], stepTime: 1.0)
        },
    };
  }

  final AlignComponent _weightViewComponent = AlignComponent(
    alignment: Anchor.center,
    child: TextComponent(
      priority: Stage.frontPriority,
      text: '',
      textRenderer: TextPaint(
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Config.gameTextFamily,
              color: Color(0xff000000))),
    ),
  );

  Weight({
    required super.savedArg,
    required Vector2? scale,
    required ScaleEffect scaleEffect,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.dynamicPriority,
            size: Stage.cellSize,
            scale: scale,
            anchor: Anchor.center,
            children: [scaleEffect],
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.weight,
            level: level,
          ),
        ) {
    super.animationComponent.add(_weightViewComponent);
  }

  @override
  void update(
    double dt,
    Move moveInput,
    World gameWorld,
    CameraComponent camera,
    Stage stage,
    bool playerStartMoving,
    bool playerEndMoving,
    Map<Point, Move> prohibitedPoints,
  ) {}

  int getWeight() => pow(2, (level - 1)).toInt();

  @override
  set level(int l) {
    super.level = l;
    (_weightViewComponent.child as TextComponent).text = '${getWeight()}';
  }

  @override
  bool get pushable => true;

  @override
  bool get stopping => false;

  @override
  bool get puttable => false;

  @override
  bool get playerMovable => true;

  @override
  bool get enemyMovable => false;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => weightMaxLevel;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => false;
}
