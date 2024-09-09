import 'dart:convert';
import 'dart:math';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:logger/logger.dart';

/// ステージ上のオブジェクト
enum StageObj {
  none,
  wall,
  goal,
  box,
  boxOnGoal,
  player,
  playerOnGoal,
  reservedFloor, // 何もない床確定
}

/// 移動
enum Move {
  none,
  left,
  right,
  up,
  down,
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

  int distance() {
    return (x.abs() + y.abs());
  }
}

class MovePath {
  List<Point> path = [];
  int fCount = 0;
}

class Stage {
  // ステージ上のオブジェクト
//  static const int objNone = 0;
//	static const int objWall = 1;
//	static const int objGoal = 2;
//	static const int objBox = 3;
//	static const int objBoxOnGoal = 4;
//	static const int objPlayer = 5;
//	static const int objPlayerOnGoal = 6;
//	static const int objSize = 7;

  // 移動
//  static const int moveNone = 0;
//  static const int moveLeft = 1;
//  static const int moveRight = 2;
//  static const int moveUp = 3;
//  static const int moveDown = 4;

//  const unsigned StageObjMatrixX[OBJ_SIZE] = {
//		0,
//		32,
//		16,
//		48,
//		0,		// invalid
//		64,
//		0		// invalid
//	};
//
//	const unsigned StageObjMatrixY[OBJ_SIZE] = {
//		0,
//		0,
//		0,
//		0,
//		0,
//		0,
//		0
//	};
//
//  const unsigned STAGE_NUM = 9;
//	const std::string stageFiles[9] =
//	{
//		"stage1.txt",
//		"stage2.txt",
//		"stage3.txt",
//		"stage4.txt",
//		"stage5.txt",
//		"stage6.txt",
//		"stage7.txt",
//		"stage8.txt",
//		"stage9.txt",
//	};
//
//	const int CLEAR_LIFE_TIME = 1000;		// クリア画面の時間：1秒

  /// マスのサイズ
  static Vector2 get cellSize => Vector2(32.0, 32.0);

  final Image stageImg;

  final Map<StageObj, Sprite> stageSprites = {};

  int width = 0;
  int height = 0;

  /// プレイヤーの位置
  int playerX = -1;
  int playerY = -1;

  /// ステージ構造の初期状態
  List<List<StageObj>> initialObjs = [];
  Point initialPlayerPos = Point(0, 0);

  /// 現在のステージ状態
  List<List<StageObj>> objs = [];

  Stage(this.stageImg) {
    stageSprites[StageObj.none] =
        Sprite(stageImg, srcPosition: Vector2(0, 0), srcSize: cellSize);
    stageSprites[StageObj.wall] =
        Sprite(stageImg, srcPosition: Vector2(64, 0), srcSize: cellSize);
    stageSprites[StageObj.goal] =
        Sprite(stageImg, srcPosition: Vector2(32, 0), srcSize: cellSize);
    stageSprites[StageObj.box] =
        Sprite(stageImg, srcPosition: Vector2(96, 0), srcSize: cellSize);
    stageSprites[StageObj.player] =
        Sprite(stageImg, srcPosition: Vector2(128, 0), srcSize: cellSize);
  }

  void setDefault() {
    initialObjs = [
      [
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall
      ],
      [
        StageObj.wall,
        StageObj.none,
        StageObj.goal,
        StageObj.goal,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.wall
      ],
      [
        StageObj.wall,
        StageObj.none,
        StageObj.box,
        StageObj.box,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.wall
      ],
      [
        StageObj.wall,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.none,
        StageObj.wall
      ],
      [
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall,
        StageObj.wall
      ],
    ];
    objs = [...initialObjs];
    width = 8;
    height = 5;
    playerX = 5;
    playerY = 1;
    initialPlayerPos = Point(playerX, playerY);
  }

  void reset() {
    objs = [...initialObjs];
    playerX = initialPlayerPos.x;
    playerY = initialPlayerPos.y;
  }

  void fillWall() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (objs[y][x] == StageObj.none) {
          objs[y][x] = StageObj.wall;
        } else if (objs[y][x] == StageObj.reservedFloor) {
          objs[y][x] = StageObj.none;
        }
      }
    }
  }

  String symboleToStr(StageObj s) {
    switch (s) {
      case StageObj.none:
        return ' ';
      case StageObj.wall:
        return '#';
      case StageObj.goal:
        return '.';
      case StageObj.box:
        return 'o';
      case StageObj.boxOnGoal:
        return 'O';
      case StageObj.player:
        return 'p';
      case StageObj.playerOnGoal:
        return 'P';
      case StageObj.reservedFloor:
        return 'f';
    }
  }

  void logInitialStage() {
    String output = '';
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (Point(x, y) == initialPlayerPos) {
          if (initialObjs[y][x] == StageObj.goal) {
            output += symboleToStr(StageObj.playerOnGoal);
          } else {
            output += symboleToStr(StageObj.player);
          }
        } else {
          output += symboleToStr(initialObjs[y][x]);
        }
      }
      if (y < height - 1) output += '\n';
    }
    final logger = Logger();
    logger.i(output);
  }

  // src->dstへ移動(ワープ)する
  // 移動距離が2マス以上のときは経路上に変化はないので注意
  void moveWarp(Point src, Point dst) {
    StageObj srcObj = get(src);
    final dstObj = get(dst);
    // 移動元を編集
    if (srcObj == StageObj.boxOnGoal) {
      set(src, StageObj.goal);
      srcObj = StageObj.box;
    } else if (srcObj == StageObj.playerOnGoal) {
      set(src, StageObj.goal);
      srcObj = StageObj.player;
    } else {
      set(src, StageObj.reservedFloor);
    }
    // 移動先を編集
    if (dstObj == StageObj.goal) {
      if (srcObj == StageObj.box) {
        set(dst, StageObj.boxOnGoal);
      } else if (srcObj == StageObj.player) {
        set(dst, StageObj.playerOnGoal);
      }
    } else {
      set(dst, srcObj);
    }
  }

  // src->dstへ移動する
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
        if (get(currentPos) == StageObj.reservedFloor) {
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

  // プレイヤーが移動できるかどうかを返す
  bool canMovePlayer(Point player) {
    // [人]周りを囲う壁や範囲外に出る
    if (player.x <= 0 ||
        player.x >= width - 1 ||
        player.y <= 0 ||
        player.y >= height - 1) {
      return false;
    }
    // 移動先が壁や箱である
    if ([StageObj.wall, StageObj.box, StageObj.boxOnGoal]
        .contains(get(player))) {
      return false;
    }
    return true;
  }

  // 箱の移動先、人の移動先に問題がなく、移動できるかどうかを返す
  bool canMove(Point box, Point player, List<Point> cantMoveList,
      List<Point> cantMoveListForPlayer) {
    final cantMoveObjs = [StageObj.wall, StageObj.box, StageObj.boxOnGoal];
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
    if (cantMoveObjs.contains(get(box))) {
      return false;
    }
    // [人]移動先が壁や箱である
    if (cantMoveObjs.contains(get(player))) {
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

  // 特定範囲の左上->右下に振ったインデックス(0始まり)を(x, y)に変換する
  Point indexToPoint(int index, Point rangeLT, Point rangeRB) {
    int rangeW = (rangeRB.x - rangeLT.x) + 1;
    int y = (index / rangeW).floor() + rangeLT.y;
    int x = index % rangeW + rangeLT.x;
    return Point(x, y);
  }

  // 特定範囲の左上->右下の各マスが、指定した中央点から何回移動の距離にあるかをリストに格納したものを返す
  List<int> getDistanceList(Point rangeLT, Point rangeRB, Point center) {
    List<int> ret = [];
    for (int y = rangeLT.y; y < rangeRB.y + 1; y++) {
      for (int x = rangeLT.x; x < rangeRB.x + 1; x++) {
        ret.add((Point(x, y) - center).distance());
      }
    }
    return ret;
  }

  void setFromText(String stageStr) {
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
            row.add(StageObj.wall);
            break;
          case ' ':
            row.add(StageObj.none);
            break;
          case 'o':
            row.add(StageObj.box);
            break;
          case 'O':
            row.add(StageObj.boxOnGoal);
            break;
          case '.':
            row.add(StageObj.goal);
            break;
          case 'p':
            assert(playerX < 0, "ステージを表す文字列にプレイヤーが複数存在するため、ステージ生成に失敗しました。");
            playerX = x;
            playerY = y;
            row.add(StageObj.none);
            break;
          case 'P':
            assert(playerX < 0, "ステージを表す文字列にプレイヤーが複数存在するため、ステージ生成に失敗しました。");
            playerX = x;
            playerY = y;
            row.add(StageObj.goal);
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
  }

  void setRandom(int w, int h, int b) {
    // 周りの壁だけのステージを生成
    initialObjs.clear();
    objs.clear();
    for (int y = 0; y < h; y++) {
      final List<StageObj> newRow = [];
      for (int x = 0; x < w; x++) {
        if (x == 0 || x == w - 1 || y == 0 || y == h - 1) {
          newRow.add(StageObj.wall);
        } else {
          newRow.add(StageObj.none);
        }
      }
      objs.add(newRow);
    }
    int floorNum = 2 * (w + h - 2);

    // 箱とプレイヤーを配置できない場合はassert
    assert(floorNum >= b + 1, "ステージ作成エラー：箱とプレイヤーを配置できる十分な広さがありません。");

    width = w;
    height = h;

    // 箱配置の範囲(囲まれた壁の内側)
    final lt = Point(1, 1);
    final rb = Point(width - 2, height - 2);
    // ランダムな位置に箱を設置
    // 最初の1個を起点に、近くに出現しやすくする
    var random = Random();
    int boxIndex = random.nextInt(floorNum);
    final boxP = indexToPoint(boxIndex, lt, rb);
    final boxFirstPList = [boxP];
    set(boxP, StageObj.boxOnGoal);
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
      set(boxPos, StageObj.boxOnGoal);
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
            set(boxMoveTo, StageObj.player);
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
        if (get(Point(playerX, playerY)) == StageObj.player) {
          set(Point(playerX, playerY), StageObj.none);
        } else if (get(Point(playerX, playerY)) == StageObj.playerOnGoal) {
          set(Point(playerX, playerY), StageObj.goal);
        }
        initialObjs = [...objs];
        initialPlayerPos = Point(playerX, playerY);
        return;
      }
    }
    assert(false, "箱を押すためのスペースが足りず、問題を作成できませんでした。");
  }

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

  StageObj get(Point p) {
    return objs[p.y][p.x];
  }

  void set(Point p, StageObj obj) {
    objs[p.y][p.x] = obj;
  }

  bool isClear() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (objs[y][x] == StageObj.box) return false;
      }
    }
    return true;
  }
}
