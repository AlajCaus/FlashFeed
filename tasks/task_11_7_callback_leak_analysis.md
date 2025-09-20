# Task 11.7: Callback-Leak Analysis & Fix

## Problem Identifiziert:
Der Memory leak prevention Test in `cross_provider_integration_test.dart` zeigt 103 Regional-Data-Callbacks beim ersten Location-Update, obwohl nur 3 erwartet werden.

## Root Cause:
**Closure-Referenz-Problem** in Zeile 375-379:
```dart
for (int i = 0; i < 100; i++) {
  void callback(String? plz, List<String> retailers) {  // ❌ Lokale Funktion
    // Dummy operation
  }
  callbacks.add(callback);
  locationProvider.registerRegionalDataCallback(callback);
}
```

Das Problem: Die lokale Funktion `callback` wird in jeder Iteration **neu erstellt** und ist daher bei der Unregistrierung **nicht identisch** mit der registrierten Referenz.

## Resource-Impact für Kunden:
- **103 Callbacks = 34x mehr CPU-Verbrauch** bei jedem Location-Update
- **Memory-Leak:** Callbacks bleiben im Speicher ohne Cleanup
- **Battery Drain:** Unnötige Callback-Ausführungen
- **Performance-Degradation:** App wird bei Location-Changes langsamer

## Solution Strategy:
1. **Fix Test:** Verwende Named Functions oder explizite Referenzen
2. **Add Production Safety:** Defensive Callback-Limits
3. **Add Monitoring:** Callback-Count-Logging für Production-Debugging
4. **Add Cleanup Verification:** Assert Callback-Count nach Unregistration

## Customer Impact:
- **Ohne Fix:** App wird auf Resource-beschränkten Geräten unbenutzbar
- **Mit Fix:** Garantierte Performance auch bei vielen Location-Updates

## Next Steps:
1. Fix Test-Implementation
2. Add defensive checks in LocationProvider
3. Add callback count monitoring
4. Verify fix with stress test