import 'dart:typed_data';

import 'package:push_and_merge/box_pusher_game.dart';
import 'package:push_and_merge/config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Uri getUri(String version, BrowserName browser) {
  String browserStr = browserNameToStr(browser);
  String uriStr =
      'https://docs.google.com/forms/d/e/1FAIpQLSc2fFJXiIbSTLMSyxgNzHZrheXBoQgXcfu2iyml30ZPmXbQVg/viewform?usp=pp_url&entry.14906963=$version';
  if (browserStr != "不明") {
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
      return "Internet+Explore";
    case BrowserName.opera:
      return "Opera";
    case BrowserName.samsungInternet:
      return "Samsung";
    case BrowserName.unknown:
      return "不明";
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
  final TextEditingController seedTextController = TextEditingController();
  late final int minStageWidth;
  late final int maxStageWidth;
  late final int minStageHeight;
  late final int maxStageHeight;
  late int enemyDamageInMerge;
  late int enemyDamageInExplosion;
  late bool enemyCanCollidePlayer;
  late int? randomSeed;

  @override
  void initState() {
    super.initState();
    widthTextController.text = Config().debugStageWidth.toString();
    heightTextController.text = Config().debugStageHeight.toString();
    seedTextController.text = Config().debugRandomSeed == null
        ? ''
        : Config().debugRandomSeed.toString();
    minStageWidth = Config().debugStageWidthClamps[0];
    maxStageWidth = Config().debugStageWidthClamps[1];
    minStageHeight = Config().debugStageHeightClamps[0];
    maxStageHeight = Config().debugStageHeightClamps[1];
    enemyDamageInMerge = Config().debugEnemyDamageInMerge;
    enemyDamageInExplosion = Config().debugEnemyDamageInExplosion;
    enemyCanCollidePlayer = Config().debugEnemyCanCollidePlayer;
    randomSeed = Config().debugRandomSeed;
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
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: "マージで敵に与えるダメージ",
            ),
            items: const [
              DropdownMenuItem(
                  value: 0,
                  child: Text(
                    '0 (ダメージなし)',
                    style: Config.gameTextStyle,
                  )),
              DropdownMenuItem(
                  value: 1,
                  child: Text(
                    '1 (レベルを1下げる)',
                    style: Config.gameTextStyle,
                  )),
              DropdownMenuItem(
                  value: 100,
                  child: Text(
                    '100 (一撃で倒す)',
                    style: Config.gameTextStyle,
                  )),
            ],
            value: enemyDamageInMerge,
            onChanged: (value) => enemyDamageInMerge = value ?? 0,
          ),
          const SizedBox(
            height: 10,
          ),
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: "爆弾の爆発で敵に与えるダメージ",
            ),
            items: const [
              DropdownMenuItem(
                  value: 0,
                  child: Text(
                    '0 (ダメージなし)',
                    style: Config.gameTextStyle,
                  )),
              DropdownMenuItem(
                  value: 1,
                  child: Text(
                    '1 (レベルを1下げる)',
                    style: Config.gameTextStyle,
                  )),
              DropdownMenuItem(
                  value: 100,
                  child: Text(
                    '100 (一撃で倒す)',
                    style: Config.gameTextStyle,
                  )),
            ],
            value: enemyDamageInExplosion,
            onChanged: (value) => enemyDamageInExplosion = value ?? 0,
          ),
          const SizedBox(
            height: 10,
          ),
          const SizedBox(
            height: 10,
          ),
          SwitchListTile(
            value: enemyCanCollidePlayer,
            onChanged: (value) => setState(() => enemyCanCollidePlayer = value),
            title: const Text(
              "敵がプレイヤーの移動先と同じマスに移動できるようにする",
              style: Config.gameTextStyle,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SwitchListTile(
            value: randomSeed != null,
            onChanged: (value) {
              if (value) {
                int? textParse = int.tryParse(seedTextController.text);
                if (textParse == null) {
                  textParse = 1234;
                  seedTextController.text = '1234';
                }
                randomSeed = textParse;
              } else {
                randomSeed = null;
              }
              setState(() {});
            },
            title: TextField(
              keyboardType: TextInputType.number,
              enabled: randomSeed != null,
              controller: seedTextController,
              decoration: const InputDecoration(
                labelText: '乱数シード値',
                border: OutlineInputBorder(),
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
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: FutureBuilder<WebBrowserInfo>(
              future: Future<WebBrowserInfo>(() async {
                return (await DeviceInfoPlugin().webBrowserInfo);
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return snapshot.data == null
                      ? const Text('アプリ版(ブラウザなし)')
                      : Text(
                          '使用ブラウザ：${browserNameToStr(snapshot.data!.browserName)} ${snapshot.data!.platform}');
                } else {
                  return const Text('使用ブラウザ：読み込み中...');
                }
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: TextButton(
              child: const Text(
                'セーブデータをインポート...',
                style: Config.gameTextStyle,
              ),
              onPressed: () async {
                // ファイル選択ダイアログ
                const XTypeGroup typeGroup = XTypeGroup(
                  label: 'json',
                  extensions: ['json'],
                );
                final XFile? file =
                    await openFile(acceptedTypeGroups: [typeGroup]);
                if (file == null) {
                  return;
                }
                final String fileContent = await file.readAsString();
                await widget.game.importSaveDataFromString(fileContent);
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: TextButton(
              child: const Text(
                'セーブデータをエクスポート...',
                style: Config.gameTextStyle,
              ),
              onPressed: () async {
                const String fileName = 'save_data.json';
                final FileSaveLocation? result =
                    await getSaveLocation(suggestedName: fileName);
                if (result == null) {
                  // Operation was canceled by the user.
                  return;
                }

                final Uint8List fileData = Uint8List.fromList(
                    widget.game.exportSaveDataToString().codeUnits);
                const String mimeType = 'application/json';
                final XFile textFile = XFile.fromData(fileData,
                    mimeType: mimeType, name: fileName);
                await textFile.saveTo(result.path);
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Config().debugStageWidth =
                (int.tryParse(widthTextController.text) ??
                        Config().debugStageWidth)
                    .clamp(minStageWidth, maxStageWidth);
            Config().debugStageHeight =
                (int.tryParse(heightTextController.text) ??
                        Config().debugStageHeight)
                    .clamp(minStageHeight, maxStageHeight);
            Config().debugEnemyDamageInMerge = enemyDamageInMerge;
            Config().debugEnemyDamageInExplosion = enemyDamageInExplosion;
            Config().debugEnemyCanCollidePlayer = enemyCanCollidePlayer;
            Config().debugRandomSeed = randomSeed == null
                ? null
                : int.tryParse(seedTextController.text);
            widget.game.popSeq();
            // ゲームでキーボード入力できるように、フォーカスを戻す
            widget.game.gameFocus.requestFocus();
            //widget.game.pushAndInitGame();
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
