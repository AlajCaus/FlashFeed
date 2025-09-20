# Task 11.7 - Deadlock Analyse und Lösung

## Problem-Beschreibung
Deadlock in `retailer_search_integration_test.dart` beim Test "RetailerSelector should reflect availability from provider"

## Root-Cause Analyse

### Problem 1: Deadlock bei pumpAndSettle()
**Ort:** `retailer_search_integration_test.dart:216`

**Ursache:**
1. `RetailersProvider` Constructor ruft `loadRetailers()` auf (Zeile 161)
2. `loadRetailers()` ist async und ruft `notifyListeners()` auf (Zeile 298)
3. Der Test erstellt den Provider und übergibt ihn an `ChangeNotifierProvider.value`
4. `pumpAndSettle()` wartet darauf, dass keine Widget-Updates mehr stattfinden
5. Da `loadRetailers()` asynchron läuft und nach Completion `notifyListeners()` aufruft, entstehen kontinuierliche Updates
6. Dies führt zu einem endlosen Warten bei `pumpAndSettle()`

**Technische Details:**
- Der Provider wird im `setUp()` initialisiert (Zeile 37-40)
- `loadRetailers()` wird bereits dort aufgerufen (Zeile 43)
- Im Test wird der Provider nochmal in den Widget-Tree eingefügt
- Dies kann zu doppelten oder überlappenden async Operations führen

### Problem 2: Null-Fehler bei openingHours
**Ort:** `retailer_validation_test.dart:390`

**Ursache:**
- Store-Objekte können leere `openingHours` Maps haben
- Test prüft direkt auf Keys ohne vorherige Validierung

## Lösungsansatz

### Lösung für Problem 1: Provider-Initialisierung optimieren

**Option A: loadRetailers() aus Constructor entfernen**
- Constructor sollte keine async Operations starten
- loadRetailers() sollte explizit aufgerufen werden

**Option B: Flag für Test-Mode einführen**
- Parameter `autoLoad: false` für Tests
- Verhindert automatisches Laden im Constructor

**Option C: Synchrone Initialisierung für bereits geladene Daten**
- Wenn Daten bereits geladen sind, keine erneute async Operation

### Lösung für Problem 2: Robuste Validierung
- Prüfung ob openingHours Map existiert und nicht leer ist
- Nur dann auf einzelne Keys prüfen

## Implementierung

### Fix 1: RetailersProvider - Keine automatische async Operation im Constructor
```dart
RetailersProvider({
  required RetailersRepository repository,
  required MockDataService mockDataService,
  bool autoLoad = true, // Neuer Parameter
}) : _repository = repository {
  // Initial load nur wenn autoLoad = true
  if (autoLoad) {
    loadRetailers();
  }
}
```

### Fix 2: Test-Setup anpassen
- Provider mit `autoLoad: false` erstellen
- `await loadRetailers()` explizit im setUp aufrufen
- Sicherstellen dass async Operations abgeschlossen sind

### Fix 3: openingHours Validierung
```dart
if (openingHours.isNotEmpty) {
  // Prüfe ob alle Tage vorhanden sind
  final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  for (final day in days) {
    if (openingHours.containsKey(day)) {
      expect(openingHours[day], isNotNull);
    }
  }
}
```

## Betroffene Dateien
1. `lib/providers/retailers_provider.dart` - Constructor anpassen
2. `test/retailer_search_integration_test.dart` - Provider-Initialisierung
3. `test/retailer_validation_test.dart` - openingHours Validierung
4. Alle anderen Tests die RetailersProvider nutzen müssen geprüft werden

## Risiken
- Breaking Change für bestehende Provider-Nutzung
- Andere Tests könnten betroffen sein
- Performance-Impact durch verzögertes Laden

## Test-Strategie
1. Fix implementieren
2. Betroffenen Test isoliert ausführen
3. Alle retailer-bezogenen Tests ausführen
4. Vollständige Test-Suite laufen lassen