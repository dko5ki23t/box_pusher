import 'dart:math';

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/components/opacity_effect_text_component.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/components/button.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/game_core/stage.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

/// デバッグモードでのゲーム画面表示モード
enum DebugViewMode {
  /// 通常
  gamePlay,

  /// 出現床/ブロックの分布
  blockFloorMap,

  /// ブロック破壊時出現オブジェクトの分布
  objInBlockMap,
}

class GameSeq extends Sequence
    with TapCallbacks, KeyboardHandler, HasGameReference<BoxPusherGame> {
  /// 画面上部の余白
  static Vector2 get topPaddingSize => Vector2(360.0, 40.0);

  /// 画面上下の余白(上部はtopPaddingSizeに追加)
  static Vector2 get yPaddingSize => Vector2(360.0, 20.0);

  /// 画面左右の余白
  static Vector2 get xPaddingSize => Vector2(20.0, 640.0);

  /// 画面上下の操作ボタン領域(yPadding領域と重複。この領域下にはステージ描画もされる)
  static Vector2 get yButtonAreaSize => Vector2(360.0, 50.0);

  /// 画面上下の操作ボタン領域(xPadding領域と重複。この領域下にはステージ描画もされる。y方向サイズはあとで計算する)
  static Vector2 get xButtonAreaSize => Vector2(50.0, 560.0);

  static Vector2 get xButtonAreaReal => Vector2(xButtonAreaSize.x,
      640.0 - topPaddingSize.y - yButtonAreaSize.y * 2 - menuButtonAreaSize.y);

  /// プレイヤー操作ボタン領域2
  static Vector2 get xButtonAreaSize2 => Vector2(50.0, 50.0);

  /// 画面斜めの操作ボタン領域(xPadding領域と重複。この領域下にはステージ描画もされる。)
  static Vector2 get dButtonAreaSize => Vector2(300.0, 120.0);

  /// メニューボタン領域(各種能力ボタン、ステージ名、メニューボタンの領域含む)
  static Vector2 get menuButtonAreaSize => Vector2(360.0, 40.0);

  /// 手の能力ボタン領域
  static Vector2 get handAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// 足の能力ボタン領域
  static Vector2 get legAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// アーマー能力ボタン領域
  static Vector2 get armerAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// ポケット能力ボタン領域
  static Vector2 get pocketAbilityButtonAreaSize => Vector2(40.0, 40.0);

  /// 次マージ時出現アイテム領域
  static Vector2 get nextItemAreaSize => Vector2(150.0, 35.0);

  /// スコア領域
  static Vector2 get scoreAreaSize => Vector2(70.0, 35.0);

  /// コインのアイコン+コイン数領域
  static Vector2 get coinsAreaSize => Vector2(50.0, 35.0);

  /// 能力ボタン間の余白
  static double get paddingAbilityButtons => 10.0;

  /// メニューボタン領域
  static Vector2 get settingsButtonAreaSize => Vector2(40.0, 40.0);

  /// 【テストモード】現在位置表示領域
  static Vector2 get currentPosAreaSize => Vector2(40.0, 40.0);

  /// 【テストモード】現在の表示モード
  DebugViewMode viewMode = DebugViewMode.gamePlay;

  /// 【テストモード】現在の表示モード切り替えボタン領域
  static Vector2 get viewModeButtonAreaSize => Vector2(60.0, 30.0);

  /// ステージ領域
  static Vector2 get stageViewSize => Vector2(360.0 - xPaddingSize.x * 2,
      640.0 - menuButtonAreaSize.y - topPaddingSize.y - yPaddingSize.y * 2);

  /// 準備できたかどうか
  bool isReady = false;

  /// ステージオブジェクト
  late Stage stage;

  /// 斜めの操作ボタンを表示中か
  bool isDiagonalButtonMode = false;
  bool prevIsDiagonalButtonMode = false;

  /// 現在押されている移動ボタンの移動方向
  Move pushingMoveButton = Move.none;

  late final Image coinImg;
  late final Image playerControllArrowImg;
  late final Image handAbilityImg;
  late final Image legAbilityImg;
  late final Image armerAbilityImg;
  late final Image pocketAbilityImg;
  late final Image settingsImg;
  late final Image diagonalMoveImg;
  late final TextComponent currentPosText;
  late final TextComponent remainMergeCountText;
  late final SpriteAnimationComponent nextMergeItem;
  late final SpriteAnimationComponent nextMergeItem2;
  late final SpriteAnimationComponent nextMergeItem3;
  late final TextComponent scoreText;
  late final TextComponent coinNumText;
  late final ButtonComponent topGameInfoArea;
  ClipComponent? playerControllButtonsArea;
  ClipComponent? clipByDiagonalMoveButton;
  List<ButtonComponent>? playerStraightMoveButtons;
  late final ButtonComponent playerUpMoveButton;
  late final ButtonComponent playerDownMoveButton;
  late final ButtonComponent playerLeftMoveButton;
  late final ButtonComponent playerRightMoveButton;
  late final PositionComponent playerUpLeftMoveButton;
  late final PositionComponent playerUpRightMoveButton;
  late final PositionComponent playerDownLeftMoveButton;
  late final PositionComponent playerDownRightMoveButton;
  late final ButtonComponent playerControllDiagonalModeButton;
  List<PositionComponent>? playerDiagonalMoveButtons;
  late final RectangleComponent menuArea;
  late final GameSpriteOnOffButton handAbilityOnOffButton;
  late final GameSpriteOnOffButton legAbilityOnOffButton;
  late final GameSpriteOnOffButton armerAbilityOnOffButton;
  late final GameSpriteAnimationButton pocketAbilityButton;
  late final GameSpriteButton menuButton;
  late final GameTextButton viewModeButton;

  @override
  Future<void> onLoad() async {
    coinImg = await Flame.images.load('coin.png');
    playerControllArrowImg =
        await Flame.images.load('player_controll_arrow.png');
    handAbilityImg = await Flame.images.load('hand_ability.png');
    legAbilityImg = await Flame.images.load('leg_ability.png');
    armerAbilityImg = await Flame.images.load('armer_ability.png');
    pocketAbilityImg = await Flame.images.load('pocket_ability.png');
    settingsImg = await Flame.images.load('settings.png');
    diagonalMoveImg = await Flame.images.load('arrows_output.png');
    // ステージ作成
    stage = Stage(testMode: game.testMode, gameWorld: game.world);
    await stage.onLoad();
    // 画面コンポーネント作成
    _createComponents();
    // 画面コンポーネント初期化
    initialize(true);
  }

  @override
  void onFocus(String? before) {
    if (isReady) {
      if (before == 'menu') {
        // BGM再開
        Audio().resumeBGM();
      } else {
        // BGMを最初から再生
        Audio().playBGM(Bgm.game);
      }
      updatePlayerControllButtons();
    }
  }

  @override
  void onUnFocus() {
    // BGM中断
    Audio().pauseBGM();
  }

  @override
  void onRemove() {
    // BGM停止
    Audio().stopBGM();
  }

  /// 画面コンポーネント作成
  void _createComponents() {
    // 画面上部、ボタンではない領域
    // 次アイテム出現までのマージ回数
    remainMergeCountText = TextComponent(
      text: "NEXT: ${stage.remainMergeCount}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Color(0xffffffff),
        ),
      ),
    );
    // 次マージ時出現アイテム
    final a = stage.getNextMergeItemSpriteAnimations();
    nextMergeItem = SpriteAnimationComponent(
        scale: Vector2.all(0.8),
        size: Vector2.all(32),
        animation: a.isNotEmpty ? a.first : null);
    nextMergeItem2 = SpriteAnimationComponent(
        scale: Vector2.all(0.8),
        size: Vector2.all(32),
        animation: a.length > 1 ? a[1] : null);
    nextMergeItem3 = SpriteAnimationComponent(
        scale: Vector2.all(0.8),
        size: Vector2.all(32),
        animation: a.length > 2 ? a[2] : null);
    // スコア
    scoreText = TextComponent(
      text: "${stage.scoreVisual}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Color(0xffffffff),
        ),
      ),
    );
    // コイン数
    coinNumText = TextComponent(
      text: "${stage.coinNum}",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Color(0xffffffff),
        ),
      ),
    );
    // プレイヤーの操作ボタン群
    final clipSize = Vector2(
        yButtonAreaSize.x, 640.0 - topPaddingSize.y - menuButtonAreaSize.y);
    final tv = Vector2(0.3, 0.3 * 9 / 16);
    playerControllButtonsArea ??= ClipComponent.rectangle(
      position: Vector2(0, topPaddingSize.y),
      size: clipSize,
    );
    // 上下左右の移動ボタン
    // 画面上の操作ボタン
    playerUpMoveButton = playerControllButton(
      size: yButtonAreaSize,
      position: Vector2(0, 0),
      arrowAngle: 0.0,
      move: Move.up,
    );
    // 画面下の操作ボタン
    playerDownMoveButton = playerControllButton(
      size: yButtonAreaSize,
      position: Vector2(0,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - yButtonAreaSize.y),
      arrowAngle: pi,
      move: Move.down,
    );
    // 画面左の操作ボタン
    playerLeftMoveButton = playerControllButton(
      size: xButtonAreaReal,
      position: Vector2(0, yButtonAreaSize.y),
      arrowAngle: -0.5 * pi,
      move: Move.left,
    );
    // 画面右の操作ボタン
    playerRightMoveButton = playerControllButton(
      size: xButtonAreaReal,
      position: Vector2(360.0 - xButtonAreaSize.x, yButtonAreaSize.y),
      arrowAngle: 0.5 * pi,
      move: Move.right,
    );
    // 斜め移動操作切り替えボタン
    playerControllDiagonalModeButton = ButtonComponent(
      onReleased: () {
        isDiagonalButtonMode = !isDiagonalButtonMode;
      },
      size: xButtonAreaSize2,
      anchor: Anchor.center,
      position: Vector2(
          (360.0 - xButtonAreaSize2.x) / 2 - xButtonAreaSize2.x * 2,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - xButtonAreaSize2.y),
      button: CircleComponent(
        radius: xButtonAreaSize2.x / 2,
        paint: Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(diagonalMoveImg),
              size: Vector2(24.0, 24.0),
              anchor: Anchor.center,
            ),
          ),
        ],
      ),
      buttonDown: CircleComponent(
        radius: xButtonAreaSize2.x / 2,
        paint: Paint()
          ..color = const Color(0xC0000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(diagonalMoveImg),
              size: Vector2(16.0, 16.0),
              anchor: Anchor.center,
            ),
          ),
        ],
      ),
    );
    playerStraightMoveButtons ??= [
      playerUpMoveButton,
      playerDownMoveButton,
      playerLeftMoveButton,
      playerRightMoveButton,
    ];
    // 画面左上の操作ボタン
    playerUpLeftMoveButton = Config().wideDiagonalMoveButton
        ? ClipComponent.polygon(
            points: [
              Vector2(0, 0),
              Vector2(tv.x, 0),
              Vector2(0, tv.y),
              Vector2(0, 0),
            ],
            size: clipSize,
            children: [
              playerControllButton(
                size: dButtonAreaSize,
                position:
                    Vector2(xButtonAreaSize.x * 0.5, yButtonAreaSize.y * 0.5),
                anchor: Anchor.center,
                angle: -0.25 * pi,
                move: Move.upLeft,
              ),
            ],
          )
        : playerControllButton(
            size: Vector2(xButtonAreaSize.x, yButtonAreaSize.y),
            position: Vector2(0, 0),
            arrowAngle: -0.25 * pi,
            move: Move.upLeft,
          );
    // 画面右上の操作ボタン
    playerUpRightMoveButton = Config().wideDiagonalMoveButton
        ? ClipComponent.polygon(
            points: [
              Vector2(1, 0),
              Vector2(1 - tv.x, 0),
              Vector2(1, tv.y),
              Vector2(1, 0),
            ],
            size: clipSize,
            children: [
              playerControllButton(
                size: dButtonAreaSize,
                position: Vector2(clipSize.x - xButtonAreaSize.x * 0.5,
                    yButtonAreaSize.y * 0.5),
                anchor: Anchor.center,
                angle: 0.25 * pi,
                move: Move.upRight,
              ),
            ],
          )
        : playerControllButton(
            size: Vector2(xButtonAreaSize.x, yButtonAreaSize.y),
            position: Vector2(360.0 - xButtonAreaSize.x, 0),
            arrowAngle: 0.25 * pi,
            move: Move.upRight,
          );
    // 画面左下の操作ボタン
    playerDownLeftMoveButton = Config().wideDiagonalMoveButton
        ? ClipComponent.polygon(
            points: [
              Vector2(0, 1 - tv.y),
              Vector2(tv.x, 1),
              Vector2(0, 1),
              Vector2(0, 1 - tv.y),
            ],
            size: clipSize,
            children: [
              playerControllButton(
                size: dButtonAreaSize,
                position: Vector2(xButtonAreaSize.x * 0.5,
                    clipSize.y - yButtonAreaSize.y * 0.5),
                anchor: Anchor.center,
                angle: -0.75 * pi,
                move: Move.downLeft,
              ),
            ],
          )
        : playerControllButton(
            size: Vector2(xButtonAreaSize.x, yButtonAreaSize.y),
            position: Vector2(
                0,
                640.0 -
                    topPaddingSize.y -
                    menuButtonAreaSize.y -
                    yButtonAreaSize.y),
            arrowAngle: -0.75 * pi,
            move: Move.downLeft,
          );
    // 画面右下の操作ボタン
    playerDownRightMoveButton = Config().wideDiagonalMoveButton
        ? ClipComponent.polygon(
            points: [
              Vector2(1, 1 - tv.y),
              Vector2(1, 1),
              Vector2(1 - tv.x, 1),
              Vector2(1, 1 - tv.y),
            ],
            size: clipSize,
            children: [
              playerControllButton(
                size: dButtonAreaSize,
                position: Vector2(clipSize.x - xButtonAreaSize.x * 0.5,
                    clipSize.y - yButtonAreaSize.y * 0.5),
                anchor: Anchor.center,
                angle: 0.75 * pi,
                move: Move.downRight,
              ),
            ],
          )
        : playerControllButton(
            size: Vector2(xButtonAreaSize.x, yButtonAreaSize.y),
            position: Vector2(
                360.0 - xButtonAreaSize.x,
                640.0 -
                    topPaddingSize.y -
                    menuButtonAreaSize.y -
                    yButtonAreaSize.y),
            arrowAngle: 0.75 * pi,
            move: Move.downRight,
          );
    // 斜めの移動ボタン
    playerDiagonalMoveButtons ??= [
      playerUpLeftMoveButton,
      playerUpRightMoveButton,
      playerDownLeftMoveButton,
      playerDownRightMoveButton,
    ];
    // 上下左右の操作ボタン領域(斜めボタンの領域は削る)
    clipByDiagonalMoveButton ??= ClipComponent.polygon(
      points: [
        Vector2(tv.x, 0),
        Vector2(1 - tv.x, 0),
        Vector2(1, tv.y),
        Vector2(1, 1 - tv.y),
        Vector2(1 - tv.x, 1),
        Vector2(tv.x, 1),
        Vector2(0, 1 - tv.y),
        Vector2(0, tv.y),
        Vector2(tv.x, 0),
      ],
      size: clipSize,
    );

    topGameInfoArea = ButtonComponent(
      button: RectangleComponent(
        size: topPaddingSize,
        paint: Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.fill,
        children: [
          // 次マージ時出現アイテム（左側に配置）
          AlignComponent(
            alignment: Anchor.bottomLeft,
            child: PositionComponent(
              size: nextItemAreaSize,
              children: [
                AlignComponent(
                  alignment: Anchor.centerLeft,
                  child: remainMergeCountText,
                ),
                AlignComponent(
                  alignment: Anchor.centerRight,
                  child: PositionComponent(
                    size: Vector2(Stage.cellSize.x * 3, Stage.cellSize.y) * 0.8,
                    children: [
                      AlignComponent(
                        alignment: Anchor.centerLeft,
                        child: nextMergeItem,
                      ),
                      AlignComponent(
                        alignment: Anchor.center,
                        child: nextMergeItem2,
                      ),
                      AlignComponent(
                        alignment: Anchor.centerRight,
                        child: nextMergeItem3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // スコア（中央に配置）
          AlignComponent(
            alignment: Anchor.bottomCenter,
            child: PositionComponent(
              size: scoreAreaSize,
              children: [
                AlignComponent(
                  alignment: Anchor.center,
                  child: scoreText,
                )
              ],
            ),
          ),
          // コイン（右側に配置）
          AlignComponent(
            alignment: Anchor.bottomRight,
            child: PositionComponent(
              size: coinsAreaSize,
              children: [
                AlignComponent(
                    alignment: Anchor.centerLeft,
                    child: SpriteComponent.fromImage(coinImg)),
                AlignComponent(
                  alignment: Anchor.centerRight,
                  child: coinNumText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    menuArea = RectangleComponent(
      size: menuButtonAreaSize,
      position: Vector2(0, 640.0 - menuButtonAreaSize.y),
      paint: Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      children: [
        RectangleComponent(
          size: menuButtonAreaSize,
          paint: Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        ),
      ],
    );
    Vector2 abilityButtonPos =
        Vector2(xPaddingSize.x, 640.0 - menuButtonAreaSize.y);
    // 手の能力ボタン領域
    handAbilityOnOffButton = GameSpriteOnOffButton(
      onChanged:
          game.testMode ? (bool isOn) => stage.setHandAbility(isOn) : null,
      size: handAbilityButtonAreaSize,
      position: abilityButtonPos,
      sprite: Sprite(handAbilityImg),
    );
    // 足の能力ボタン領域
    abilityButtonPos +=
        Vector2(handAbilityButtonAreaSize.x + paddingAbilityButtons, 0);
    legAbilityOnOffButton = GameSpriteOnOffButton(
      onChanged: game.testMode
          ? (bool isOn) {
              stage.setLegAbility(isOn);
              updatePlayerControllButtons();
            }
          : null,
      size: legAbilityButtonAreaSize,
      position: abilityButtonPos,
      sprite: Sprite(legAbilityImg),
    );
    // アーマー能力ボタン領域
    abilityButtonPos +=
        Vector2(legAbilityButtonAreaSize.x + paddingAbilityButtons, 0);
    armerAbilityOnOffButton = GameSpriteOnOffButton(
      onChanged:
          game.testMode ? (bool isOn) => stage.setArmerAbility(isOn) : null,
      size: armerAbilityButtonAreaSize,
      position: abilityButtonPos,
      sprite: Sprite(armerAbilityImg,
          srcPosition: Vector2.zero(), srcSize: Vector2.all(32)),
    );
    // ポケット能力ボタン領域
    abilityButtonPos +=
        Vector2(armerAbilityButtonAreaSize.x + paddingAbilityButtons, 0);
    pocketAbilityButton = GameSpriteAnimationButton(
      onReleased: () => stage.usePocketAbility(game.world),
      size: pocketAbilityButtonAreaSize,
      position: abilityButtonPos,
      animation:
          SpriteAnimation.spriteList([Sprite(pocketAbilityImg)], stepTime: 1.0),
    );
    // メニューボタン領域
    menuButton = GameSpriteButton(
      size: settingsButtonAreaSize,
      position: Vector2(360.0 - xPaddingSize.x - settingsButtonAreaSize.x,
          640.0 - menuButtonAreaSize.y),
      sprite: Sprite(settingsImg),
      onReleased: () => game.pushSeqNamed("menu"),
    );
    if (game.testMode) {
      // 【テストモード時】現在座標表示領域
      currentPosText = TextComponent(
        size: currentPosAreaSize,
        position: Vector2(0, yPaddingSize.y),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: Config.gameTextFamily,
            color: Color(0xffffffff),
          ),
        ),
      );
      // 【テストモード】現在の表示モード切り替えボタン
      viewModeButton = GameTextButton(
        size: viewModeButtonAreaSize,
        position: Vector2(360.0 - viewModeButtonAreaSize.x, yPaddingSize.y),
        text: viewMode.name,
        onReleased: () {
          viewMode = DebugViewMode
              .values[(viewMode.index + 1) % DebugViewMode.values.length];
          switch (viewMode) {
            case DebugViewMode.gamePlay:
              //game.world.removeAll(stage.blockFloorMapView);
              game.world.removeAll(stage.objInBlockMapView);
              break;
            case DebugViewMode.blockFloorMap:
              //game.world.removeAll(stage.objInBlockMapView);
              game.world.addAll(stage.blockFloorMapView);
              break;
            case DebugViewMode.objInBlockMap:
              game.world.removeAll(stage.blockFloorMapView);
              game.world.addAll(stage.objInBlockMapView);
              break;
          }
        },
      );
    }
  }

  // 初期化（というよりリセット）
  void initialize(bool t) {
    // 準備中にする
    isReady = false;
    removeAll(children);
    game.world.removeAll(game.world.children);
    // デバッグモードのときはステージの最大幅・高さを指定する
    if (game.testMode) {
      stage.stageMaxLT = Point(-(Config().debugStageWidth / 2).ceil(),
          -(Config().debugStageHeight / 2).ceil());
      stage.stageMaxRB = Point((Config().debugStageWidth / 2).ceil(),
          (Config().debugStageHeight / 2).ceil());
    }
    stage.initialize(game.camera, game.stageData, t);

    // プレイヤー操作ボタン領域
    add(playerControllButtonsArea!);
    // 画面上部ゲーム情報領域
    add(topGameInfoArea);
    // メニュー領域
    add(menuArea);
    // 手の能力ボタン領域
    add(handAbilityOnOffButton);
    // 足の能力ボタン領域
    add(legAbilityOnOffButton);
    // アーマー能力ボタン領域
    add(armerAbilityOnOffButton);
    // ポケット能力ボタン領域
    add(pocketAbilityButton);
    // メニューボタン領域
    add(menuButton);
    if (game.testMode) {
      // 【テストモード時】現在座標表示領域
      add(currentPosText);
      // 【テストモード】現在の表示モード切り替えボタン
      add(viewModeButton);
    }

    // 準備完了
    isReady = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // ゲームシーケンスでない場合は何もしない
    if (game.getCurrentSeqName() != 'game') return;
    // クリア済みなら何もしない
    if (stage.isClear()) return;
    // ゲームオーバー済みなら何もしない
    if (stage.isGameover) return;
    bool beforeLegAbility = stage.getLegAbility();
    stage.update(dt, pushingMoveButton, game.world, game.camera);
    // 手の能力取得状況更新
    handAbilityOnOffButton.isOn = stage.getHandAbility();
    // 足の能力取得状況更新
    legAbilityOnOffButton.isOn = stage.getLegAbility();
    if (beforeLegAbility != stage.getLegAbility() ||
        prevIsDiagonalButtonMode != isDiagonalButtonMode) {
      updatePlayerControllButtons();
    }
    prevIsDiagonalButtonMode = isDiagonalButtonMode;
    // アーマーの能力状況更新
    armerAbilityOnOffButton.isOn = stage.getArmerAbility();
    armerAbilityOnOffButton.sprite = Sprite(armerAbilityImg,
        srcPosition: Vector2(stage.getArmerAbilityRecoveryTurns() * 32, 0),
        srcSize: Vector2.all(32));
    // ポケットの能力状況更新
    final pocketItemAnimation = stage.getPocketAbilitySpriteAnimation() ??
        SpriteAnimation.spriteList([Sprite(pocketAbilityImg)], stepTime: 1.0);
    pocketAbilityButton.animation = pocketItemAnimation;
    pocketAbilityButton.enabled = stage.getPocketAbility();
    // 次アイテム出現までのマージ回数更新
    remainMergeCountText.text = "NEXT: ${stage.remainMergeCount}";
    // 次マージ時出現アイテム更新
    final a = stage.getNextMergeItemSpriteAnimations();
    nextMergeItem.animation = a.isNotEmpty ? a.first : null;
    nextMergeItem2.animation = a.length > 1 ? a[1] : null;
    nextMergeItem3.animation = a.length > 2 ? a[2] : null;
    // スコア表示更新
    scoreText.text = "${stage.scoreVisual}";
    // スコア加算表示
    int addedScore = stage.addedScore;
    if (addedScore > 0 && Config().showAddedScoreOnScore) {
      final addingScoreText = OpacityEffectTextComponent(
        text: "+$addedScore",
        textRenderer: TextPaint(
          style: Config.gameTextStyle,
        ),
      );
      add(RectangleComponent(
        size: menuButtonAreaSize,
        position: Vector2(0, 640.0 - menuButtonAreaSize.y),
        paint: Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill,
        children: [
          RectangleComponent(
            size: menuButtonAreaSize,
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
                Vector2(0, -10.0),
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
    // コイン数表示更新
    coinNumText.text = "${stage.coinNum}";
    // 【テストモード】現在座標表示
    if (game.testMode) {
      currentPosText.text = "pos:(${stage.player.pos.x},${stage.player.pos.y})";
    }
    // 【テストモード】表示モード切り替えボタン更新
    if (game.testMode) {
      viewModeButton.text = viewMode.name;
    }
    // 今回のupdateでクリアしたらクリア画面に移行
    if (stage.isClear()) {
      game.pushSeqNamed('clear');
    }
    // 今回のupdateでゲームオーバーになったらゲームオーバー画面に移行
    if (stage.isGameover) {
      // ハイスコア更新
      if (stage.score > game.highScore) {
        game.setAndSaveHighScore(stage.score);
      }
      // BGMストップ
      Audio().stopBGM();
      // ゲームオーバーシーケンスへ
      game.pushSeqNamed('gameover');
    }
  }

  ButtonComponent playerControllButton({
    required Vector2 size,
    Vector2? position,
    Anchor? anchor,
    double? angle,
    double? arrowAngle,
    required Move move,
  }) {
    return ButtonComponent(
      onPressed: () {
        if (pushingMoveButton == Move.none) {
          pushingMoveButton = move;
        }
      },
      onReleased: () {
        if (pushingMoveButton == move) {
          pushingMoveButton = Move.none;
        }
      },
      onCancelled: () {
        if (pushingMoveButton == move) {
          pushingMoveButton = Move.none;
        }
      },
      size: size,
      anchor: anchor,
      angle: angle,
      position: position,
      button: RectangleComponent(
        size: size,
        paint: Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(playerControllArrowImg),
              size: Vector2(24.0, 24.0),
              anchor: Anchor.center,
              angle: arrowAngle,
            ),
          ),
        ],
      ),
      buttonDown: RectangleComponent(
        size: size,
        paint: Paint()
          ..color = const Color(0xC0000000)
          ..style = PaintingStyle.fill,
        children: [
          AlignComponent(
            alignment: Anchor.center,
            child: SpriteComponent(
              sprite: Sprite(playerControllArrowImg),
              size: Vector2(24.0, 24.0),
              anchor: Anchor.center,
              angle: arrowAngle,
            ),
          ),
        ],
      ),
    );
  }

  void updatePlayerControllButtons() {
    playerControllButtonsArea!.removeAll(playerControllButtonsArea!.children);
    if (Config().playerControllButtonType == 0) {
      playerUpMoveButton.size = yButtonAreaSize;
      playerUpMoveButton.button?.size = yButtonAreaSize;
      playerUpMoveButton.buttonDown?.size = yButtonAreaSize;
      playerUpMoveButton.position = Vector2.all(0);
      playerDownMoveButton.size = yButtonAreaSize;
      playerDownMoveButton.button?.size = yButtonAreaSize;
      playerDownMoveButton.buttonDown?.size = yButtonAreaSize;
      playerDownMoveButton.position = Vector2(0,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - yButtonAreaSize.y);
      playerLeftMoveButton.size = xButtonAreaReal;
      playerLeftMoveButton.button?.size = xButtonAreaReal;
      playerLeftMoveButton.buttonDown?.size = xButtonAreaReal;
      playerLeftMoveButton.position = Vector2(0, yButtonAreaSize.y);
      playerRightMoveButton.size = xButtonAreaReal;
      playerRightMoveButton.button?.size = xButtonAreaReal;
      playerRightMoveButton.buttonDown?.size = xButtonAreaReal;
      playerRightMoveButton.position =
          Vector2(360.0 - xButtonAreaSize.x, yButtonAreaSize.y);
      if (Config().wideDiagonalMoveButton) {
        /*
        playerUpLeftMoveButton.size = yButtonAreaSize;
        playerUpLeftMoveButton.button?.size = yButtonAreaSize;
        playerUpLeftMoveButton.buttonDown?.size = yButtonAreaSize;
        playerUpLeftMoveButton.position = Vector2.all(0);
        playerDownMoveButton.size = yButtonAreaSize;
        playerDownMoveButton.button?.size = yButtonAreaSize;
        playerDownMoveButton.buttonDown?.size = yButtonAreaSize;
        playerDownMoveButton.position = Vector2(
            0,
            640.0 -
                topPaddingSize.y -
                menuButtonAreaSize.y -
                yButtonAreaSize.y);
        playerLeftMoveButton.size = xButtonAreaReal;
        playerLeftMoveButton.button?.size = xButtonAreaReal;
        playerLeftMoveButton.buttonDown?.size = xButtonAreaReal;
        playerLeftMoveButton.position = Vector2(0, yButtonAreaSize.y);
        playerRightMoveButton.size = xButtonAreaReal;
        playerRightMoveButton.button?.size = xButtonAreaReal;
        playerRightMoveButton.buttonDown?.size = xButtonAreaReal;
        playerRightMoveButton.position =
            Vector2(360.0 - xButtonAreaSize.x, yButtonAreaSize.y);
        */
      } else {
        playerUpLeftMoveButton.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerUpLeftMoveButton as ButtonComponent).button?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerUpLeftMoveButton as ButtonComponent).buttonDown?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        playerUpLeftMoveButton.position = Vector2.all(0);
        playerUpRightMoveButton.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerUpRightMoveButton as ButtonComponent).button?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerUpRightMoveButton as ButtonComponent).buttonDown?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        playerUpRightMoveButton.position =
            Vector2(360.0 - xButtonAreaSize.x, 0);
        playerDownLeftMoveButton.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerDownLeftMoveButton as ButtonComponent).button?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerDownLeftMoveButton as ButtonComponent).buttonDown?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        playerDownLeftMoveButton.position = Vector2(
            0,
            640.0 -
                topPaddingSize.y -
                menuButtonAreaSize.y -
                yButtonAreaSize.y);
        playerDownRightMoveButton.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerDownRightMoveButton as ButtonComponent).button?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        (playerDownRightMoveButton as ButtonComponent).buttonDown?.size =
            Vector2(xButtonAreaSize.x, yButtonAreaSize.y);
        playerDownRightMoveButton.position = Vector2(
            360.0 - xButtonAreaSize.x,
            640.0 -
                topPaddingSize.y -
                menuButtonAreaSize.y -
                yButtonAreaSize.y);
      }
      if (stage.getLegAbility()) {
        if (Config().wideDiagonalMoveButton) {
          clipByDiagonalMoveButton!.addAll(playerStraightMoveButtons!);
          playerControllButtonsArea!.add(clipByDiagonalMoveButton!);
          playerControllButtonsArea!.addAll(playerDiagonalMoveButtons!);
        } else {
          playerControllButtonsArea!.addAll(playerStraightMoveButtons!);
          playerControllButtonsArea!.addAll(playerDiagonalMoveButtons!);
        }
      } else {
        playerControllButtonsArea!.addAll(playerStraightMoveButtons!);
      }
    } else if (Config().playerControllButtonType == 1) {
      playerUpMoveButton.size = xButtonAreaSize2;
      playerUpMoveButton.button?.size = xButtonAreaSize2;
      playerUpMoveButton.buttonDown?.size = xButtonAreaSize2;
      playerUpMoveButton.position = Vector2(
          (360.0 - xButtonAreaSize2.x) / 2,
          640.0 -
              topPaddingSize.y -
              menuButtonAreaSize.y -
              xButtonAreaSize2.y * 2);
      playerDownMoveButton.size = xButtonAreaSize2;
      playerDownMoveButton.button?.size = xButtonAreaSize2;
      playerDownMoveButton.buttonDown?.size = xButtonAreaSize2;
      playerDownMoveButton.position = Vector2((360.0 - xButtonAreaSize2.x) / 2,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - xButtonAreaSize2.y);
      playerLeftMoveButton.size = xButtonAreaSize2;
      playerLeftMoveButton.button?.size = xButtonAreaSize2;
      playerLeftMoveButton.buttonDown?.size = xButtonAreaSize2;
      playerLeftMoveButton.position = Vector2(
          (360.0 - xButtonAreaSize2.x) / 2 - xButtonAreaSize2.x,
          640.0 -
              topPaddingSize.y -
              menuButtonAreaSize.y -
              xButtonAreaSize2.y * 1.5);
      playerRightMoveButton.size = xButtonAreaSize2;
      playerRightMoveButton.button?.size = xButtonAreaSize2;
      playerRightMoveButton.buttonDown?.size = xButtonAreaSize2;
      playerRightMoveButton.position = Vector2(
          (360.0 - xButtonAreaSize2.x) / 2 + xButtonAreaSize2.x,
          640.0 -
              topPaddingSize.y -
              menuButtonAreaSize.y -
              xButtonAreaSize2.y * 1.5);
      playerUpLeftMoveButton.size = xButtonAreaSize2;
      (playerUpLeftMoveButton as ButtonComponent).button?.size =
          xButtonAreaSize2;
      (playerUpLeftMoveButton as ButtonComponent).buttonDown?.size =
          xButtonAreaSize2;
      playerUpLeftMoveButton.position = Vector2(
          180 - xButtonAreaSize2.x,
          640.0 -
              topPaddingSize.y -
              menuButtonAreaSize.y -
              xButtonAreaSize2.y * 2);
      playerUpRightMoveButton.size = xButtonAreaSize2;
      (playerUpRightMoveButton as ButtonComponent).button?.size =
          xButtonAreaSize2;
      (playerUpRightMoveButton as ButtonComponent).buttonDown?.size =
          xButtonAreaSize2;
      playerUpRightMoveButton.position = Vector2(
          180,
          640.0 -
              topPaddingSize.y -
              menuButtonAreaSize.y -
              xButtonAreaSize2.y * 2);
      playerDownLeftMoveButton.size = xButtonAreaSize2;
      (playerDownLeftMoveButton as ButtonComponent).button?.size =
          xButtonAreaSize2;
      (playerDownLeftMoveButton as ButtonComponent).buttonDown?.size =
          xButtonAreaSize2;
      playerDownLeftMoveButton.position = Vector2(180 - xButtonAreaSize2.x,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - xButtonAreaSize2.y);
      playerDownRightMoveButton.size = xButtonAreaSize2;
      (playerDownRightMoveButton as ButtonComponent).button?.size =
          xButtonAreaSize2;
      (playerDownRightMoveButton as ButtonComponent).buttonDown?.size =
          xButtonAreaSize2;
      playerDownRightMoveButton.position = Vector2(180,
          640.0 - topPaddingSize.y - menuButtonAreaSize.y - xButtonAreaSize2.y);
      if (stage.getLegAbility()) {
        playerControllButtonsArea!.add(playerControllDiagonalModeButton);
      }
      if (stage.getLegAbility() && isDiagonalButtonMode) {
        playerControllButtonsArea!.addAll(playerDiagonalMoveButtons!);
      } else {
        playerControllButtonsArea!.addAll(playerStraightMoveButtons!);
      }
    }
  }

  // TapCallbacks実装時には必要(PositionComponentでは不要)
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) async {
    super.onTapUp(event);
    if (game.testMode) {
      final cameraPos =
          game.camera.globalToLocal(event.canvasPosition) / Stage.cellSize.x;
      final Point stagePos = Point(cameraPos.x.floor(), cameraPos.y.floor());
      switch (viewMode) {
        case DebugViewMode.gamePlay:
          // テストモード時のみ、ブロックをタップで破壊
          final tapObject = stage.get(stagePos);
          if (tapObject.type == StageObjType.block) {
            stage.breakBlocks(
                stagePos, (block) => true, PointDistanceRange(stagePos, 0));
          }
          break;
        case DebugViewMode.blockFloorMap:
        case DebugViewMode.objInBlockMap:
          game.debugTargetPos = stagePos;
          game.debugBlockFloorDistribution =
              stage.blockFloorDistribution.values.last;
          for (final range in stage.blockFloorDistribution.keys) {
            if (range.contains(stagePos)) {
              game.debugBlockFloorDistribution =
                  stage.blockFloorDistribution[range]!;
              break;
            }
          }
          game.debugObjInBlockDistribution =
              stage.objInBlockDistribution.values.last;
          for (final range in stage.objInBlockDistribution.keys) {
            if (range.contains(stagePos)) {
              game.debugObjInBlockDistribution =
                  stage.objInBlockDistribution[range]!;
              break;
            }
          }
          game.pushSeqOverlay('debug_view_distributions_dialog');
          break;
      }
    }
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // ゲームシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'game') return true;
    // 準備中なら何もしない
    if (!isReady) return false;
    final keyMoves = [];
    // シフトキーを押している間は斜め入力のみ受け付け
    final onlyDiagonal = keysPressed.contains(LogicalKeyboardKey.shiftLeft);
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      keyMoves.add(Move.left);
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowRight)) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      keyMoves.add(Move.right);
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      keyMoves.add(Move.up);
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      keyMoves.add(Move.down);
    }

    // 現在の移動方向を上下左右に分解し、対応するキーが押されていなければその向きを消す
    // (右上向きに移動中右キーが押されなくなったら、pushingMoveButton = Move.upとなる)
    final pushingMoveList = pushingMoveButton.toStraightList();
    for (final move in pushingMoveList) {
      if (!keyMoves.contains(move)) {
        pushingMoveButton = pushingMoveButton.subStraight(move);
      }
    }
    // 押されているキーに対応する向きをpushingMoveButtonに足す
    for (final keyMove in keyMoves) {
      if (Config().allowMoveStraightWithoutLegAbility) {
        // 足の能力がオフなら、入力が上下左右のいずれかになっている時点でbreak
        if (!stage.getLegAbility() && pushingMoveButton.isStraight) {
          break;
        }
        pushingMoveButton = pushingMoveButton.addStraight(keyMove);
      } else {
        pushingMoveButton = pushingMoveButton.addStraight(keyMove);
        // 足の能力がオフかつ斜め入力になっているのなら、移動できなくする
        if (!stage.getLegAbility() && pushingMoveButton.isDiagonal) {
          pushingMoveButton = Move.none;
          break;
        }
      }
    }
    // シフトキーを押している間は斜め入力のみ受け付け
    if (onlyDiagonal && !pushingMoveButton.isDiagonal) {
      pushingMoveButton = Move.none;
    }

    // スペースキー->メニューを開く
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      if (menuButton.onReleased != null) {
        menuButton.onReleased!();
      }
    }

    // Pキー->ポケットの能力を使う
    if (event is RawKeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.keyP)) {
      if (pocketAbilityButton.onReleased != null) {
        pocketAbilityButton.onReleased!();
      }
    }

    return false;
  }
}
