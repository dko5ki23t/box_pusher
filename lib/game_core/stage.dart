import 'dart:async';
//import 'dart:convert';
//import 'dart:math';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:collection/collection.dart';
//import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:logger/logger.dart';

/// ステージ上オブジェクトの種類
enum StageObjType {
  none,
  wall,
  goal,
  box,
  boxOnGoal,
  player,
  playerOnGoal,
  reservedFloor, // 何もない床確定
}

class StageObjTypeLevel {
  StageObjType type;
  int level;

  StageObjTypeLevel({required this.type, this.level = 1});
}

/// 移動
enum Move {
  none,
  left,
  right,
  up,
  down,
}

/// 移動履歴
class MoveHistory {
  final bool boxMoved;
  final Move move;

  MoveHistory({
    required this.boxMoved,
    required this.move,
  });
}

class StageObjFactory {
  final Map<StageObjType, Sprite> stageSprites;
  Vector2 offset;

  StageObjFactory({required this.stageSprites, required this.offset});

  StageObj create({required StageObjTypeLevel typeLevel, required Point pos}) {
    return StageObj(
        typeLevel: typeLevel,
        sprite: SpriteComponent(
          sprite: stageSprites[typeLevel.type],
          children: [
            if (typeLevel.level > 1)
              AlignComponent(
                alignment: Anchor.center,
                child: TextComponent(
                  text: typeLevel.level.toString(),
                  textRenderer: TextPaint(
                    style: const TextStyle(
                      fontFamily: 'Aboreto',
                      color: Color(0xff000000),
                    ),
                  ),
                ),
              ),
          ],
          size: Stage.cellSize,
          position: (offset +
              Vector2(pos.x * Stage.cellSize.x, pos.y * Stage.cellSize.y)),
        ),
        pos: pos);
  }

  Sprite getSprite(StageObjType type) => stageSprites[type]!;

  void setPosition(StageObj obj, {Vector2? offset}) {
    final pixel = offset ?? Vector2.zero();
    obj.sprite.position = this.offset +
        Vector2(obj.pos.x * Stage.cellSize.x, obj.pos.y * Stage.cellSize.y) +
        pixel;
  }
}

class StageObj {
  StageObjTypeLevel typeLevel;
  Point pos; // 現在位置
  bool valid;
  SpriteComponent sprite;

  StageObj({
    required this.typeLevel,
    required this.sprite,
    this.valid = true,
    required this.pos,
  });
}

class Point {
  int x = 0;
  int y = 0;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Point &&
            runtimeType == other.runtimeType &&
            x == other.x &&
            y == other.y);
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Point operator -() {
    return Point(-x, -y);
  }

  Point operator +(Point a) {
    return Point(x + a.x, y + a.y);
  }

  Point operator -(Point a) {
    return Point(x - a.x, y - a.y);
  }

  Point copy() => Point(x, y);

  int distance() {
    return (x.abs() + y.abs());
  }
}

class MovePath {
  List<Point> path = [];
  int fCount = 0;
}

class Stage {
  /// マスのサイズ
  static Vector2 get cellSize => Vector2(32.0, 32.0);

  /// プレイヤーの移動速度
  static const double playerSpeed = 96.0;

  final Image stageImg;

  int _width = 0;
  int _height = 0;

  /// プレイヤーの位置
  Point playerPos = Point(-1, -1);

  late StageObjFactory objFactory;

  /// ステージ構造の初期状態
  List<List<StageObjTypeLevel>> initialObjsInfo = [];
  Point initialPlayerPos = Point(0, 0);

  /// 現在のステージ状態
  List<List<StageObjTypeLevel>> objsInfo = [];

  /// 静止物
  Map<Point, StageObj> staticObjs = {};

  /// 箱
  List<StageObj> boxes = [];

  /// 消えた(無効にした)箱
  List<StageObj> invalidBoxes = [];

  /// プレイヤー
  late StageObj player;

  /// プレイヤーが移動中かどうか
  bool isPlayerMoving = false;

  /// 一手戻している最中からどうか
  bool isUndoing = false;

  /// 箱が移動中かどうか
  bool isBoxMoving = false;

  /// 移動履歴
  List<MoveHistory> moveHistory = [];

  /// 移動中の箱
  StageObj? movingBox;

  /// 移動量
  double movingAmount = 0.0;

  /// 移動中の方向
  Move movingTo = Move.none;

  /// ステージの横幅
  int get width => _width;
  set width(int w) {
    _width = w;
    _updateOffset();
  }

  /// ステージの高さ
  int get height => _height;
  set height(int h) {
    _height = h;
    _updateOffset();
  }

  void _updateOffset() {
    final internalOffset = Vector2(
        (GameSeq.stageViewSize.x - cellSize.x * _width) * 0.5,
        (GameSeq.stageViewSize.y - cellSize.y * _height) * 0.5);
    final offset = Vector2(GameSeq.xPaddingSize.x,
            GameSeq.topPaddingSize.y + GameSeq.yPaddingSize.y) +
        internalOffset;
    objFactory.offset = offset;
  }

  Stage(this.stageImg) {
    final Map<StageObjType, Sprite> stageSprites = {};
    stageSprites[StageObjType.none] =
        Sprite(stageImg, srcPosition: Vector2(0, 0), srcSize: cellSize);
    stageSprites[StageObjType.wall] =
        Sprite(stageImg, srcPosition: Vector2(160, 0), srcSize: cellSize);
    stageSprites[StageObjType.goal] =
        Sprite(stageImg, srcPosition: Vector2(32, 0), srcSize: cellSize);
    stageSprites[StageObjType.box] =
        Sprite(stageImg, srcPosition: Vector2(96, 0), srcSize: cellSize);
    stageSprites[StageObjType.player] =
        Sprite(stageImg, srcPosition: Vector2(128, 0), srcSize: cellSize);

    objFactory =
        StageObjFactory(stageSprites: stageSprites, offset: Vector2(0, 0));
  }

  /// デフォルトのステージを生成する
  void setDefault(Future<void> Function(Iterable<Component>) addAll) {
    // ※必ずwidth,heightを先に設定してからobjFactory.create()する。
    // これは表示場所のoffset計算を先にする必要があるため。
    width = 7;
    height = 7;
    playerPos = Point(3, 4);
    initialPlayerPos = playerPos.copy();
    initialObjsInfo = [
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.none),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.box),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
      [
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
        StageObjTypeLevel(type: StageObjType.wall),
      ],
    ];
    objsInfo = [...initialObjsInfo];
    _drawWithObjsInfo(addAll);
  }

  /// 初期化
  void initialize(void Function() removeAll) {
    isPlayerMoving = false;
    isBoxMoving = false;
    movingAmount = 0;
    movingTo = Move.none;
    boxes.clear();
    moveHistory.clear();
    removeAll();
  }

  /// ステージを初期状態に戻す
  void reset() {
    objsInfo = [...initialObjsInfo];
    playerPos = initialPlayerPos.copy();
    // 荷物位置初期化
    // TODO
    /*
    for (final box in boxes) {
      box.current = box.initial;
      // 描画
      stage.setCellPosition(box.sprite, box.current.x, box.current.y, 0, 0);
    }
    */
    // プレイヤー描画
    objFactory.setPosition(player);

    // 各種変数初期化
    movingBox = null;
    moveHistory.clear();
    isPlayerMoving = false;
    isUndoing = false;
    isBoxMoving = false;
    movingAmount = 0;
    movingTo = Move.none;
  }

/*
  void fillWall() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (objs[y][x].type == StageObjType.none) {
          objs[y][x].type = StageObjType.wall;
        } else if (objs[y][x].type == StageObjType.reservedFloor) {
          objs[y][x].type = StageObjType.none;
        }
      }
    }
  }
*/

  String symboleToStr(StageObjType s) {
    switch (s) {
      case StageObjType.none:
        return ' ';
      case StageObjType.wall:
        return '#';
      case StageObjType.goal:
        return '.';
      case StageObjType.box:
        return 'o';
      case StageObjType.boxOnGoal:
        return 'O';
      case StageObjType.player:
        return 'p';
      case StageObjType.playerOnGoal:
        return 'P';
      case StageObjType.reservedFloor:
        return 'f';
    }
  }

  void logInitialStage() {
    String output = '';
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (Point(x, y) == initialPlayerPos) {
          if (initialObjsInfo[y][x].type == StageObjType.goal) {
            output += symboleToStr(StageObjType.playerOnGoal);
          } else {
            output += symboleToStr(StageObjType.player);
          }
        } else {
          output += symboleToStr(initialObjsInfo[y][x].type);
        }
      }
      if (y < height - 1) output += '\n';
    }
    final logger = Logger();
    logger.i(output);
  }

  void logCurrentStage() {
    String output = '';
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (Point(x, y) == playerPos) {
          if (objsInfo[y][x].type == StageObjType.goal) {
            output += symboleToStr(StageObjType.playerOnGoal);
          } else {
            output += symboleToStr(StageObjType.player);
          }
        } else {
          output += symboleToStr(objsInfo[y][x].type);
        }
      }
      if (y < height - 1) output += '\n';
    }
    final logger = Logger();
    logger.i(output);
  }

  // src->dstへ移動(ワープ)する
  // 移動距離が2マス以上のときは経路上に変化はないので注意
/*
  void moveWarp(Point src, Point dst) {
    StageObjType srcObjType = get(src).type;
    final dstObjType = get(dst).type;
    // 移動元を編集
    if (srcObjType == StageObjType.boxOnGoal) {
      setType(src, StageObjType.goal);
      srcObjType = StageObjType.box;
    } else if (srcObjType == StageObjType.playerOnGoal) {
      setType(src, StageObjType.goal);
      srcObjType = StageObjType.player;
    } else {
      setType(src, StageObjType.reservedFloor);
    }
    // 移動先を編集
    if (dstObjType == StageObjType.goal) {
      if (srcObjType == StageObjType.box) {
        setType(dst, StageObjType.boxOnGoal);
      } else if (srcObjType == StageObjType.player) {
        setType(dst, StageObjType.playerOnGoal);
      }
    } else {
      setType(dst, srcObjType);
    }
  }
*/

  // src->dstへ移動する
/*
  void move(Point src, Point dst) {
    final d = (src.x - dst.x).abs() + (src.y - dst.y).abs();
    if (d == 1) {
      moveWarp(src, dst);
    } else if (d > 1) {
      final pathList = getPath(src, dst);
      if (pathList.isNotEmpty) {
        // 経路上の"確定床"数が最大の経路を用いる＝新たな"確定床"をなるべく作成しない
        pathList.sort((a, b) => -1 * a.fCount.compareTo(b.fCount));
        final onePath = pathList[0].path;
        Point current = src;
        for (final point in onePath) {
          moveWarp(current, point);
          current = point;
        }
        moveWarp(current, dst);
      }
    }
  }
*/

  List<List<int>> combination(List<int> list, int n) {
    return n == 1
        ? list.map((el) => [el]).toList()
        : list.asMap().entries.expand((entry) {
            return combination(list.sublist(entry.key + 1), n - 1)
                .map((el) => [entry.value] + el)
                .toList();
          }).toList();
  }

  // src->dstへの{移動経路, f_count}をリストにして返す。
  // f_count = 経路上にある床確定マスの数
  // 各移動経路は通る点のリスト。ただし、srcとdstは含まない
  // 各移動経路は途中に障害物を含まない(=ちゃんと通れる道だけ入ってる)
  // ※src == dstの場合は空リストが返るので注意
/*
  List<MovePath> getPath(Point src, Point dst) {
    int absX = (dst.x - src.x).abs();
    int absY = (dst.y - src.y).abs();
    // x方向の単位移動
    Point unitX = Point(0, 0);
    if (dst.x - src.x > 0) {
      unitX = Point(1, 0);
    } else if (dst.x - src.x < 0) {
      unitX = Point(-1, 0);
    }
    // y方向の単位移動
    Point unitY = Point(0, 0);
    if (dst.y - src.y > 0) {
      unitY = Point(0, 1);
    } else if (dst.y - src.y < 0) {
      unitY = Point(0, -1);
    }
    // 0～(absX+absY)の配列インデックスのうち、y_abs個を選ぶ組み合わせ
    final combs =
        combination([for (int i = 0; i < (absX + absY); i++) i], absY);

    List<MovePath> ret = [];
    for (final comb in combs) {
      MovePath path = MovePath();
      Point currentPos = Point(src.x, src.y);
      bool canPath = true;
      for (int i = 0; i < (absX + absY - 1); i++) {
        Point oneStep = unitX;
        if (comb.contains(i)) {
          oneStep = unitY;
        }
        currentPos = currentPos + oneStep;
        if (!canMovePlayer(currentPos)) {
          canPath = false;
          break;
        }
        if (get(currentPos).type == StageObjType.reservedFloor) {
          path.fCount++;
        }
        path.path.add(currentPos);
      }
      if (canPath) {
        ret.add(path);
      }
    }
    return ret;
  }
*/

  // プレイヤーが移動できるかどうかを返す
/*
  bool canMovePlayer(Point player) {
    // [人]周りを囲う壁や範囲外に出る
    if (player.x <= 0 ||
        player.x >= width - 1 ||
        player.y <= 0 ||
        player.y >= height - 1) {
      return false;
    }
    // 移動先が壁や箱である
    if ([StageObjType.wall, StageObjType.box, StageObjType.boxOnGoal]
        .contains(get(player).type)) {
      return false;
    }
    return true;
  }
*/

  // 箱の移動先、人の移動先に問題がなく、移動できるかどうかを返す
/*
  bool canMove(Point box, Point player, List<Point> cantMoveList,
      List<Point> cantMoveListForPlayer) {
    final cantMoveObjs = [
      StageObjType.wall,
      StageObjType.box,
      StageObjType.boxOnGoal
    ];
    // [箱]周りを囲う壁や範囲外に出る
    if (box.x <= 0 || box.x >= width - 1 || box.y <= 0 || box.y >= height - 1) {
      return false;
    }
    // [人]周りを囲う壁や範囲外に出る
    if (player.x <= 0 ||
        player.x >= width - 1 ||
        player.y <= 0 ||
        player.y >= height - 1) {
      return false;
    }
    // [箱]移動先が壁や箱である
    if (cantMoveObjs.contains(get(box).type)) {
      return false;
    }
    // [人]移動先が壁や箱である
    if (cantMoveObjs.contains(get(player).type)) {
      return false;
    }
    // [箱]移動不可リストに入っている
    if (cantMoveList.contains(box)) {
      return false;
    }
    // [人]移動不可リストに入っている
    if (cantMoveListForPlayer.contains(player)) {
      return false;
    }
    return true;
  }
*/

  // 特定範囲の左上->右下に振ったインデックス(0始まり)を(x, y)に変換する
/*
  Point indexToPoint(int index, Point rangeLT, Point rangeRB) {
    int rangeW = (rangeRB.x - rangeLT.x) + 1;
    int y = (index / rangeW).floor() + rangeLT.y;
    int x = index % rangeW + rangeLT.x;
    return Point(x, y);
  }
*/

  // 特定範囲の左上->右下の各マスが、指定した中央点から何回移動の距離にあるかをリストに格納したものを返す
/*
  List<int> getDistanceList(Point rangeLT, Point rangeRB, Point center) {
    List<int> ret = [];
    for (int y = rangeLT.y; y < rangeRB.y + 1; y++) {
      for (int x = rangeLT.x; x < rangeRB.x + 1; x++) {
        ret.add((Point(x, y) - center).distance());
      }
    }
    return ret;
  }
*/

/*
  List<Component> setFromText(String stageStr) {
    List<Component> ret = [];
    playerX = -1;
    playerY = -1;
    initialObjs.clear();
    objs.clear();
    // 1行ずつ読み込む
    final strRows = LineSplitter.split(stageStr).toList();
    height = strRows.length;
    // 最初の行の文字数を横幅として決定
    assert(strRows.isNotEmpty, "ステージを表す文字列が空のためステージ生成に失敗しました。");
    width = strRows[0].length;
    for (int y = 0; y < strRows.length; y++) {
      final strRow = strRows[y];
      assert(
          strRow.length == width, "ステージを表す文字列が、各行によって文字数が異なるためステージ生成に失敗しました。");
      final List<StageObj> row = [];
      // 1文字ずつ読み込む
      for (int x = 0; x < strRow.length; x++) {
        switch (strRow[x]) {
          case '#':
            row.add(
                objFactory.create(type: StageObjType.wall, pos: Point(x, y)));
            break;
          case ' ':
            row.add(
                objFactory.create(type: StageObjType.none, pos: Point(x, y)));
            break;
          case 'o':
            row.add(
                objFactory.create(type: StageObjType.box, pos: Point(x, y)));
            break;
          case 'O':
            row.add(objFactory.create(
                type: StageObjType.boxOnGoal, pos: Point(x, y)));
            break;
          case '.':
            row.add(
                objFactory.create(type: StageObjType.goal, pos: Point(x, y)));
            break;
          case 'p':
            assert(playerX < 0, "ステージを表す文字列にプレイヤーが複数存在するため、ステージ生成に失敗しました。");
            playerX = x;
            playerY = y;
            row.add(
                objFactory.create(type: StageObjType.none, pos: Point(x, y)));
            break;
          case 'P':
            assert(playerX < 0, "ステージを表す文字列にプレイヤーが複数存在するため、ステージ生成に失敗しました。");
            playerX = x;
            playerY = y;
            row.add(
                objFactory.create(type: StageObjType.goal, pos: Point(x, y)));
            break;
          default:
            assert(playerX < 0, "ステージを表す文字列に無効な文字が含まれていたため、ステージ生成に失敗しました。");
            break;
        }
      }
      initialObjs.add(row);
    }
    objs = [...initialObjs];
    initialPlayerPos = Point(playerX, playerY);

    assert(playerX >= 0, "ステージを表す文字列にプレイヤーが存在しないため、ステージ生成に失敗しました。");

    assert(!isClear(), "ステージを表す文字列が既にクリア済みの状態のため、ステージ生成に失敗しました。");

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        ret.add(objs[y][x].sprite);
      }
    }
    return ret;
  }

  List<Component> setRandom(int w, int h, int b) {
    List<Component> ret = [];
    width = w;
    height = h;
    // 周りの壁だけのステージを生成
    initialObjs.clear();
    objs.clear();
    for (int y = 0; y < h; y++) {
      final List<StageObj> newRow = [];
      for (int x = 0; x < w; x++) {
        if (x == 0 || x == w - 1 || y == 0 || y == h - 1) {
          newRow.add(
              objFactory.create(type: StageObjType.wall, pos: Point(x, y)));
        } else {
          newRow.add(
              objFactory.create(type: StageObjType.none, pos: Point(x, y)));
        }
      }
      objs.add(newRow);
    }
    int floorNum = 2 * (w + h - 2);

    // 箱とプレイヤーを配置できない場合はassert
    assert(floorNum >= b + 1, "ステージ作成エラー：箱とプレイヤーを配置できる十分な広さがありません。");

    // 箱配置の範囲(囲まれた壁の内側)
    final lt = Point(1, 1);
    final rb = Point(width - 2, height - 2);
    // ランダムな位置に箱を設置
    // 最初の1個を起点に、近くに出現しやすくする
    var random = Random();
    int boxIndex = random.nextInt(floorNum);
    final boxP = indexToPoint(boxIndex, lt, rb);
    final boxFirstPList = [boxP];
    setType(boxP, StageObjType.boxOnGoal);
    // 最初の1個からの距離をリスト化
    final distMap = getDistanceList(lt, rb, boxP);
    // 距離に応じて箱の配置確率を変える
    List<int> boxesMap = [];
    for (final dist in distMap) {
      if (dist == 0) {
        // 1個目と同じ場所には置かない
        boxesMap.add(0);
      } else if (dist <= 2) {
        boxesMap.add(2);
      } else {
        boxesMap.add(1);
      }
    }
    List<int> samplingList = [];
    for (int i = 0; i < boxesMap.length; i++) {
      for (int j = 0; j < boxesMap[i]; j++) {
        samplingList.add(i);
      }
    }
    final boxIndices = samplingList.sample(b - 1);
    for (final index in boxIndices) {
      final boxPos = indexToPoint(index, lt, rb);
      boxFirstPList.add(boxPos);
      setType(boxPos, StageObjType.boxOnGoal);
    }

    // 各箱をそれぞれ4~6マス分引く
    // 最初に選んだ箱が引けない位置だと都合が悪いため、引ける箱を選べるまでループする
    for (int firstSelect = 0; firstSelect < b; firstSelect++) {
      // プレイヤー位置は最初に移動させる箱の位置とする
      Point currentPlayerP = boxFirstPList[firstSelect];
      bool canPullFirst = true; // 最初に選んだ箱を引けたかどうか
      for (int boxIdx = 0; boxIdx < boxFirstPList.length; boxIdx++) {
        Point firstP = boxFirstPList[(firstSelect + boxIdx) % b];
        Point currentP = firstP;
        List<Point> history = [firstP];
        List<Point> history2 = [];
        int moveNum = 4 + random.nextInt(3);
        for (int i = 0; i < moveNum; i++) {
          // 引ける位置の候補
          List<List<Point>> moveCand = [];
          // 上
          Point candUp = currentP + Point(0, -1);
          Point playerUp = currentP + Point(0, -2);
          // プレイヤーは前回位置から箱を引き始める位置へ移動が可能か
          if (currentPlayerP == candUp ||
              getPath(currentPlayerP, candUp).isNotEmpty) {
            // 箱とプレイヤーは引く動作が可能か
            if (canMove(candUp, playerUp, history, history2)) {
              moveCand.add([candUp, playerUp]);
            }
          }
          // 右
          Point candRight = currentP + Point(1, 0);
          Point playerRight = currentP + Point(2, 0);
          if (currentPlayerP == candRight ||
              getPath(currentPlayerP, candRight).isNotEmpty) {
            if (canMove(candRight, playerRight, history, history2)) {
              moveCand.add([candRight, playerRight]);
            }
          }
          // 下
          Point candDown = currentP + Point(0, 1);
          Point playerDown = currentP + Point(0, 2);
          if (currentPlayerP == candDown ||
              getPath(currentPlayerP, candDown).isNotEmpty) {
            if (canMove(candDown, playerDown, history, history2)) {
              moveCand.add([candDown, playerDown]);
            }
          }
          // 左
          Point candLeft = currentP + Point(-1, 0);
          Point playerLeft = currentP + Point(-2, 0);
          if (currentPlayerP == candLeft ||
              getPath(currentPlayerP, candLeft).isNotEmpty) {
            if (canMove(candLeft, playerLeft, history, history2)) {
              moveCand.add([candLeft, playerLeft]);
            }
          }
          // 引ける位置候補の中から一つ選ぶ
          if (moveCand.isEmpty) {
            if (boxIdx == 0 && i == 0) {
              canPullFirst = false;
            }
            break;
          }
          final moveTo = moveCand.sample(1)[0];
          Point boxMoveTo = moveTo[0];
          Point playerMoveTo = moveTo[1];
          // プレイヤーを、箱を引く位置に移動する
          if (boxIdx == 0 && i == 0) {
            setType(boxMoveTo, StageObjType.player);
          } else {
            move(currentPlayerP, boxMoveTo);
          }
          // プレイヤー、箱を引く
          move(boxMoveTo, playerMoveTo);
          // 箱を移動する
          move(currentP, boxMoveTo);
          //print('[$boxIdxの$i回目]');
          //print(boxMoveTo);
          //print(playerMoveTo);
          //show(showScale: true);
          // TODO: これで良い？
          // 一度通った床は次以降の移動先候補にいれない
          history.add(boxMoveTo);
          history2.add(playerMoveTo);
          // 現在の位置を変更
          currentP = boxMoveTo;
          currentPlayerP = playerMoveTo;
        }
        // 選んだ最初の箱を1度も引けなかったなら別の箱を最初に選ぶ
        if (!canPullFirst) {
          break;
        }
      }
      // 最初に選んだ箱が押せたなら、問題作成完了
      if (canPullFirst) {
        // 通過していない床を壁に置き換える
        fillWall();

        // プレイヤーの位置設定
        playerX = currentPlayerP.x;
        playerY = currentPlayerP.y;
        // データ内にはプレイヤーは存在させない
        if (get(Point(playerX, playerY)).type == StageObjType.player) {
          setType(Point(playerX, playerY), StageObjType.none);
        } else if (get(Point(playerX, playerY)) == StageObjType.playerOnGoal) {
          setType(Point(playerX, playerY), StageObjType.goal);
        }
        initialObjs = [...objs];
        initialPlayerPos = Point(playerX, playerY);
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            ret.add(objs[y][x].sprite);
          }
        }
        return ret;
      }
    }
    assert(false, "箱を押すためのスペースが足りず、問題を作成できませんでした。");
    return ret;
  }
*/

  void explode(Point pos, StageObj box,
      Future<void> Function(Iterable<Component>) addAll) {
    // 引数位置を中心として周囲を爆破する
    final List<Point> breaked = [];
    for (int y = pos.y - 1; y < pos.y + 2; y++) {
      for (int x = pos.x - 1; x < pos.x + 2; x++) {
        if (x < 0 || x >= width) continue;
        if (y < 0 || y >= height) continue;
        final p = Point(x, y);
        if (p == pos) continue;
        if (get(p).type == StageObjType.wall &&
            get(p).level <= box.typeLevel.level) {
          setType(p, StageObjType.none);
          staticObjs[p]!.sprite.sprite =
              objFactory.getSprite(StageObjType.none);
          breaked.add(p);
        }
      }
    }
    // 破壊した壁の数/2(切り上げ)個の箱を出現させる
    final boxAppears = breaked.sample((breaked.length / 2).ceil());
    final List<StageObj> adding = [];
    for (final boxAppear in boxAppears) {
      setType(boxAppear, StageObjType.box, level: 1);
      adding.add(objFactory.create(
          typeLevel: StageObjTypeLevel(type: StageObjType.box, level: 1),
          pos: boxAppear));
    }
    boxes.addAll(adding);
    addAll([for (final e in adding) e.sprite]);
    // 当該位置の箱を消す
    final mergedBox = boxes.firstWhere((element) => element.pos == pos);
    mergedBox.valid = false;
    mergedBox.sprite.removeAll(mergedBox.sprite.children);
    mergedBox.sprite.makeTransparent();
    // 消す箱をリストに追加
    invalidBoxes.add(mergedBox);
    boxes.remove(mergedBox);
    // 移動した箱のレベルを上げる
    box.sprite.removeAll(box.sprite.children);
    box.sprite.add(
      AlignComponent(
        alignment: Anchor.center,
        child: TextComponent(
          text: (++box.typeLevel.level).toString(),
          textRenderer: TextPaint(
            style: const TextStyle(
              fontFamily: 'Aboreto',
              color: Color(0xff000000),
            ),
          ),
        ),
      ),
    );
  }

/*
  SpriteComponent getCellSprite(
      StageObj obj, int cellX, int cellY, int px, int py) {
    final internalOffset = Vector2(
        (GameSeq.stageViewSize.x - cellSize.x * width) * 0.5,
        (GameSeq.stageViewSize.y - cellSize.y * height) * 0.5);
    final offset = Vector2(GameSeq.xPaddingSize.x,
            GameSeq.topPaddingSize.y + GameSeq.yPaddingSize.y) +
        internalOffset;
    assert(stageSprites.containsKey(obj), "ステージオブジェクトに対応するスプライトがありません。");
    return SpriteComponent(
      sprite: stageSprites[obj],
      size: cellSize,
      position: (offset +
          Vector2(cellX * cellSize.x, cellY * cellSize.y) +
          Vector2(px.toDouble(), py.toDouble())),
    );
  }
*/

  void setCellPosition(
      SpriteComponent sprite, int cellX, int cellY, int px, int py) {
    final internalOffset = Vector2(
        (GameSeq.stageViewSize.x - cellSize.x * width) * 0.5,
        (GameSeq.stageViewSize.y - cellSize.y * height) * 0.5);
    final offset = Vector2(GameSeq.xPaddingSize.x,
            GameSeq.topPaddingSize.y + GameSeq.yPaddingSize.y) +
        internalOffset;
    sprite.position =
        offset + Vector2(cellX * cellSize.x + px, cellY * cellSize.y + py);
  }

  StageObjTypeLevel get(Point p) {
    return objsInfo[p.y][p.x];
  }

  void setType(Point p, StageObjType type, {int? level}) {
    objsInfo[p.y][p.x].type = type;
    if (level != null) objsInfo[p.y][p.x].level = level;
  }

  void _drawWithObjsInfo(Future<void> Function(Iterable<Component>) addAll) {
    staticObjs.clear();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final objType = get(Point(x, y));
        switch (objType.type) {
          case StageObjType.none:
          case StageObjType.box:
          case StageObjType.player:
          case StageObjType.reservedFloor:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.none, level: objType.level),
                pos: Point(x, y));
            break;
          case StageObjType.wall:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.wall, level: objType.level),
                pos: Point(x, y));
            break;
          case StageObjType.goal:
          case StageObjType.boxOnGoal:
          case StageObjType.playerOnGoal:
            staticObjs[Point(x, y)] = objFactory.create(
                typeLevel: StageObjTypeLevel(
                    type: StageObjType.goal, level: objType.level),
                pos: Point(x, y));
            break;
        }
        if (objType.type == StageObjType.box ||
            objType.type == StageObjType.boxOnGoal) {
          boxes.add(objFactory.create(
              typeLevel: StageObjTypeLevel(
                  type: StageObjType.box, level: objType.level),
              pos: Point(x, y)));
        }
      }
    }
    addAll([for (final e in staticObjs.values) e.sprite]);
    addAll([for (final e in boxes) e.sprite]);

    player = objFactory.create(
        typeLevel: StageObjTypeLevel(type: StageObjType.player, level: 1),
        pos: playerPos);
    addAll([player.sprite]);
  }

  void update(double dt, Move moveInput, bool inputUndo,
      Future<void> Function(Iterable<Component>) addAll) {
    // クリア済みなら何もしない
    if (isClear()) return;
    if (!isPlayerMoving) {
      // 移動中でない場合
      Point to = playerPos.copy();
      Point toTo = playerPos.copy();
      Move move = moveInput;

      switch (moveInput) {
        case Move.left:
          to.x--;
          toTo.x = to.x - 1;
          break;
        case Move.right:
          to.x++;
          toTo.x = to.x + 1;
          break;
        case Move.up:
          to.y--;
          toTo.y = to.y - 1;
          break;
        case Move.down:
          to.y++;
          toTo.y = to.y + 1;
          break;
        default:
          break;
      }
      if (moveInput == Move.none && inputUndo) {
        final lastMove = moveHistory.removeLast();
        final boxPos = to;
        // 履歴の逆に動く
        switch (lastMove.move) {
          case Move.left:
            to.x++;
            toTo.x = to.x + 1;
            boxPos.x--;
            move = Move.right;
            break;
          case Move.right:
            to.x--;
            toTo.x = to.x - 1;
            boxPos.x++;
            move = Move.left;
            break;
          case Move.up:
            to.y++;
            toTo.y = to.y + 1;
            boxPos.y--;
            move = Move.down;
            break;
          case Move.down:
            to.y--;
            toTo.y = to.y - 1;
            boxPos.y++;
            move = Move.up;
            break;
          default:
            break;
        }
        isBoxMoving = lastMove.boxMoved;
        if (isBoxMoving) {
          movingBox = boxes.firstWhere((element) => element.pos == boxPos);
        }
        isUndoing = true;
      } else if (moveInput == Move.none) {
        return;
      }

      // 一手戻す場合以外は移動に関して判定
      if (!isUndoing) {
        // ステージ外に飛び出さないか
        if (to.x < 0 || to.x >= width || to.y < 0 || to.y >= height) {
          return;
        }

        // 壁にぶつかるか
        if (get(to).type == StageObjType.wall) {
          return;
        }

        // 荷物があるか
        if (get(to).type == StageObjType.box ||
            get(to).type == StageObjType.boxOnGoal) {
          // 押せるかどうか
          if (toTo.x < 0 || toTo.x >= width || toTo.y < 0 || toTo.y >= height) {
            return;
          }
          if (get(toTo).type != StageObjType.none &&
              get(toTo).type != StageObjType.goal &&
              get(toTo).type != StageObjType.box) {
            return;
          }
          if (get(toTo).type == StageObjType.box &&
              get(toTo).level != get(to).level) {
            return;
          }
          movingBox = boxes.firstWhere((element) => element.pos == to);
          isBoxMoving = true;
        }
      }
      isPlayerMoving = true;
      movingTo = move;
      movingAmount = 0.0;
    }

    if (isPlayerMoving) {
      // 移動中の場合(このフレームで移動開始した場合を含む)
      // 移動量加算
      movingAmount += dt * playerSpeed;
      if (movingAmount >= Stage.cellSize.x) {
        movingAmount = Stage.cellSize.x;
      }

      // ※※※画像の移動ここから※※※
      // 移動中の場合は画素も考慮
      Vector2 offset = Vector2.zero();

      if (isPlayerMoving) {
        switch (movingTo) {
          case Move.left:
            offset.x = -1 * movingAmount;
            break;
          case Move.right:
            offset.x = movingAmount;
            break;
          case Move.up:
            offset.y = -1 * movingAmount;
            break;
          case Move.down:
            offset.y = movingAmount;
            break;
          default:
            break;
        }
        // プレイヤー位置変更
        objFactory.setPosition(player, offset: offset);
        if (isBoxMoving) {
          // 押している箱の位置変更
          objFactory.setPosition(movingBox!, offset: offset);
        }
      }
      // ※※※画像の移動ここまで※※※

      // 次のマスに移っていたら移動終了
      if (movingAmount >= Stage.cellSize.x) {
        Point to = playerPos.copy();
        Point toTo = playerPos.copy();

        switch (movingTo) {
          case Move.left:
            to.x--;
            if (!isUndoing) toTo.x = to.x - 1;
            break;
          case Move.right:
            to.x++;
            if (!isUndoing) toTo.x = to.x + 1;
            break;
          case Move.up:
            to.y--;
            if (!isUndoing) toTo.y = to.y - 1;
            break;
          case Move.down:
            to.y++;
            if (!isUndoing) toTo.y = to.y + 1;
            break;
          default:
            return;
        }

        // 荷物位置更新
        if (isBoxMoving) {
          switch (get(toTo).type) {
            case StageObjType.none:
              setType(toTo, StageObjType.box,
                  level: movingBox!.typeLevel.level);
              break;
            case StageObjType.goal:
              setType(toTo, StageObjType.boxOnGoal,
                  level: movingBox!.typeLevel.level);
              break;
            case StageObjType.box:
              explode(toTo, movingBox!, addAll);
              setType(toTo, StageObjType.box,
                  level: movingBox!.typeLevel.level);
              break;
            default:
              // ありえない
              //HALT("fatal error");
              break;
          }
          if (isUndoing) {
            switch (get(movingBox!.pos).type) {
              case StageObjType.box:
                setType(movingBox!.pos, StageObjType.none);
                break;
              case StageObjType.boxOnGoal:
                setType(movingBox!.pos, StageObjType.goal);
                break;
              default:
                // ありえない
                //HALT("fatal error");
                break;
            }
          } else {
            switch (get(to).type) {
              case StageObjType.box:
                setType(to, StageObjType.none);
                break;
              case StageObjType.boxOnGoal:
                setType(to, StageObjType.goal);
                break;
              default:
                // ありえない
                //HALT("fatal error");
                break;
            }
          }
          movingBox!.pos = toTo;
          objFactory.setPosition(movingBox!);
          movingBox = null;
        }

        // プレーヤー位置更新
        playerPos = to.copy();
        player.pos = to.copy();
        objFactory.setPosition(player);

        // 移動履歴に追加
        if (!isUndoing) {
          moveHistory.add(MoveHistory(boxMoved: isBoxMoving, move: movingTo));
        }

        // TODO
        // 一手戻すボタンの有効/無効切り替え
//        undoButton!.enabled = moveHistory.isNotEmpty;
        // 無効になったなら一手戻すボタン押されたかフラグをオフに
//        if (moveHistory.isEmpty) {
//          isPushUndo = false;
//        }

        // 各種移動中変数初期化
        isPlayerMoving = false;
        isUndoing = false;
        isBoxMoving = false;
        movingAmount = 0;
        movingTo = Move.none;

        // TODO
//        if (isClear) {
//          game.router.pushNamed('clear');
//        }
      }
    }
  }

  bool isClear() {
    return false;
//    for (int y = 0; y < height; y++) {
//      for (int x = 0; x < width; x++) {
//        if (objs[y][x] == StageObj.box) return false;
//      }
//    }
//    return true;
  }
}
