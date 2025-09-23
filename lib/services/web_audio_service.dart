import 'package:flutter/foundation.dart';

/// Web Audio Service for notification sounds
/// Uses conditional imports for web/mobile compatibility
class WebAudioService {
  static void playNotificationSound() {
    if (kIsWeb) {
      _playWebSound();
    } else {
      // On mobile, we could use a different approach
    }
  }

  static void _playWebSound() {
    // This will be overridden by web implementation
  }
}