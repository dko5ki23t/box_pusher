import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _url = Uri.parse('https://forms.gle/F1BTY8KL6NZkBoyo7');

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
  late final int minStageWidth;
  late final int maxStageWidth;
  late final int minStageHeight;
  late final int maxStageHeight;

  @override
  void initState() {
    super.initState();
    widthTextController.text = widget.game.debugStageWidth.toString();
    heightTextController.text = widget.game.debugStageHeight.toString();
    minStageWidth = widget.game.debugStageWidthClamps[0];
    maxStageWidth = widget.game.debugStageWidthClamps[1];
    minStageHeight = widget.game.debugStageHeightClamps[0];
    maxStageHeight = widget.game.debugStageHeightClamps[1];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'デバッグ',
        style: Config.gameTextStyle,
      ),
      content: Column(
        children: [
          Flexible(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: widthTextController,
              decoration: InputDecoration(
                labelText: 'ステージの最大幅($minStageWidth~$maxStageWidth)',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: heightTextController,
              decoration: InputDecoration(
                labelText: 'ステージの最大高さ($minStageHeight~$maxStageHeight)',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: TextButton(
              child: const Text(
                'バグ報告(Google Formを開きます)',
                style: Config.gameTextStyle,
              ),
              onPressed: () async {
                if (!await launchUrl(_url)) {}
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.debugStageWidth =
                (int.tryParse(widthTextController.text) ??
                        widget.game.debugStageWidth)
                    .clamp(minStageWidth, maxStageWidth);
            widget.game.debugStageHeight =
                (int.tryParse(heightTextController.text) ??
                        widget.game.debugStageHeight)
                    .clamp(minStageHeight, maxStageHeight);
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
