import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// 効果音
enum Sound {
  /// 決定音
  decide,

  /// マージ音
  merge,

  /// マージ一定数達成によるアイテム出現音
  spawn,

  /// 動物救出時（特殊効果ゲット）
  getSkill,

  /// ボム爆発時
  explode,

  /// ワープ使用時
  warp,

  /// トラップレベル1、穴に落として敵を倒す
  trap1,
}

extension SoundExtent on Sound {
  String get fileName {
    switch (this) {
      case Sound.decide:
        return 'audio/kettei.mp3';
      case Sound.merge:
        return 'audio/merge.mp3';
      case Sound.spawn:
        return 'audio/spawn.mp3';
      case Sound.getSkill:
        return 'audio/get_skill.mp3';
      case Sound.explode:
        return 'audio/explode.mp3';
      case Sound.warp:
        return 'audio/warp.mp3';
      case Sound.trap1:
        return 'audio/trap1.mp3';
    }
  }

  double get volume {
    switch (this) {
      case Sound.merge:
      case Sound.explode:
      case Sound.warp:
      case Sound.trap1:
        return 0.8;
      case Sound.decide:
      case Sound.getSkill:
      case Sound.spawn:
        return 1.0;
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
        return 'audio/maou_bgm_8bit29.mp3';
    }
  }

  double get volume {
    switch (this) {
      case Bgm.game:
        return 0.3;
    }
  }
}

bool isLoaded = false;

class AudioPlayerWithStatus {
  final AudioPlayer player;
  bool isBusy = false;

  AudioPlayerWithStatus(this.player);
}

/// 音楽を扱うクラス
/// 最初に1度onLoad()を呼ぶこと
class Audio {
  static final Audio _instance = Audio._internal();

  factory Audio() => _instance;

  Audio._internal();

  /// 同時に再生できる効果音の数
  final int soundPlayerNum = 5;

  late AudioPlayer _bgmPlayer;
  late List<AudioPlayerWithStatus> _soundPlayers;

  final bgmPlayerIdStr = 'box_pusher_bgm_playerId';

  Future<void> onLoad() async {
    assert(!isLoaded, '[Audioクラス]onLoad()が2回呼ばれた');
    // 各種音楽ファイル読み込み
    AudioCache(prefix: 'assets/audio/');

    // https://qiita.com/kaedeee/items/001635c30f9d8ccbf755
    //const AudioContext audioContext = AudioContext(
    //  iOS: AudioContextIOS(
    //    category: AVAudioSessionCategory.ambient,
    //    options: [
    //      AVAudioSessionOptions.defaultToSpeaker,
    //      AVAudioSessionOptions.mixWithOthers,
    //      AVAudioSessionOptions.allowAirPlay,
    //      AVAudioSessionOptions.allowBluetooth,
    //      AVAudioSessionOptions.allowBluetoothA2DP,
    //    ],
    //  ),
    //  android: AudioContextAndroid(
    //    isSpeakerphoneOn: true,
    //    stayAwake: true,
    //    contentType: AndroidContentType.sonification,
    //    usageType: AndroidUsageType.assistanceSonification,
    //    audioFocus: AndroidAudioFocus.none,
    //  ),
    //);

    //AudioPlayer.global.setAudioContext(audioContext);

    _bgmPlayer = AudioPlayer(playerId: bgmPlayerIdStr);
    // BGMはループ再生するよう設定
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _soundPlayers = [
      for (int i = 0; i < soundPlayerNum; i++)
        AudioPlayerWithStatus(AudioPlayer()
          ..onPlayerComplete.listen((event) {
            _soundPlayers[i].isBusy = false;
          }))
    ];
    isLoaded = true;
  }

  Future<void> playSound(Sound sound) async {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    for (final player in _soundPlayers) {
      if (!player.isBusy) {
        player.isBusy = true;
        try {
          await player.player.play(
            AssetSource(sound.fileName),
            volume: sound.volume,
          );
        } catch (e) {
          log('[Audio]playSound() error : $e');
          player.isBusy = false;
        }
        return;
      }
    }
    log('[Audio.playSound()] 全てのプレイヤーが使用中のため再生できなかった：${sound.name}');
  }

  Future<void> playBGM(Bgm bgm) async {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource(bgm.fileName), volume: bgm.volume);
    } catch (e) {
      log('[Audio]playBGM() error : $e');
    }
  }

  Future<void> stopBGM() async {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    await _bgmPlayer.stop();
  }

  Future<void> pauseBGM() async {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    await _bgmPlayer.pause();
  }

  Future<void> resumeBGM() async {
    assert(isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    await _bgmPlayer.resume();
  }

  Future<void> onRemove() async {
    assert(!isLoaded, '[Audioクラス]まだonLoad()が呼ばれてない');
    await _bgmPlayer.dispose();
    for (final player in _soundPlayers) {
      await player.player.dispose();
    }
  }
}
