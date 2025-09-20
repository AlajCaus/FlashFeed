# Task 11.8 - Timer-Leak Fix für RetailersProvider

## PROBLEM ANALYSE
```
Timer (duration: 0:00:10.000000, periodic: false), created:
RetailersProvider.searchStores (package:flashfeed/providers/retailers_provider.dart:1138:10)

EXCEPTION: A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart': Failed assertion: line 1617 pos 12: '!timersPending'
```

## ROOT CAUSE
1. **RetailersProvider.searchStores()** erstellt 10s-Timeout-Timer (Zeile 1138)
2. **Timer wird nicht getrackt** und bei dispose() aufgeräumt
3. **Test verwendet FakeAsync** aber Timer bleibt pending

## BETROFFENE DATEIEN
- `lib/providers/retailers_provider.dart:1138` - Timeout-Timer ohne cleanup
- `test/retailer_search_integration_test.dart:158` - pump() statt pumpAndSettle()
- `lib/widgets/store_search_bar.dart:69` - ✅ bereits korrekt

## LÖSUNG (MINIMAL-ÄNDERUNGEN)

### 1. RetailersProvider - Timer Tracking
```dart
class RetailersProvider extends ChangeNotifier {
  Timer? _searchTimeoutTimer; // NEU: Timer-Tracking

  Future<List<Store>> searchStores(...) async {
    // Cancel vorherigen Timer
    _searchTimeoutTimer?.cancel(); // NEU

    return _performSearchInternal(...)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _searchTimeoutTimer = null; // NEU
            // ... rest bleibt gleich
          },
        );
  }

  @override
  void dispose() {
    _searchTimeoutTimer?.cancel(); // NEU
    super.dispose();
  }
}
```

### 2. Test - Proper Async Handling
```dart
// VORHER: Zeile 158
await tester.pump(Duration(milliseconds: 300));

// NACHHER:
await tester.pumpAndSettle(Duration(milliseconds: 300));
```

## AUSWIRKUNGSANALYSE
- ✅ **Keine Breaking Changes** - nur interne Timer-Verwaltung
- ✅ **StoreSearchBar bleibt unverändert** - Timer-Cleanup bereits korrekt
- ✅ **Tests werden stabiler** - keine Timer-Leaks mehr
- ✅ **Provider-Dispose** robuster - alle Timer aufgeräumt

## IMPLEMENTIERUNGSPLAN
1. Timer-Tracking in RetailersProvider hinzufügen
2. Test-Fix: pump() → pumpAndSettle()
3. Test ausführen und validieren
4. Commit mit "fix: resolve timer leak in RetailersProvider search"

## RISIKOBEWERTUNG: NIEDRIG
- Nur interne Timer-Verwaltung
- Keine öffentlichen APIs geändert
- Tests validieren Funktionalität bleibt gleich