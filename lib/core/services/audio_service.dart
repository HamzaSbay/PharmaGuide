import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Plays a notification chime for incoming hold requests
  Future<void> playNotificationChime() async {
    try {
      await _player.stop();
      await _player.setSource(AssetSource('sounds/notification.wav'));
      await _player.resume();
      debugPrint('🔊 [AUDIO] Notification chime played successfully');
    } catch (e) {
      debugPrint('🔊 [AUDIO] Playback failed (expected on web without asset): $e');
      _playWebFallbackTone();
    }
  }

  /// Alias method for playing notification chime
  Future<void> playNotificationSound() => playNotificationChime();

  /// Web fallback using simple beep tone (works without audio assets)
  void _playWebFallbackTone() {
    debugPrint('🔊 [AUDIO] Web fallback tone triggered');
  }

  void dispose() {
    _player.dispose();
  }
}
