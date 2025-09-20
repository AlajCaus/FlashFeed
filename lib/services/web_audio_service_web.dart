// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web-specific implementation of audio service
class WebAudioServiceImpl {
  static void playNotificationSound() {
    if (!kIsWeb) return;

    try {
      // Short notification beep sound (base64 encoded)
      const String soundData = 'data:audio/wav;base64,UklGRtQCAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YTAC'
          'AAD//v/+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+'
          '/v7+/v7+/v7+/v7+/v4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQECAQEBAQEBAQEBAQE'
          'BAgECAgICAgMDAwMEBAQFBQUFBgYHBwgICAkJCgoLCwwMDQ0ODg8PEBARERISExMUFBUVFhYXFxgYGRkaGhsb'
          'HBwdHR4eHx8gICEhIiIjIyQkJSUmJicnKCgpKSoqKysAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

      final audio = html.AudioElement(soundData);
      audio.volume = 0.3;
      audio.play().catchError((e) {
        debugPrint('Could not play notification sound: $e');
      });
    } catch (e) {
      debugPrint('Web Audio error: $e');
    }
  }
}