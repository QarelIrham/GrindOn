import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ── Layanan Suara (Audio Service) ─────────────────────────────────
// Mengatur semua efek suara dalam aplikasi (berhasil, klik, gagal, dll).
class AudioService {
  static final AudioPlayer _uiPlayer = AudioPlayer();
  static final AudioPlayer _mainPlayer = AudioPlayer();
  static const String _path = 'lib/assets/audio/';
  static bool isEnabled = true;
  static bool _isInitialized = false;
  static DateTime _lastClickTime = DateTime.now();

  static void init({bool? enabled}) {
    if (enabled != null) isEnabled = enabled;
    if (_isInitialized) return;
    
    _uiPlayer.audioCache.prefix = '';
    _mainPlayer.audioCache.prefix = '';
    
    _isInitialized = true;
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
    if (!isEnabled) return;
    
    final now = DateTime.now();
    if (now.difference(_lastClickTime).inMilliseconds < 50) return;
    _lastClickTime = now;

    try {
      init();
      await _uiPlayer.stop();
      await _uiPlayer.play(AssetSource('${_path}menuclick.m4a'), volume: 0.3);
    } catch (e) {
      debugPrint('Click SFX Error: $e');
    }
  }
}
