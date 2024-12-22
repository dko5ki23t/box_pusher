import 'dart:convert';
import 'dart:io';

import 'package:box_pusher/audio.dart';
import 'package:box_pusher/components/confirm_delete_stage_data_dialog.dart';
import 'package:box_pusher/components/debug_dialog.dart';
import 'package:box_pusher/components/version_log_dialog.dart';
import 'package:box_pusher/sequences/clear_seq.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:box_pusher/sequences/gameover_seq.dart';
import 'package:box_pusher/sequences/loading_seq.dart';
import 'package:box_pusher/sequences/menu_seq.dart';
import 'package:box_pusher/sequences/sequence.dart';
import 'package:box_pusher/sequences/title_seq.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

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
        ScaleDetector, // ピンチイン・ピンチアウト検出用（マップの拡大縮小のため）
        ScrollDetector, // マウスホイール検出用（マップの拡大縮小のため）
        HasKeyboardHandlerComponents {
  late final RouterComponent _router;
  static final Vector2 offset = Vector2(15, 50);
  late final Map<String, OverlayRoute> _overlays;

  /// テストやデバッグ用のモード
  bool testMode;

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

  /// セーブデータのバージョン（アプリバージョン）
  Version _saveDataVersion = Version(0, 0, 0);

  /// 画面サイズのベース（実際の画面によってスケーリングされる）
  static Vector2 get baseSize => Vector2(360.0, 640.0);
  Vector2 contentSize = Vector2(0.0, 0.0);
  double contentScale = 0.0;

  /// ズーム操作し始めのズーム
  late double startZoom;

  BoxPusherGame({this.testMode = false})
      : super(
            camera: CameraComponent.withFixedResolution(
                width: baseSize.x, height: baseSize.y));

  // 背景色
  @override
  Color backgroundColor() => const Color(0xff000000);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // アプリ切り替え時に音楽中断/再開
    AppLifecycleListener(
      onShow: () {
        if (_router.currentRoute.name == 'game' &&
            _router.routes['game']!.firstChild() != null) {
          return Audio().resumeBGM();
        }
      },
      onHide: () {
        Audio().pauseBGM();
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
      'confirm_delete_stage_data_dialog': OverlayRoute(
        (context, game) {
          return ConfirmDeleteStageDataDialog(
            game: this,
          );
        },
      ),
    };
    camera.viewport.add(
      _router = RouterComponent(
        routes: {
          'title': Route(TitleSeq.new),
          'game': Route(GameSeq.new),
          'loading': Route(LoadingSeq.new, transparent: true),
          'menu': Route(MenuSeq.new, transparent: true),
          'gameover': Route(GameoverSeq.new, transparent: true),
          'clear': Route(ClearSeq.new, transparent: true),
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
        _saveDataVersion = Version.parse(prefs.getString('version')!);
      } catch (e) {
        _stageData = {};
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
        _stageData = jsonMap['stageData'];
        _saveDataVersion = Version.parse(jsonMap['version']);
      } catch (e) {
        _stageData = {};
        setAndSaveHighScore(0);
        _saveDataVersion = Version.parse(packageInfo.version);
      }
    }

    // オーディオの準備
    await Audio().onLoad();
  }

  /// ハイスコアの更新・セーブデータに保存
  Future<void> setAndSaveHighScore(int score) async {
    _highScore = score;
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  /// プレイ中ステージの更新・セーブデータに保存
  Future<void> setAndSaveStageData() async {
    final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
    _stageData = gameSeq.stage.encodeStageData();
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  Future<void> clearAndSaveStageData() async {
    _stageData = {};
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setString('stageData', jsonEncode(_stageData));
      await prefs.setString('version', _saveDataVersion.toString());
    } else {
      String jsonText = jsonEncode({
        'highScore': _highScore,
        'stageData': _stageData,
        'version': _saveDataVersion.toString(),
      });
      await saveDataFile.writeAsString(jsonText);
    }
  }

  int getCurrentScore() {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      return gameSeq.stage.score;
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

  @override
  void onScaleStart(ScaleStartInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    gameZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      camera.viewfinder.zoom = gameZoom * currentScale.y;
      clampZoom();
    } else {
      final delta = info.delta.global * -1.0;
      camera.moveBy(delta);
      //camera.viewfinder.position.translate(-delta.x, -delta.y);
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // ゲームシーケンス中のみ有効
    if (_router.currentRoute.name != 'game') return;
    gameZoom += info.scrollDelta.global.y * -0.001;
    gameZoom = gameZoom.clamp(0.5, 3.0);
    camera.viewfinder.zoom = gameZoom;
  }

  void clampZoom() {
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(0.5, 3.0);
  }

  void pushAndInitGame({bool initialize = true}) {
    if (_router.routes['game']!.firstChild() != null) {
      final gameSeq = _router.routes['game']!.firstChild() as GameSeq;
      if (gameSeq.isLoaded && initialize) {
        gameSeq.initialize();
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
}
