import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // テスト用広告
      return 'ca-app-pub-3940256099942544/6300978111';
      //return 'ca-app-pub-5298352571661081/8543241986';
    } else if (Platform.isIOS) {
      // テスト用広告
      //return 'ca-app-pub-3940256099942544/1458002511';
      return 'ca-app-pub-5298352571661081/4328496934';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /*static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return '<YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID>';
    } else if (Platform.isIOS) {
      return '<YOUR_IOS_INTERSTITIAL_AD_UNIT_ID>';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return '<YOUR_ANDROID_REWARDED_AD_UNIT_ID>';
    } else if (Platform.isIOS) {
      return '<YOUR_IOS_REWARDED_AD_UNIT_ID>';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get appopenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5298352571661081/8354805618';
      // テスト広告
      //return 'ca-app-pub-3940256099942544/9257395921';
    } else if (Platform.isIOS) {
      return '<YOUR_IOS_REWARDED_AD_UNIT_ID>';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }*/
}
