import 'dart:math';

import 'package:box_pusher/components/rounded_component.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;

class Barrierman extends StageObj {
  /// 各レベルに対応する動きのパターン
  static final Map<int, EnemyMovePattern> movePatterns = {
    1: EnemyMovePattern.followPlayer,
    2: EnemyMovePattern.followPlayer,
    3: EnemyMovePattern.followPlayer,
  };

  /// バリアの枠色
  Color get barrierBorderColor {
    switch (level) {
      case 1:
        return const Color(0xff000000);
      case 2:
        return const Color(0x307092BE);
      case 3:
        return const Color(0x30A349A4);
      default:
        return Colors.black;
    }
  }

  /// バリアの色
  Color get barrierColor {
    switch (level) {
      case 1:
        return const Color(0x307F7F7F);
      case 2:
        return const Color(0x3089B2E8);
      case 3:
        return const Color(0x30C8BFE7);
      default:
        return Colors.black;
    }
  }

  /// 各レベルごとの画像のファイル名
  static String get imageFileName => 'barrierman.png';

  /// バリア
  late final RoundedComponent barrierComponent;

  /// バリアを張る間隔
  static int barrierPeriod = 5;

  /// バリアが残るターン数
  static int barrierTurns = 3;

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
          Move.down: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1), 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 32, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.up: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 64, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 96, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.left: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 128, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 160, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
          Move.right: SpriteAnimation.spriteList([
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 192, 0),
                srcSize: Stage.cellSize),
            Sprite(baseImg,
                srcPosition: Vector2(256 * (i - 1) + 224, 0),
                srcSize: Stage.cellSize),
          ], stepTime: Stage.objectStepTime),
        },
    };
  }

  /// 経過ターン数
  int turns = 0;

  bool isFirstUpdate = true;

  Barrierman({
    required super.savedArg,
    required super.pos,
    int level = 1,
  }) : super(
          animationComponent: SpriteAnimationComponent(
            priority: Stage.movingPriority,
            size: Stage.cellSize,
            anchor: Anchor.center,
            position:
                (Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                    Stage.cellSize / 2),
          ),
          levelToAnimations: levelToAnimationsS,
          typeLevel: StageObjTypeLevel(
            type: StageObjType.barrierman,
            level: level,
          ),
        ) {
    barrierComponent = RoundedComponent(
      position: Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
          Stage.cellSize * 0.5,
      anchor: Anchor.center,
      size: Stage.cellSize * 5,
      priority: Stage.frontPriority,
      color: barrierColor,
      borderColor: barrierBorderColor,
      strokeWidth: 3.0,
      cornerRadius: 15.0,
    );
  }

  bool playerStartMovingFlag = false;

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
    if (isFirstUpdate) {
      // バリア展開中なら
      if (0 < turns &&
          turns < barrierTurns &&
          !gameWorld.contains(barrierComponent)) {
        barrierComponent.position =
            Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                Stage.cellSize * 0.5;
        gameWorld.add(barrierComponent);
      }
      isFirstUpdate = false;
    }
    // レベルアップに応じてバリアの色を変える
    barrierComponent.color = barrierColor;
    barrierComponent.borderColor = barrierBorderColor;

    if (playerStartMoving) {
      playerStartMovingFlag = true;
      // 移動/バリア展開を決定
      if (turns == 0) {
        // バリアを表示
        if (!gameWorld.contains(barrierComponent)) {
          barrierComponent.position =
              Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                  Stage.cellSize * 0.5;
          gameWorld.add(barrierComponent);
        }
      } else {
        final ret = super.enemyMove(
          movePatterns[level]!,
          vector,
          stage.player,
          stage,
          prohibitedPoints,
        );
        if (ret.containsKey('move')) {
          moving = ret['move'] as Move;
        }
        if (ret.containsKey('vector')) {
          vector = ret['vector'] as Move;
        }
      }
      if (forceMoving != Move.none) {
        moving = forceMoving;
        forceMoving = Move.none;
      }
      movingAmount = 0;
    }

    if (playerStartMovingFlag) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * Stage.playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      if (moving != Move.none) {
        // ※※※画像の移動ここから※※※
        // 移動中の場合は画素も考慮
        Vector2 offset = moving.vector * movingAmount;
        stage.setObjectPosition(this, offset: offset);
        // バリアも移動
        barrierComponent.position =
            Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y) +
                Stage.cellSize * 0.5 +
                offset;
        // ※※※画像の移動ここまで※※※
      }

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        ++turns;
        if (turns == barrierTurns) {
          // バリアを削除
          if (gameWorld.contains(barrierComponent)) {
            gameWorld.remove(barrierComponent);
          }
        }
        if (turns >= barrierPeriod) {
          turns = 0;
        }
        pos += moving.point;
        // 移動後に関する処理
        endMoving(stage, gameWorld);
        // バリアによるダメージカットを付与
        if (0 < turns && turns <= barrierTurns) {
          final range = PointRectRange(pos - Point(2, 2), pos + Point(2, 2));
          final targets = stage.enemies.where((e) => range.contains(e.pos));
          for (final target in targets) {
            target.cutDamage = max(target.cutDamage, level);
          }
        }
        // ゲームオーバー判定
        if (stage.player.pos == pos) {
          // 同じマスにいる場合はアーマー関係なくゲームオーバー
          stage.isGameover = true;
        }
        moving = Move.none;
        movingAmount = 0;
        pushings.clear();
        playerStartMovingFlag = false;
      }
    }
  }

  @override
  void onRemove(World gameWorld) {
    if (gameWorld.contains(barrierComponent)) {
      gameWorld.remove(barrierComponent);
    }
  }

  @override
  bool get pushable => false;

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
  int get maxLevel => 3;

  @override
  bool get isEnemy => true;

  @override
  bool get killable => true;

  @override
  bool get beltMove => true;

  @override
  bool get hasVector => true;

  @override
  int get coins => level * 2;

  // turnsの保存/読み込み
  @override
  int get arg => turns;

  @override
  void loadArg(int val) {
    turns = val;
  }
}
