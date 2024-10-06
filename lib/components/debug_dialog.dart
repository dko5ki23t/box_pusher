import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/sequences/game_seq.dart';
import 'package:flutter/material.dart';

class DebugDialog extends StatefulWidget {
  final BoxPusherGame game;

  const DebugDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  DebugDialogState createState() => DebugDialogState();
}

class DebugDialogState extends State<DebugDialog> {
  final TextEditingController widthTextController = TextEditingController();
  final TextEditingController heightTextController = TextEditingController();
  final TextEditingController boxNumTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widthTextController.text = widget.game.debugStageWidth.toString();
    heightTextController.text = widget.game.debugStageHeight.toString();
    boxNumTextController.text = widget.game.debugStageBoxNum.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('デバッグ'),
      content: Column(
        children: [
          Flexible(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: widthTextController,
              decoration: const InputDecoration(
                labelText: '幅',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Flexible(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: heightTextController,
              decoration: const InputDecoration(
                labelText: '高さ',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Flexible(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: boxNumTextController,
              decoration: const InputDecoration(
                labelText: '箱の数',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.debugStageWidth =
                int.tryParse(widthTextController.text) ??
                    widget.game.debugStageWidth;
            widget.game.debugStageHeight =
                int.tryParse(heightTextController.text) ??
                    widget.game.debugStageHeight;
            widget.game.debugStageBoxNum =
                int.tryParse(boxNumTextController.text) ??
                    widget.game.debugStageBoxNum;
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
