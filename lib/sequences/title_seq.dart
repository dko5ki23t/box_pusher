import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/components/button.dart';
import 'package:push_and_merge/config.dart';
import 'package:push_and_merge/sequences/sequence.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
//import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class TitleSeq extends Sequence with /*TapCallbacks,*/ KeyboardHandler {
  //late final TextComponent titleText;
  late final SpriteComponent titleLogo;
  late final TextComponent highScreText;
  late final GameButtonGroup buttonGroup;
  late final GameTextButton newGameButton;
  late final GameTextButton continueButton;
  late final GameTextButton continueFromTreasureButton;
  late final GameTextButton languageButton;
  late final GameTextButton creditButton;
  late final GameTextButton privacyPolicyButton;
  //late final GameTextButton versionLogButton;
  late final GameTextButton achievementsButton;
  late final RectangleComponent highScoreRectangle;
  late final TextComponent versionText;
  late final Image titleLogoImage;
  late final Image bugImage;
  //late final GameButton debugOnOffButton;
  //late final GameTextButton debugButton;

  final spaceBetweenButtons = Vector2(0, 50.0);
  final buttonSize = Vector2(120.0, 30.0);

  /// 有効なデバッグコマンド入力中か
  bool isDebugCommandValid = false;

  /// 入力中のデバッグコマンド
  String debugCommand = '';

  /// 最後に宝箱を開けたときの有効なステージデータがあるか
  bool _existLastTreasureStageData = false;

  @override
  Future<void> onLoad() async {
    final loc = game.localization;
    //titleText = TextComponent(
    //  text: loc.gameTitle,
    //  size: Vector2(150.0, 45.0),
    //  position: Vector2(180.0, 260.0),
    //  anchor: Anchor.center,
    //  textRenderer: TextPaint(
    //    style: const TextStyle(
    //      fontFamily: Config.gameTextFamily,
    //      color: Color(0xff000000),
    //      fontSize: 40,
    //    ),
    //  ),
    //);
    titleLogoImage = await Flame.images.load('title_logo.png');
    titleLogo = SpriteComponent.fromImage(
      titleLogoImage,
      size: Vector2(300.0, 110.0),
      position: Vector2(180.0, 220.0),
      anchor: Anchor.center,
    );
    highScreText = TextComponent(
      text: "${loc.highScore} : ${game.highScore}",
      textRenderer: TextPaint(
        style: Config.gameTextStyle,
      ),
    );
    Vector2 buttonPos = Vector2(180.0, 360.0);
    _existLastTreasureStageData =
        game.lastTreasureStageData.containsKey('score');
    if (_existLastTreasureStageData) {
      buttonPos -= spaceBetweenButtons;
    }
    newGameButton = GameTextButton(
      size: buttonSize,
      position: buttonPos.clone(),
      anchor: Anchor.center,
      text: loc.newGame,
      onReleased: () {
        if (game.stageData.isNotEmpty) {
          game.pushSeqNamed('confirm_delete_stage_data');
        } else {
          game.pushAndInitGame(useLastTreasureData: false);
        }
      },
    );
    buttonPos += spaceBetweenButtons;
    continueButton = GameTextButton(
      size: buttonSize,
      position: buttonPos.clone(),
      anchor: Anchor.center,
      text: loc.loadGame,
      enabled: game.stageData.isNotEmpty,
      onReleased: () => game.pushAndInitGame(useLastTreasureData: false),
    );
    if (_existLastTreasureStageData) {
      buttonPos += spaceBetweenButtons;
    }
    continueFromTreasureButton = GameTextButton(
      size: buttonSize,
      position: buttonPos,
      anchor: Anchor.center,
      text: "${loc.loadGame} +",
      onReleased: () => game.pushSeqNamed('confirm_start_from_last_treasure'),
    );
    buttonPos += spaceBetweenButtons;
    achievementsButton = GameTextButton(
      size: buttonSize,
      position: buttonPos,
      anchor: Anchor.center,
      text: loc.achievements,
      onReleased: () async {
        game.pushSeqNamed('achievements');
      },
    );
    languageButton = GameTextButton(
      size: Vector2(80.0, 20.0),
      position: Vector2(300.0, 30.0),
      anchor: Anchor.center,
      text: loc.language,
      onReleased: () async {
        game.changeLocale();
        await game.saveUserConfigData();
      },
    );
    creditButton = GameTextButton(
      size: Vector2(80.0, 20.0),
      position: Vector2(300.0, 60.0),
      anchor: Anchor.center,
      text: loc.credit,
      onReleased: () async {
        game.pushSeqOverlay('credit_notation_dialog');
      },
    );
    privacyPolicyButton = GameTextButton(
      size: Vector2(150.0, 20.0),
      position: Vector2(180.0, 600.0),
      anchor: Anchor.center,
      text: loc.privacyPolicy,
      onReleased: () async {
        await launchUrl(Uri.https('shimarinapps.com', '/privacy-policy'));
      },
    );
    buttonGroup = GameButtonGroup(buttons: [
      languageButton,
      creditButton,
      newGameButton,
      continueButton,
      if (_existLastTreasureStageData) continueFromTreasureButton,
      achievementsButton,
      privacyPolicyButton,
    ]);
    highScoreRectangle = RectangleComponent(
      size: Vector2(120.0, 30.0),
      position: buttonPos + Vector2(0, 50.0),
      anchor: Anchor.center,
      children: [
        AlignComponent(
          alignment: Anchor.center,
          child: highScreText,
        ),
      ],
    );
    // アプリバージョン等取得
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    versionText = TextComponent(
      text: 'Ver.${packageInfo.version}',
      size: Vector2(120.0, 30.0),
      position: buttonPos + Vector2(0, 80.0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
            fontFamily: Config.gameTextFamily,
            color: Color(0xff000000),
            fontSize: 12),
      ),
    );
    //versionLogButton = GameTextButton(
    //  size: Vector2(120.0, 30.0),
    //  position: Vector2(180.0, 410.0),
    //  anchor: Anchor.center,
    //  text: loc.versionLog,
    //  onReleased: () async {
    //    game.pushSeqOverlay('version_log_dialog');
    //  },
    //);
    //debugButton = GameTextButton(
    //  size: Vector2(80.0, 30.0),
    //  position: Vector2(160.0, 460.0),
    //  anchor: Anchor.centerLeft,
    //  enabled: game.testMode,
    //  text: loc.debug,
    //  onReleased: () async {
    //    game.pushSeqOverlay('debug_dialog');
    //  },
    //);

    addAll([
      // 背景
      RectangleComponent(
        size: BoxPusherGame.baseSize,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      ),
      //titleText,
      titleLogo,
      newGameButton,
      continueButton,
      if (_existLastTreasureStageData) continueFromTreasureButton,
      languageButton,
      creditButton,
      //versionLogButton,
      achievementsButton,
      //GameSpriteOnOffButton(
      //  size: Vector2.all(30),
      //  position: Vector2(120.0, 460.0),
      //  anchor: Anchor.centerLeft,
      //  isOn: game.testMode,
      //  onChanged: (isOn) => game.testMode = !game.testMode,
      //  sprite: await Sprite.load('bug_report.png'),
      //),
      //if (game.testMode)
      //debugButton,
      highScoreRectangle,
      versionText,
      privacyPolicyButton,
      // TODO: 例外発生 -> MissingPluginException (MissingPluginException(No implementation found for method share on channel dev.fluttercommunity.plus/share))
      // 当面必要ないと思うのでコメントアウト
      /*GameTextButton(
        size: Vector2(120.0, 30.0),
        position: Vector2(180.0, 530.0),
        anchor: Anchor.center,
        text: "シェア",
        onReleased: () => Share.share("共有のテスト"),
      ),*/
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    highScreText.text = "${game.localization.highScore} : ${game.highScore}";
    continueButton.enabled = game.stageData.isNotEmpty;
    //debugButton.enabled = game.testMode;
    final prev = _existLastTreasureStageData;
    _existLastTreasureStageData =
        game.lastTreasureStageData.containsKey('score');
    if (_existLastTreasureStageData != prev) {
      // ボタン位置更新
      Vector2 buttonPos = Vector2(180.0, 360.0);
      if (_existLastTreasureStageData) {
        buttonPos -= spaceBetweenButtons;
      }
      newGameButton.position = buttonPos.clone();
      buttonPos += spaceBetweenButtons;
      continueButton.position = buttonPos.clone();
      if (_existLastTreasureStageData) {
        buttonPos += spaceBetweenButtons;
      }
      continueFromTreasureButton.position = buttonPos.clone();
      buttonPos += spaceBetweenButtons;
      achievementsButton.position = buttonPos.clone();
      buttonGroup.buttons.clear();
      buttonGroup.buttons.addAll([
        languageButton,
        newGameButton,
        continueButton,
        if (_existLastTreasureStageData) continueFromTreasureButton,
        achievementsButton,
      ]);
      highScoreRectangle.position = buttonPos + Vector2(0, 50.0);
      versionText.position = buttonPos + Vector2(0, 90.0);
      if (_existLastTreasureStageData &&
          !contains(continueFromTreasureButton)) {
        add(continueFromTreasureButton);
      } else if (!_existLastTreasureStageData &&
          contains(continueFromTreasureButton)) {
        remove(continueFromTreasureButton);
      }
    }
  }

  // PCのキーボード入力
  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // タイトルシーケンスでない場合は何もせず、キー処理を他に渡す
    if (game.getCurrentSeqName() != 'title') return true;
    if ((keysPressed.contains(LogicalKeyboardKey.arrowUp)) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      buttonGroup.focusPrev(focusIdIfNull: 2);
    }
    if ((keysPressed.contains(LogicalKeyboardKey.arrowDown)) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      buttonGroup.focusNext(focusIdIfNull: 2);
    }

    // スペースキー->フォーカスしているボタンを押す
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      buttonGroup.getCurrentFocusButton()?.fire();
    }

    // デバッグコマンド
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.slash)) {
        isDebugCommandValid = true;
        debugCommand = '';
      } else if (isDebugCommandValid) {
        if (debugCommand == '' &&
            keysPressed.contains(LogicalKeyboardKey.keyI)) {
          debugCommand = 'i';
        } else if (debugCommand == 'i' &&
            keysPressed.contains(LogicalKeyboardKey.keyM)) {
          debugCommand = 'im';
        } else if (debugCommand == 'im' &&
            keysPressed.contains(LogicalKeyboardKey.keyP)) {
          // セーブデータインポート
          importSaveData();
          isDebugCommandValid = false;
          debugCommand = '';
        } else if (debugCommand == '' &&
            keysPressed.contains(LogicalKeyboardKey.keyE)) {
          debugCommand = 'e';
        } else if (debugCommand == 'e' &&
            keysPressed.contains(LogicalKeyboardKey.keyX)) {
          debugCommand = 'ex';
        } else if (debugCommand == 'ex' &&
            keysPressed.contains(LogicalKeyboardKey.keyP)) {
          // セーブデータエクスポート
          exportSaveData();
          isDebugCommandValid = false;
          debugCommand = '';
        } else {
          isDebugCommandValid = false;
          debugCommand = '';
        }
      }
    }

    return false;
  }

  Future<void> importSaveData() async {
    // ファイル選択ダイアログ
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'json',
      extensions: ['json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final String fileContent = await file.readAsString();
      game.importSaveDataFromString(fileContent);
    }
  }

  Future<void> exportSaveData() async {
    const String fileName = 'save_data.json';
    final FileSaveLocation? result =
        await getSaveLocation(suggestedName: fileName);
    if (result == null) {
      // Operation was canceled by the user.
      return;
    }

    final Uint8List fileData =
        Uint8List.fromList(game.exportSaveDataToString().codeUnits);
    const String mimeType = 'application/json';
    final XFile textFile =
        XFile.fromData(fileData, mimeType: mimeType, name: fileName);
    await textFile.saveTo(result.path);
  }

  @override
  void onUnFocus() {
    // ボタン群のフォーカスをクリア
    buttonGroup.unFocus();
  }

  @override
  void onLangChanged() {
    final loc = game.localization;
    //titleText.text = loc.gameTitle;
    newGameButton.text = loc.newGame;
    continueButton.text = loc.loadGame;
    continueFromTreasureButton.text = "${loc.loadGame} +";
    languageButton.text = loc.language;
    creditButton.text = loc.credit;
    //versionLogButton.text = loc.versionLog;
    achievementsButton.text = loc.achievements;
    //debugButton.text = loc.debug;
    privacyPolicyButton.text = loc.privacyPolicy;
  }
}
