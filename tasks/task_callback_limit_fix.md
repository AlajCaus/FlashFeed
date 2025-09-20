# Task: LocationProvider Callback Limit Test Fix

## Problem
Der Performance-Test `should handle concurrent callback registrations without performance degradation` schlägt fehl, weil er versucht 100 Callbacks zu registrieren, aber der LocationProvider ein hartes Limit von 50 Callbacks hat.

## Fehleranalyse
```
Bad state: Maximum location callbacks reached (50). Cannot register more callbacks.
package:flashfeed/providers/location_provider.dart 249:7  LocationProvider.registerLocationChangeCallback
test\location_provider_performance_test.dart 113:28       main.<fn>.<fn>.<fn>
```

## Ursache
- Test registriert 100 Callbacks (Zeile 108-113 in location_provider_performance_test.dart)
- LocationProvider erlaubt maximal 50 Callbacks (_maxLocationCallbacks = 50)
- Bei Callback #51 wird StateError geworfen

## Lösungsoptionen

### Option 1: Test anpassen (EMPFOHLEN)
- Test auf 50 Callbacks reduzieren
- Performance-Test bleibt gültig
- Keine Änderung am Production-Code nötig

### Option 2: Limit erhöhen
- _maxLocationCallbacks von 50 auf 100+ erhöhen
- Könnte DoS-Schutz schwächen
- Nicht empfohlen für Production

### Option 3: Test-spezifische Provider-Instanz
- Test mit eigenem LocationProvider ohne Limits
- Aufwändiger, weniger realistisch

## Implementierung (Option 1)
1. Test von 100 auf 45 Callbacks reduzieren
2. Performance-Anforderung entsprechend anpassen
3. Test validiert weiterhin Concurrent-Performance

## Auswirkungen
- KEINE Breaking Changes
- Test wird realistischer (unter Production-Limits)
- Performance-Validierung bleibt bestehen