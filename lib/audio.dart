import 'package:flame_audio/flame_audio.dart';

/// 効果音
enum Sound {
  /// 決定音
  decide,

  /// マージ音
  merge,

  /// 動物救出時（特殊効果ゲット）
  getSkill,

  /// ボム爆発時
  explode,

  /// トラップレベル1、穴に落として敵を倒す
  trap1,
}

extension SoundExtent on Sound {
  String get fileName {
    switch (this) {
      case Sound.decide:
        return 'kettei.mp3';
      case Sound.merge:
        return 'merge.mp3';
      case Sound.getSkill:
        return 'get_skill.mp3';
      case Sound.explode:
        return 'explode.mp3';
      case Sound.trap1:
        return 'trap1.mp3';
    }
  }
}

/// BGUM
enum Bgm {
  /// ゲームプレイ中のBGM
  game,
}

extension BgmExtent on Bgm {
  String get fileName {
    switch (this) {
      case Bgm.game:
        return 'maou_bgm_8bit29.mp3';
    }
  }
}

bool isLoaded = false;

/// 音楽を扱うクラス
/// 最初に1度onLoad()を呼ぶこと
class Audio {
  static Future<void> onLoad() async {
    assert(!isLoaded, '[Audioクラス]onLoad()が2回呼ばれた');
    // キャッシュクリア
    await FlameAudio.audioCache.clearAll();
    // 各種音楽ファイル読み込み
    await FlameAudio.audioCache
        .loadAll([for (final bgm in Bgm.values) bgm.fileName]);
    await FlameAudio.audioCache
        .loadAll([for (final sound in Sound.values) sound.fileName]);
    // BGMの準備
    FlameAudio.bgm.initialize();
    isLoaded = true;
  }

  static Future<AudioPlayer> playSound(Sound sound) {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    return FlameAudio.play(sound.fileName);
  }

  static Future<void> playBGM(Bgm bgm) {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    return FlameAudio.bgm.play(bgm.fileName);
  }

  static Future<void> stopBGM() {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    return FlameAudio.bgm.stop();
  }

  static Future<void> pauseBGM() {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    return FlameAudio.bgm.pause();
  }

  static Future<void> resumeBGM() {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    return FlameAudio.bgm.resume();
  }

  static Future<void> onRemove() async {
    assert(!isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    // キャッシュクリア
    await FlameAudio.audioCache.clearAll();
  }
}
