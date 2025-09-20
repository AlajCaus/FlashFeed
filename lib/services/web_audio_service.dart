import 'package:flutter/foundation.dart';

/// Web Audio Service for notification sounds
/// Uses conditional imports for web/mobile compatibility
class WebAudioService {
  static void playNotificationSound() {
    if (kIsWeb) {
      _playWebSound();
    } else {
      // On mobile, we could use a different approach
      debugPrint('Notification sound: Mobile implementation not yet available');
    }
  }

  static void _playWebSound() {
    // This will be overridden by web implementation
    debugPrint('Web Audio: Playing notification sound');
  }
}