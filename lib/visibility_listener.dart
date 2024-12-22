import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

/// アプリ/Webページの表示/非表示リスナー
class VisibilityListener {
  static void setListeners({
    required void Function() onShow,
    required void Function() onHide,
  }) {
    if (kIsWeb) {
      html.document.addEventListener('visibilitychange', (event) {
        if (html.document.hidden == true) {
          onHide();
        } else {
          onShow();
        }
      });
    } else {
      AppLifecycleListener(
        onShow: onShow,
        onHide: onHide,
      );
    }
  }
}
