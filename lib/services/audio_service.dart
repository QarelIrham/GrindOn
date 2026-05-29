import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ── Layanan Suara (Audio Service) ─────────────────────────────────
// Mengatur semua efek suara dalam aplikasi (berhasil, klik, gagal, dll).
class AudioService {
  static final AudioPlayer _uiPlayer = AudioPlayer();
  static final AudioPlayer _mainPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static const String _path = 'audio/';
  static bool isEnabled = true;
  static bool isMusicEnabled = true;
  static bool _isInitialized = false;
  static DateTime _lastClickTime = DateTime.now();

  static void init({bool? enabled, bool? musicEnabled}) {
    if (enabled != null) isEnabled = enabled;
    if (musicEnabled != null) {
      isMusicEnabled = musicEnabled;
      if (isMusicEnabled) {
        playBgm();
      } else {
        stopBgm();
      }
    }
    if (_isInitialized) return;

    final ctx = AudioContextConfig(
      respectSilence: false,
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    
    AudioPlayer.global.setAudioContext(ctx);
    _bgmPlayer.setAudioContext(ctx);
    _uiPlayer.setAudioContext(ctx);
    _mainPlayer.setAudioContext(ctx);
    
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    
    _isInitialized = true;
  }

  static Future<void> playBgm() async {
    if (!isMusicEnabled) return;
    try {
      init();
      if (_bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.play(AssetSource('${_path}rpgtheme.mp3'), volume: 0.4);
      }
    } catch (e) {
      debugPrint('BGM Error: $e');
    }
  }

  static Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('BGM Stop Error: $e');
    }
  }

  static Future<void> toggleBgm(bool enable) async {
    isMusicEnabled = enable;
    if (enable) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }

  static Future<void> playSuccess() async {
    if (!isEnabled) return;
    try {
      init();
      await _mainPlayer.stop();
      await _mainPlayer.play(AssetSource('${_path}taskcompleted.m4a'), volume: 0.3);
    } catch (e) {
      debugPrint('Success SFX Error: $e');
    }
  }

  static Future<void> playLevelUp() async {
    if (!isEnabled) return;
    try {
      init();
      await _mainPlayer.stop();
      await _mainPlayer.play(AssetSource('${_path}levelup.mp3'), volume: 0.4);
    } catch (e) {
      debugPrint('LevelUp SFX Error: $e');
    }
  }

  static Future<void> playCoin() async {
    if (!isEnabled) return;
    try {
      init();
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('${_path}buyitem.m4a'), volume: 0.8);
    } catch (e) {
      debugPrint('Coin SFX Error: $e');
    }
  }

  static Future<void> playFail() async {
    if (!isEnabled) return;
    try {
      init();
      await _mainPlayer.stop();
      await _mainPlayer.play(AssetSource('${_path}failtask.m4a'), volume: 0.3);
    } catch (e) {
      debugPrint('Fail SFX Error: $e');
    }
  }

  static Future<void> playClick() async {
    // Disabled as per user request to prevent lag
    return;
  }
}
