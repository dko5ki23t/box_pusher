import 'package:box_pusher/box_pusher_game.dart';
import 'package:flutter/material.dart';

class ConfirmExitDialog extends StatefulWidget {
  final BoxPusherGame game;

  const ConfirmExitDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  ConfirmExitDialogState createState() => ConfirmExitDialogState();
}

class ConfirmExitDialogState extends State<ConfirmExitDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認'),
      content: const Text('ゲームをあきらめますか？\n（ここまでのスコアは記録され、セーブデータは消えます。）'),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.setGameover();
            widget.game.popSeq();
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
