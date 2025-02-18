import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/config.dart';
import 'package:flutter/material.dart';

class DebugViewDistributionsDialog extends StatefulWidget {
  final BoxPusherGame game;

  const DebugViewDistributionsDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  DebugViewDistributionsDialogState createState() =>
      DebugViewDistributionsDialogState();
}

class DebugViewDistributionsDialogState
    extends State<DebugViewDistributionsDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final targetPos = widget.game.debugTargetPos;
    final blockFloorDistribution = widget.game.debugBlockFloorDistribution;
    final objInBlockDistribution = widget.game.debugObjInBlockDistribution;
    return AlertDialog(
      title: Text(
        '座標(${targetPos.x}, ${targetPos.y})の情報',
        style: Config.gameTextStyle,
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text('ブロック/床'),
            const Divider(
              height: 10,
              thickness: 0.5,
            ),
            Text('総数：${blockFloorDistribution.totalTotal}'),
            Text('残り：${blockFloorDistribution.remainTotal}'),
            for (final key in blockFloorDistribution.keys)
              Text(
                  '${key.type.name} (${key.level}): ${blockFloorDistribution.getRemainNum(key)}/${blockFloorDistribution.getTotalNum(key)}'),
            const Text('ブロック破壊時出現オブジェクト'),
            const Divider(
              height: 10,
              thickness: 0.5,
            ),
            Text('総数：${objInBlockDistribution.totalTotal}'),
            Text('残り：${objInBlockDistribution.remainTotal}'),
            for (final key in objInBlockDistribution.keys)
              Text(
                  '${key.type.name} (${key.level}): ${objInBlockDistribution.getRemainNum(key)}/${objInBlockDistribution.getTotalNum(key)}'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.popSeq();
            // ゲームでキーボード入力できるように、フォーカスを戻す
            widget.game.gameFocus.requestFocus();
          },
        ),
      ],
    );
  }
}
