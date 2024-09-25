import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:box_pusher/components/debug_dialog.dart';
import 'package:box_pusher/game_core/stage_objs/stage_obj.dart';
import 'package:box_pusher/sequences/clear_seq.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:box_pusher/sequences/gameover_seq.dart';
import 'package:box_pusher/sequences/menu_seq.dart';
import 'package:box_pusher/sequences/quest_seq.dart';
import 'package:box_pusher/sequences/title_seq.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;
import 'package:path_provider/path_provider.dart';

class BoxPusherGame extends FlameGame with SingleGameInstance, PanDetector {
  late final RouterComponent router;
  static final Vector2 offset = Vector2(15, 50);

  /// テストやデバッグ用のモード
  final bool testMode;

  /// デバッグモードで作成するステージの情報
  int debugStageWidth = 7;
  int debugStageHeight = 7;
  int debugStageBoxNum = 3;

  /// セーブデータファイル
  late final File saveDataFile;

  /// ハイスコア
  int _highScore = 0;
  int get highScore => _highScore;

  /// プレイ中のステージ情報
  Map<String, dynamic> _stageData = {};
  Map<String, dynamic> get stageData => _stageData;

  /// 画面サイズのベース（実際の画面によってスケーリングされる）
  static Vector2 get baseSize => Vector2(360.0, 640.0);
  Vector2 contentSize = Vector2(0.0, 0.0);
  double contentScale = 0.0;
  bool triggeredL = false;
  bool triggeredR = false;
  bool triggeredU = false;
  bool triggeredD = false;

  /// ゲーム開始時の情報（GameSeqのinitialize()で参照する）
  GameMode gameMode = GameMode.quest;
  int gameLevel = 1;
  int gameStageNum = 1;

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

    // 各シーケンス（ルート）を追加
    camera.viewport.add(
      router = RouterComponent(
        routes: {
          'title': Route(TitleSeq.new),
          'quest': Route(QuestSeq.new),
          'game': Route(GameSeq.new),
          'menu': Route(MenuSeq.new, transparent: true),
          'gameover': Route(GameoverSeq.new, transparent: true),
          'clear': Route(ClearSeq.new, transparent: true),
          'debug_dialog': OverlayRoute(
            (context, game) {
              return DebugDialog(
                game: this,
              );
            },
          )
        },
        initialRoute: 'title',
      ),
    );

    // セーブデータファイル準備
    final directory = await getApplicationDocumentsDirectory();
    final localPath = directory.path;
    saveDataFile = File('$localPath/box_pusher.json');
    try {
      final saveData = await saveDataFile.readAsString();
      final jsonMap = jsonDecode(saveData);
      _highScore = jsonMap['highScore'];
      _stageData = jsonMap['stageData'];
    } catch (e) {
      _stageData = {};
      setAndSaveHighScore(0);
    }
  }

  /// ハイスコアの更新・セーブデータに保存
  Future<void> setAndSaveHighScore(int score) async {
    _highScore = score;
    String jsonText = jsonEncode({
      'highScore': _highScore,
      'stageData': _stageData,
    });
    await saveDataFile.writeAsString(jsonText);
  }

  /// プレイ中ステージの更新・セーブデータに保存
  Future<void> setAndSaveStageData() async {
    final gameSeq = router.routes['game']!.firstChild() as GameSeq;
    _stageData = gameSeq.stage.getStageData();
    String jsonText = jsonEncode({
      'highScore': _highScore,
      'stageData': _stageData,
    });
    await saveDataFile.writeAsString(jsonText);
  }

  Future<void> clearAndSaveStageData() async {
    _stageData = {};
    String jsonText = jsonEncode({
      'highScore': _highScore,
      'stageData': _stageData,
    });
    await saveDataFile.writeAsString(jsonText);
  }

  @override
  void onRemove() {
    removeAll(children);
    processLifecycleEvents();
    Flame.images.clearCache();
    Flame.assets.clearCache();
  }

  @override
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
  }

  void pushAndInitGame(
      {GameMode? mode, int? level, int? stage, bool initialize = true}) {
    if (mode != null) gameMode = mode;
    if (level != null) gameLevel = level;
    if (stage != null) gameStageNum = stage;
    if (router.routes['game']!.firstChild() != null) {
      final gameSeq = router.routes['game']!.firstChild() as GameSeq;
      if (gameSeq.isLoaded && initialize) {
        gameSeq.initialize();
      }
    }
    router.pushNamed('game');
  }

  void resetGame() {
    if (router.routes['game']!.firstChild() != null) {
      final gameSeq = router.routes['game']!.firstChild() as GameSeq;
      if (gameSeq.isLoaded) {
        gameSeq.reset();
      }
    }
  }

  void resetTriggered() {
    triggeredL = false;
    triggeredR = false;
    triggeredU = false;
    triggeredD = false;
  }

  get isTriggeredL {
    final ret = triggeredL;
    triggeredL = false;
    return ret;
  }

  get isTriggeredR {
    final ret = triggeredR;
    triggeredR = false;
    return ret;
  }

  get isTriggeredU {
    final ret = triggeredU;
    triggeredU = false;
    return ret;
  }

  get isTriggeredD {
    final ret = triggeredD;
    triggeredD = false;
    return ret;
  }
}
