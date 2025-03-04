import 'package:flutter/foundation.dart';
import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/game_core/stage_objs/player.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuSeq extends Sequence with KeyboardHandler {
  late final TextComponent menuText;
  late final GameButtonGroup buttonGroup;
  late final GameMenuButton resumeButton;
  late final GameMenuButton saveButton;
  late final GameMenuButton saveAndToTitleButton;
  late final GameMenuButton giveUpButton;
  late final GameMenuButton controllSettingButton;
  late final GameMenuButton resetCameraButton;

  bool isSaved = false;

  final menuButtonSize = Vector2(150.0, 30.0);
  final menuButtonBasePos = Vector2(180.0, 250.0);
  final menuButtonOffset = Vector2(0, 50.0);

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    menuText = TextComponent(
      text: loc.menu,
      size: Vector2(320.0, 45.0),
      position: Vector2(180.0, 180.0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: Config.gameTextFamily,
          color: Colors.white,
          fontSize: 35,
        ),
      ),
    );
    Vector2 menuButtonPos = menuButtonBasePos.clone();
    resumeButton = GameMenuButton(
      keyName: 'resume',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: loc.resume,
      onReleased: () => game.popSeq(),
    );
    menuButtonPos += menuButtonOffset;
    saveButton = GameMenuButton(
      keyName: 'save',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: loc.save,
      onReleased: () async {
        await game.setAndSaveStageData();
        await game.saveAchievementData();
        isSaved = true;
      },
    );
    menuButtonPos += menuButtonOffset;
    saveAndToTitleButton = GameMenuButton(
      keyName: 'saveAndToTitle',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: loc.saveAndToTitle,
      onReleased: () async {
        if (!isSaved) {
          await game.setAndSaveStageData();
          await game.saveAchievementData();
        }
        game.pushSeqNamed('title');
      },
    );
    menuButtonPos += menuButtonOffset;
    giveUpButton = GameMenuButton(
      keyName: 'giveUp',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: loc.exit,
      onReleased: () async {
        game.pushSeqNamed('confirm_exit');
      },
    );
    menuButtonPos += menuButtonOffset;
    controllSettingButton = GameMenuButton(
      keyName: 'controllSetting',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: "${loc.controller}${Config().playerControllButtonType.index + 1}",
      onReleased: () {
        int index = Config().playerControllButtonType.index + 1;
        bool canSelect = false;
        while (!canSelect) {
          canSelect = true;
          // モバイル版ではキーボード使えないため、「操作ボタンなし」は選べないようにする
          if (!kIsWeb && index == PlayerControllButtonType.noButton.index) {
            ++index;
            canSelect = false;
          }
          // 斜め移動能力が無い場合は操作ボタン「画面下部2」を選べないようにする
          if (index == PlayerControllButtonType.onScreenBottom2.index &&
              !game.isPlayerAbilityAquired(PlayerAbility.leg)) {
            ++index;
            canSelect = false;
          }
          if (index >= PlayerControllButtonType.values.length) {
            index = 0;
            canSelect = false;
          }
        }
        Config().playerControllButtonType =
            PlayerControllButtonType.values[index];
        game.updatePlayerControllButtons();
      },
    );
    menuButtonPos += menuButtonOffset;
    resetCameraButton = GameMenuButton(
      keyName: 'resetCamer',
      size: menuButtonSize,
      position: menuButtonPos,
      anchor: Anchor.center,
      text: loc.resetCamera,
      onReleased: () {
        game.camera.viewfinder.zoom = 1.0;
        game.resetCameraPos();
      },
    );
    buttonGroup = GameButtonGroup(buttons: [
      resumeButton,
      saveButton,
      saveAndToTitleButton,
      giveUpButton,
      controllSettingButton,
      resetCameraButton,
    ]);
    addAll([
      // 背景をボタンにする(押すとメニュー閉じる)にすることで、背後のゲーム画面での操作を不可能にする
      ButtonComponent(
        onReleased: () => game.popSeq(),
        button: RectangleComponent(
          size: BoxPusherGame.baseSize,
          paint: Paint()
            ..color = const Color(0x80000000)
            ..style = PaintingStyle.fill
            ..strokeWidth = 2,
        ),
      ),
      menuText,
      resumeButton, saveButton, saveAndToTitleButton,
      giveUpButton, controllSettingButton, resetCameraButton,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final loc = game.localization;
    controllSettingButton.text =
        "${loc.controller}${Config().playerControllButtonType.index + 1}";
    // セーブ済みならボタンを無効化&テキスト変更
    saveButton.text = isSaved ? loc.saved : loc.save;
    saveButton.enabled = !isSaved;
    saveAndToTitleButton.text = isSaved ? loc.toTitle : loc.saveAndToTitle;
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // メニューシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'menu') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      buttonGroup.focusPrev();
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      buttonGroup.focusNext();
    }

    // Escキー->メニューを閉じる
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.escape)) {
      game.popSeq();
    }

    // スペースキー->フォーカスしているボタンを押す
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
    }

    return false;
  }

  @override
  void onFocus(String? before) {
    if (before == "confirm_exit") {
      // あきらめるボタン押下後の確認ダイアログから遷移してきたなら
      if (game.isGameover() == true) {
        // ゲーム画面->ゲームオーバー画面に遷移
        game.popSeq();
      }
    }
  }

  @override
  void onUnFocus() {
    // ボタン群のフォーカスをクリア
    buttonGroup.unFocus();
    // セーブしたかどうかをクリア
    isSaved = false;
    // ユーザ設定コンフィグをセーブ
    game.saveUserConfigData();
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    menuText.text = loc.menu;
    resumeButton.text = loc.resume;
    saveButton.text = loc.save;
    giveUpButton.text = loc.exit;
    resetCameraButton.text = loc.resetCamera;
  }
}
