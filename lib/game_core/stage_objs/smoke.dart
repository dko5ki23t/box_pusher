import 'dart:math';

import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/game_core/stage_objs/player.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';

class Smoke extends StageObj {
  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'smoke.png';

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
      for (int i = 1; i <= 3; i++)
        i: {
          Move.none: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(320 * (i - 1), 0),
                srcSize: Vector2.all(160)),
            Sprite(baseImg,
                srcPosition: Vector2(320 * (i - 1) + 160, 0),
                srcSize: Vector2.all(160)),
          ], stepTime: Stage.objectStepTime),
        },
    };
  }

  /// 経過ターン
  int turns = 0;

  /// 消えるまでのターン数
  final int lastingTurns;

  /// 封じたプレイヤーの能力（煙から出たらリセットされる）
  List<PlayerAbility> forbidedAbility = [];

  Smoke({
    required super.savedArg,
    required this.lastingTurns,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.frontMovingPriority,
            size: Stage.cellSize * 5,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          )..add(OpacityEffect.to(0.9, EffectController(duration: 0))),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.smoke,
            level: level,
          ),
        ) {
    // 透明度変更
    animationComponent.add(OpacityEffect.to(
        max(0, 0.9 - 0.3 * turns), EffectController(duration: 0)));
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
  ) {
    // 移動し始めのフレームの場合
    if (playerStartMoving) {
      ++turns;
      if (turns >= lastingTurns) {
        // オブジェクト削除
        validAfterFrame = false;
      }
      // 透明度変更
      animationComponent.add(OpacityEffect.to(
          max(0, 0.9 - 0.3 * turns), EffectController(duration: 0)));
    }
    bool coverPlayer = PointRectRange(pos + Point(-2, -2), pos + Point(2, 2))
        .contains(stage.player.pos);
    if (coverPlayer) {
      // プレイヤーの能力を使用不可にする
      if (forbidedAbility.length < level) {
        int n = level - forbidedAbility.length;
        // プレイヤーが使用可能な能力のリスト作成
        final List<PlayerAbility> availables = [];
        for (final ability in PlayerAbility.values) {
          if (stage.player.isAbilityAvailable(ability)) {
            availables.add(ability);
          }
        }
        // 使用可能な能力がなければ何もしない
        if (availables.isEmpty) return;
        if (n >= availables.length) {
          forbidedAbility.addAll(availables);
        } else {
          // ランダムに選ぶ
          forbidedAbility.addAll(availables.sample(n));
        }
      }
      for (final ability in forbidedAbility) {
        stage.player.isAbilityForbidden[ability] = true;
      }
    } else {
      forbidedAbility.clear();
    }
  }

  @override
  bool get pushable => false;

  @override
  bool get stopping => false;

  @override
  bool get puttable => true;

  @override
  bool get playerMovable => true;

  @override
  bool get enemyMovable => true;

  @override
  bool get mergable => level < maxLevel;

  @override
  int get maxLevel => 3;

  @override
  bool get isEnemy => false;

  @override
  bool get killable => false;

  @override
  bool get beltMove => false;

  @override
  bool get hasVector => false;

  // Stage.get()の対象にならない(オブジェクトと重なってるのに敵の移動先にならないように)
  @override
  bool get isOverlay => true;

  // turnsの保存/読み込み
  @override
  int get arg => turns;

  @override
  void loadArg(int val) {
    turns = val;
  }
}
