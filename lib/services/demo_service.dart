import 'package:flutter/foundation.dart';

/// Service für Demo-Modus-Funktionalität
///
/// Verwaltet Demo-spezifische Features wie:
/// - Auto-Login als Premium User
/// - Demo-Daten-Reset
/// - Guided Tour
/// - Performance-Metriken
class DemoService {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  // Demo-Modus aktiv?
  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  // Demo-Features
  bool _showGuidedTour = false;
  bool _showPerformanceMetrics = false;
  DateTime? _demoStartTime;

  bool get showGuidedTour => _showGuidedTour;
  bool get showPerformanceMetrics => _showPerformanceMetrics;

  /// Demo-Modus aktivieren
  /// Wird durch URL-Parameter ?demo=true ausgelöst
  void activateDemoMode({
    bool autoLogin = true,
    bool guidedTour = false,
    bool performanceMetrics = false,
  }) {
    _isDemoMode = true;
    _showGuidedTour = guidedTour;
    _showPerformanceMetrics = performanceMetrics;
    _demoStartTime = DateTime.now();

    if (kDebugMode) {
    }
  }

  /// Demo-Modus deaktivieren
  void deactivateDemoMode() {
    _isDemoMode = false;
    _showGuidedTour = false;
    _showPerformanceMetrics = false;
    _demoStartTime = null;

    if (kDebugMode) {
    }
  }

  /// Demo-Daten zurücksetzen
  /// Lädt vordefinierte Beispieldaten für Demo
  Future<void> resetDemoData() async {
    if (!_isDemoMode) return;

    if (kDebugMode) {
    }

    // Simulierte Verzögerung
    await Future.delayed(const Duration(seconds: 1));

    // Hier würden wir normalerweise:
    // - Provider zurücksetzen
    // - Vordefinierte Demo-Daten laden
    // - Cache leeren

    if (kDebugMode) {
    }
  }

  /// Demo-Session-Dauer abrufen
  Duration? getDemoSessionDuration() {
    if (_demoStartTime == null) return null;
    return DateTime.now().difference(_demoStartTime!);
  }

  /// Demo-URL generieren
  /// Generiert eine URL die zur Landing Page oder App Stores führt
  String generateDemoUrl({
    String baseUrl = 'https://flashfeed.app',
    bool includePremium = true,
    bool includeGuidedTour = false,
    bool includeMetrics = false,
  }) {
    // Immer GitHub Pages URL verwenden
    String landingPageUrl = 'https://alajcaus.github.io/FlashFeed/';

    // Füge Query-Parameter für Demo-Features hinzu
    List<String> params = [];
    if (includePremium) params.add('premium=true');
    if (includeGuidedTour) params.add('tour=true');
    if (includeMetrics) params.add('metrics=true');

    if (params.isNotEmpty) {
      landingPageUrl += '?${params.join('&')}';
    }

    return landingPageUrl;
  }

  /// URL-Parameter parsen und Demo-Modus aktivieren wenn nötig
  void handleUrlParameters(Map<String, String> params) {
    if (params['demo'] == 'true') {
      activateDemoMode(
        autoLogin: params['premium'] == 'true',
        guidedTour: params['tour'] == 'true',
        performanceMetrics: params['metrics'] == 'true',
      );
    }
  }

  /// Demo-Statistiken für Präsentation
  Map<String, dynamic> getDemoStatistics() {
    return {
      'sessionDuration': getDemoSessionDuration()?.inSeconds ?? 0,
      'isDemoMode': _isDemoMode,
      'features': {
        'guidedTour': _showGuidedTour,
        'performanceMetrics': _showPerformanceMetrics,
      },
      'startTime': _demoStartTime?.toIso8601String(),
    };
  }
}