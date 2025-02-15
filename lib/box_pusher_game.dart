import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/components/debug_dialog.dart';
import 'package:box_pusher/components/debug_view_distributions_dialog.dart';
import 'package:box_pusher/components/version_log_dialog.dart';
import 'package:box_pusher/config.dart';
import 'package:box_pusher/custom_scale_detector.dart';
import 'package:box_pusher/game_core/common.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/sequences/achievements_seq.dart';
import 'package:box_pusher/sequences/clear_seq.dart';
import 'package:box_pusher/sequences/confirm_delete_stage_data_seq.dart';
import 'package:box_pusher/sequences/confirm_exit_seq.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:box_pusher/sequences/gameover_seq.dart';
import 'package:box_pusher/sequences/loading_seq.dart';
import 'package:box_pusher/sequences/menu_seq.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:box_pusher/sequences/title_seq.dart';
import 'package:box_pusher/visibility_listener.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_ja.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

enum Language {
  japanese,
  english,
}

class Version {
  int major;
  int minor;
  int patch;

  Version(this.major, this.minor, this.patch);

  static Version parse(String str) {
    final nums = str.split('.');
    return Version(int.parse(nums[0]), int.parse(nums[1]), int.parse(nums[2]));
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class BoxPusherGame extends FlameGame
    with
        SingleGameInstance,
        CustomScaleDetector, // ピンチイン・ピンチアウト検出用（マップの拡大縮小のため）
        ScrollDetector, // マウスホイール検出用（マップの拡大縮小のため）
        HasKeyboardHandlerComponents {
  late final RouterComponent _router;
  static final Vector2 offset = Vector2(15, 50);
  late final Map<String, OverlayRoute> _overlays;

  /// テストやデバッグ用のモード
  bool testMode;

  /// 【テストモード】分布表示時にダイアログに渡すための変数
  late Point debugTargetPos;
  late Distribution<StageObjTypeLevel> debugBlockFloorDistribution;
  late Distribution<StageObjTypeLevel> debugObjInBlockDistribution;

  /// ゲームでキーボードを使うためのフォーカス
  final FocusNode gameFocus;

  /// ゲームシーケンスでのズーム倍率
  double gameZoom = 1.0;

  /// セーブデータファイル
  late final File saveDataFile;

  /// ハイスコア
  int _highScore = 0;
  int get highScore => _highScore;

  /// プレイ中のステージ情報
  Map<String, dynamic> _stageData = {};
  Map<String, dynamic> get stageData => _stageData;

  /// 実績情報
  Map<String, dynamic> _achievementData = {};
  Map<String, dynamic> get achievementData => _achievementData;

  /// 操作方法や音量等のコンフィグ情報
  Map<String, dynamic> _userConfigData = {};
  Map<String, dynamic> get userConfigData => _userConfigData;

  /// セーブデータのバージョン（アプリバージョン）
  Version _saveDataVersion = Version(0, 0, 0);

  /// 画面サイズのベース（実際の画面によってスケーリングされる）
  static Vector2 get baseSize => Vector2(360.0, 640.0);
  Vector2 contentSize = Vector2(0.0, 0.0);
  double contentScale = 0.0;

  /// ズーム操作し始めのズーム
  late double startZoom;

  /// ドラッグ操作でカメラ移動できるか(ジョイスティックをドラッグ中ならfalseにする)
  bool canMoveCamera = true;

  /// 言語
  Language lang = Language.japanese;

  // TODO: ゴリ押し
  /// ローカライゼーション取得
  AppLocalizations get localization {
    switch (lang) {
      case Language.japanese:
        return AppLocalizationsJa();
      case Language.english:
        return AppLocalizationsEn();
    }
  }

  /// ロケール変更
  void changeLocale() {
    switch (lang) {
      case Language.japanese:
        lang = Language.english;
        break;
      case Language.english:
        lang = Language.japanese;
        break;
    }
  }

  BoxPusherGame({
    this.testMode = false,
    required this.gameFocus,
    required Locale initialLocale,
  }) : super(
            camera: CameraComponent.withFixedResolution(
                width: baseSize.x, height: baseSize.y)) {
    if (initialLocale.languageCode == 'en') {
      lang = Language.english;
    }
  }

  // 背景色
  @override
  Color backgroundColor() => const Color(0xff000000);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // アプリ切り替え時/webページの表示・非表示時に音楽を中断/再開
    await Audio().onLoad();
    VisibilityListener.setListeners(
      onShow: () {
        if (_router.currentRoute.name == 'game' &&
            _router.routes['game']!.firstChild() != null) {
          if (!Config().hideGameToMenu) {
            Audio().resumeBGM();
          }
        }
      },
      onHide: () {
        if (Config().hideGameToMenu &&
            _router.currentRoute.name == 'game' &&
            _router.routes['game']!.firstChild() != null) {
          // ゲームシーケンスの時はメニュー画面に遷移
          pushSeqNamed("menu");
        } else {
          Audio().pauseBGM();
        }
      },
    );

    // 各シーケンス（ルート）を追加
    _overlays = {
      'version_log_dialog': OverlayRoute(
        (context, game) {
          return VersionLogDialog(
            game: this,
          );
        },
      ),
      'debug_dialog': OverlayRoute(
        (context, game) {
          return DebugDialog(
            game: this,
          );
        },
      ),
      'debug_view_distributions_dialog': OverlayRoute(
        (context, game) {
          return DebugViewDistributionsDialog(
            game: this,
          );
        },
      ),
    };
    camera.viewport.add(
      _router = RouterComponent(
        routes: {
          'title': Route(TitleSeq.new),
          'achievements': Route(AchievementsSeq.new),
          'game': Route(GameSeq.new),
          'loading': Route(LoadingSeq.new, transparent: true),
          'menu': Route(MenuSeq.new, transparent: true),
          'gameover': Route(GameoverSeq.new, transparent: true),
          'clear': Route(ClearSeq.new, transparent: true),
          'confirm_exit': Route(ConfirmExitSeq.new, transparent: true),
          'confirm_delete_stage_data':
              Route(ConfirmDeleteStageDataSeq.new, transparent: true),
        }..addAll(_overlays),
        initialRoute: 'title',
      ),
    );

    // アプリバージョン等取得
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // セーブデータファイル準備
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        _highScore = prefs.getInt('highScore') ?? 0;
        _stageData = jsonDecode(prefs.getString('stageData') ?? '');
        _userConfigData = jsonDecode(prefs.getString('userConfigData') ??
            jsonEncode(getDefaultUserConfig()));
        _achievementData = jsonDecode(prefs.getString('achievementData') ??
            jsonEncode(getDefaultAchievement()));
        _saveDataVersion = Version.parse(prefs.getString('version')!);
      } catch (e) {
        _stageData = {};
        _userConfigData = getDefaultUserConfig();
        _achievementData = getDefaultAchievement();
        setAndSaveHighScore(0);
        _saveDataVersion = Version.parse(packageInfo.version);
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = directory.path;
      saveDataFile = File('$localPath/box_pusher.json');
      try {
        final saveData = await saveDataFile.readAsString();
        final jsonMap = jsonDecode(saveData);
        _highScore = jsonMap['highScore'];
        _stageData = jsonMap['stageData'] ?? {};
        _userConfigData = jsonMap['userConfigData'] ?? getDefaultUserConfig();
        _achievementData =
            jsonMap['achievementData'] ?? getDefaultAchievement();
        _saveDataVersion = Version.parse(jsonMap['version']);
      } catch (e) {
        _stageData = {};
        _userConfigData = getDefaultUserConfig();
        _achievementData = getDefaultAchievement();
        setAndSaveHighScore(0);
        _saveDataVersion = Version.parse(packageInfo.version);
      }
    }
    // ユーザ設定コンフィグデータを反映
    int index = 0;
    try {
      index = _userConfigData['controller'];
    } catch (e) {
      log(e.toString());
    }
    if (index < PlayerControllButtonType.values.length) {
      Config().playerControllButtonType =
          PlayerControllButtonType.values[index];
    }
    int volume = 100;
    try {
      volume = _userConfigData['volume'];
    } catch (e) {
      log(e.toString());
    }
    Config().audioVolume = volume;
    bool showTutorial = true;
    try {
      showTutorial = _userConfigData['showTutorial'];
    } catch (e) {
      log(e.toString());
    }
    Config().showTutorial = showTutorial;
  }

  /// 【デバッグ】文字列からセーブデータをインポート->成功したかどうかを返す
  Future<bool> importSaveDataFromString(String saveData) async {
    try {
      final jsonMap = jsonDecode(saveData);
      _stageData = jsonMap['stageData'] ?? {};
    } catch (e) {
      return false;
    }
    return true;
  }

  /// 【デバッグ】セーブデータをファイルにエクスポート
  String exportSaveDataToString() {
    return jsonEncode({
      'highScore': _highScore,
      'stageData': _stageData,
      'userConfigData': _userConfigData,
      'achievementData': _achievementData,
      'version': _saveDataVersion.toString(),
    });
  }

  /// ハイスコアの更新・セーブデータに保存
  Future<void> setAndSaveHighScore(int score) async {
    _highScore = score;
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('userConfigData', jsonEncode(_userConfigData));
      await prefs.setString('achievementData', jsonEncode(_achievementData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'userConfigData': _userConfigData,
        'achievementData': _achievementData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  /// プレイ中ステージの更新・セーブデータに保存
  Future<void> setAndSaveStageData() async {
    final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
    _stageData = await gameSeq.stage.encodeStageData();
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('userConfigData', jsonEncode(_userConfigData));
      await prefs.setString('achievementData', jsonEncode(_achievementData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'userConfigData': _userConfigData,
        'achievementData': _achievementData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  /// 操作方法や音量等のコンフィグ情報をセーブデータに保存
  Future<void> saveUserConfigData() async {
    _userConfigData['controller'] = Config().playerControllButtonType.index;
    _userConfigData['volume'] = Config().audioVolume;
    _userConfigData['showTutorial'] = Config().showTutorial;
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('userConfigData', jsonEncode(_userConfigData));
      await prefs.setString('achievementData', jsonEncode(_achievementData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'userConfigData': _userConfigData,
        'achievementData': _achievementData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  Map<String, dynamic> getDefaultUserConfig() {
    return {
      'controller': PlayerControllButtonType.joyStick.index,
      'volume': 100,
      'showTutorial': true,
    };
  }

  /// 操作方法や音量等のコンフィグ情報をセーブデータに保存
  Future<void> saveAchievementData() async {
    // TODO:各種実績の情報を取得
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('userConfigData', jsonEncode(_userConfigData));
      await prefs.setString('achievementData', jsonEncode(_achievementData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'userConfigData': _userConfigData,
        'achievementData': _achievementData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  Map<String, dynamic> getDefaultAchievement() {
    return {
      'hasHelpedGirl': false,
      'createDia': false,
      'maxFoundTreasureNum': 0,
      'maxBreakBlockRate': 0,
    };
  }

  Future<void> clearAndSaveStageData() async {
    _stageData = {};
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('userConfigData', jsonEncode(_userConfigData));
      await prefs.setString('achievementData', jsonEncode(_achievementData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'userConfigData': _userConfigData,
        'achievementData': _achievementData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  int getCurrentScore() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      return gameSeq.stage.score.actual;
    } else {
      return 0;
    }
  }

  bool isGameReady() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      return gameSeq.isReady;
    } else {
      return false;
    }
  }

  void updatePlayerControllButtons() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      gameSeq.updatePlayerControllButtons();
    }
  }

  void setGameover() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      gameSeq.stage.isGameover = true;
    }
  }

  bool? isGameover() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      return gameSeq.stage.isGameover;
    }
    return null;
  }

  void resetCameraPos() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      gameSeq.resetCameraPos();
    }
  }

  @override
  void onRemove() {
    removeAll(children);
    processLifecycleEvents();
    Flame.images.clearCache();
    Flame.assets.clearCache();
    Audio().onRemove();
  }

  /*@override
  void onPanEnd(DragEndInfo info) {
    if (info.velocity.x.abs() > info.velocity.y.abs()) {
      // X Axis
      if (info.velocity.x < 0) {
        triggeredL = true;
      } else {
        triggeredR = true;
      }
    } else {
      // Y Axis
      if (info.velocity.y < 0) {
        triggeredU = true;
      } else {
        triggeredD = true;
      }
    }
  }*/

  void clampZoom() {
    gameZoom = gameZoom.clamp(0.8, 3.0);
    camera.viewfinder.zoom = gameZoom;
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    if ((_router.routes['game']!.firstChild() as GameSeq).tutorial.current !=
        null) {
      return;
    }
    gameZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    if ((_router.routes['game']!.firstChild() as GameSeq).tutorial.current !=
        null) {
      return;
    }
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      gameZoom *= currentScale.y;
      clampZoom();
    } else {
      // 実行されない（CostomScaleDetectorを使用した弊害？ https://github.com/flame-engine/flame/issues/2635）
      // ->代わりにonDragUpdateを使う
      final delta = info.delta.global;
      camera.moveBy(-delta);
      //camera.viewfinder.position.translate(-delta.x, -delta.y);
    }
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    if ((_router.routes['game']!.firstChild() as GameSeq).tutorial.current !=
        null) {
      return;
    }
    if (canMoveCamera) {
      final delta = info.delta.global;
      camera.moveBy(-delta);
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    if ((_router.routes['game']!.firstChild() as GameSeq).tutorial.current !=
        null) {
      return;
    }
    gameZoom += info.scrollDelta.global.y * -0.001;
    clampZoom();
  }

  void pushAndInitGame({bool initialize = true}) {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      if (gameSeq.isLoaded && initialize) {
        gameSeq.isReady = false;
        pushSeqNamed('game');
        pushSeqNamed('loading');
        gameSeq.initialize(addComponents: false);
        return;
      }
    }
    pushSeqNamed('game');
    pushSeqNamed('loading');
  }

  void pushSeqNamed(String name, {bool replace = false}) {
    final beforeName = _router.currentRoute.name;
    if (!_overlays.keys.contains(beforeName)) {
      (_router.currentRoute.firstChild()! as Sequence).onUnFocus();
    }
    _router.pushNamed(name, replace: replace);
    final curName = _router.currentRoute.name;
    if (_router.routes[name]!.firstChild() != null &&
        !_overlays.keys.contains(curName)) {
      (_router.routes[name]!.firstChild()! as Sequence).onFocus(beforeName);
    }
  }

  void pushSeqOverlay(String name) {
    final curName = _router.currentRoute.name;
    if (!_overlays.keys.contains(curName)) {
      (_router.currentRoute.firstChild()! as Sequence).onUnFocus();
    }
    _router.pushOverlay(name);
  }

  void popSeq() {
    final beforeName = _router.currentRoute.name;
    if (!_overlays.keys.contains(beforeName)) {
      (_router.currentRoute.firstChild()! as Sequence).onUnFocus();
    }
    _router.pop();
    final curName = _router.currentRoute.name;
    if (!_overlays.keys.contains(curName)) {
      (_router.currentRoute.firstChild()! as Sequence).onFocus(beforeName);
    }
  }

  String? getCurrentSeqName() => _router.currentRoute.name;
}
