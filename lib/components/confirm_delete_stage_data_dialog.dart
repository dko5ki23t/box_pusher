import 'package:box_pusher/box_pusher_game.dart';
import 'package:flutter/material.dart';

class ConfirmDeleteStageDataDialog extends StatefulWidget {
  final BoxPusherGame game;

  const ConfirmDeleteStageDataDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  ConfirmDeleteStageDataDialogState createState() =>
      ConfirmDeleteStageDataDialogState();
}

class ConfirmDeleteStageDataDialogState
    extends State<ConfirmDeleteStageDataDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認'),
      content: const Text('前回プレイしたデータを削除して最初から始めます。\nよろしいですか？'),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.clearAndSaveStageData();
            widget.game.popSeq();
            widget.game.pushAndInitGame();
          },
        ),
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () {
            widget.game.popSeq();
          },
        ),
      ],
    );
  }
}
