import 'package:push_and_merge/box_pusher_game.dart';
import 'package:flame/components.dart';

abstract class Sequence extends Component with HasGameReference<BoxPusherGame> {
  Language _prevLang = Language.japanese;

  void onFocus(String? before) {
    // do nothing
  }

  void onUnFocus() {
    // do nothing
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.lang != _prevLang) {
      onLangChanged();
    }
    _prevLang = game.lang;
  }

  void onLangChanged();
}
