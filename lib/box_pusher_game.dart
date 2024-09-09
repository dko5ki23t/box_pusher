import 'package:box_pusher/components/debug_dialog.dart';
import 'package:box_pusher/sequences/clear_seq.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:box_pusher/sequences/menu_seq.dart';
import 'package:box_pusher/sequences/quest_seq.dart';
import 'package:box_pusher/sequences/title_seq.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;

class BoxPusherGame extends FlameGame with SingleGameInstance, PanDetector {
  late final RouterComponent router;
  static final Vector2 offset = Vector2(15, 50);

  /// テストやデバッグ用のモード
  final bool testMode;

  /// デバッグモードで作成するステージの情報
  int debugStageWidth = 7;
  int debugStageHeight = 7;
  int debugStageBoxNum = 3;

  /// 画面サイズのベース（実際の画面によってスケーリングされる）
  static Vector2 get baseSize => Vector2(360.0, 640.0);
  Vector2 contentSize = Vector2(0.0, 0.0);
  double contentScale = 0.0;
  bool triggeredL = false;
  bool triggeredR = false;
  bool triggeredU = false;
  bool triggeredD = false;
  // ゲームの画面サイズに合わせてスケールを変える
  final _content = RectangleComponent(
    size: baseSize,
  );

  /// ゲーム開始時の情報（GameSeqのinitialize()で参照する）
  GameMode gameMode = GameMode.quest;
  int gameLevel = 1;
  int gameStageNum = 1;

  BoxPusherGame({this.testMode = false});

  // 背景色
  @override
  Color backgroundColor() => const Color(0xff000000);

  @override
  void onLoad() {
    super.onLoad();

    // ゲームの画面サイズに合わせてスケールを変える領域を追加
    add(_content);
    // 各シーケンス（ルート）を追加
    _content.add(
      router = RouterComponent(
        routes: {
          'title': Route(TitleSeq.new),
          'quest': Route(QuestSeq.new),
          'game': Route(GameSeq.new),
          'menu': Route(MenuSeq.new, transparent: true),
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
  }

  @override
  void onGameResize(Vector2 size) {
    contentScale = size.y / _content.size.y;
    contentSize = Vector2(size.x, size.y);
    _content.scale = Vector2.all(contentScale);
    _content.position = Vector2(
      size.x * 0.5 - _content.size.x * 0.5 * contentScale,
      0,
    );
    super.onGameResize(size);
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
