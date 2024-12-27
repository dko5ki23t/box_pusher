import 'package:box_pusher/ad_banner.dart';
import 'package:box_pusher/box_pusher_game.dart';
import 'package:box_pusher/config.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main({
  bool testMode = kDebugMode,
  bool showAd = false,
  bool firebase = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (showAd) {
    MobileAds.instance.initialize();
  }
  if (firebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  Locale? locale;
  runApp(
    MaterialApp(
      title: 'Box Pusher',
      home: MyApp(
        initialLocale: locale,
        testMode: testMode,
        showAd: showAd,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final bool testMode;
  final bool showAd;
  const MyApp(
      {required this.initialLocale,
      this.testMode = false,
      this.showAd = false,
      super.key});

  @override
  State<MyApp> createState() => MyAppStateForLocale();
  static MyAppStateForLocale? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppStateForLocale>();
}

class MyAppStateForLocale extends State<MyApp> {
  //Locale? _locale;
  bool showAd = false;
  late Future<void> configFuture;

  /// デバッグ用のTextFieldに当てられたフォーカスを戻すために使用
  final gameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // 各種ゲーム用設定読み込み
    configFuture = Config().initialize();
    showAd = widget.showAd;
    //_locale = widget.initialLocale;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: configFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // ゲーム用設定読み込み完了後にゲーム画面用意
            return Scaffold(
              body: Column(
                children: [
                  Flexible(
                    child: GameWidget.controlled(
                      gameFactory: () => BoxPusherGame(
                          testMode: widget.testMode, gameFocus: gameFocus),
                      loadingBuilder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                      focusNode: gameFocus,
                    ),
                  ),
                  showAd
                      ? FutureBuilder(
                          future: AdSize.getAnchoredAdaptiveBannerAdSize(
                              Orientation.portrait,
                              MediaQuery.of(context).size.width.truncate()),
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<AnchoredAdaptiveBannerAdSize?>
                                snapshot,
                          ) {
                            if (snapshot.hasData) {
                              final data = snapshot.data;
                              if (data != null) {
                                return Container(
                                  height: 70,
                                  color: Colors.white70,
                                  child: AdBanner(size: data),
                                );
                              } else {
                                return Container(
                                  height: 70,
                                  color: Colors.white70,
                                );
                              }
                            } else {
                              return Container(
                                height: 70,
                                color: Colors.white70,
                              );
                            }
                          },
                        )
                      : Container(),
                ],
              ),
            );
          } else {
            // TODO: ロード画面など
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  void setLocale(Locale locale) {
    setState(() {
      //_locale = locale;
    });
  }
}
