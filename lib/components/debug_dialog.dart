import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Uri getUri(String version, BrowserName browser) {
  late String browserStr = '';
  switch (browser) {
    case BrowserName.chrome:
      browserStr = "Google+Chrome";
      break;
    case BrowserName.edge:
      browserStr = "Edge";
      break;
    case BrowserName.firefox:
      browserStr = "Firefox";
      break;
    case BrowserName.safari:
      browserStr = "Safari";
      break;
    case BrowserName.msie:
    case BrowserName.opera:
    case BrowserName.samsungInternet:
    case BrowserName.unknown:
      browserStr = '';
      break;
  }
  String uriStr =
      'https://docs.google.com/forms/d/e/1FAIpQLSc2fFJXiIbSTLMSyxgNzHZrheXBoQgXcfu2iyml30ZPmXbQVg/viewform?usp=pp_url&entry.14906963=$version';
  if (browserStr.isNotEmpty) {
    uriStr += '&entry.282092769=$browserStr';
  }

  return Uri.parse(uriStr);
}

String browserNameToStr(BrowserName name) {
  switch (name) {
    case BrowserName.chrome:
      return "Google+Chrome";
    case BrowserName.edge:
      return "Edge";
    case BrowserName.firefox:
      return "Firefox";
    case BrowserName.safari:
      return "Safari";
    case BrowserName.msie:
    case BrowserName.opera:
    case BrowserName.samsungInternet:
    case BrowserName.unknown:
      return "";
  }
}

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
                // バグ報告で使用しているブラウザを取得するために使う
                DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                // アプリバージョン等取得
                PackageInfo packageInfo = await PackageInfo.fromPlatform();
                final browserName =
                    (await deviceInfo.webBrowserInfo).browserName;
                if (!await launchUrl(getUri(packageInfo.version, browserName),
                    mode: LaunchMode.externalApplication)) {}
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
