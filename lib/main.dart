import 'package:box_pusher/ad_banner.dart';
import 'package:box_pusher/box_pusher_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main({
  bool testMode = kDebugMode,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  Locale? locale;
  runApp(
    MaterialApp(
      title: 'Box Pusher',
      home: MyApp(
        initialLocale: locale,
        testMode: testMode,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final bool testMode;
  const MyApp({required this.initialLocale, this.testMode = false, super.key});

  @override
  State<MyApp> createState() => MyAppStateForLocale();
  static MyAppStateForLocale? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppStateForLocale>();
}

class MyAppStateForLocale extends State<MyApp> {
  Locale? _locale;
  bool showAd = true;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            child: GameWidget.controlled(
              gameFactory: () => BoxPusherGame(testMode: widget.testMode),
            ),
          ),
          showAd
              ? FutureBuilder(
                  future: AdSize.getAnchoredAdaptiveBannerAdSize(
                      Orientation.portrait,
                      MediaQuery.of(context).size.width.truncate()),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<AnchoredAdaptiveBannerAdSize?> snapshot,
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
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
}
