# Task: Compiler-Fehler Fix - getNextOpeningTime Methode

## Problem
- **Fehler:** `The method 'getNextOpeningTime' isn't defined for the type 'Store'`
- **Datei:** test/retailers_provider_extended_test.dart:266:39
- **Ursache:** Store-Klasse hat keine `getNextOpeningTime()` Methode

## Auswirkungsanalyse

### Betroffene Dateien
1. **lib/models/models.dart** (Zeile 213-302)
   - Store-Klasse benötigt neue `getNextOpeningTime()` Methode
   - Bestehende OpeningHours-Logik kann wiederverwendet werden

2. **test/retailers_provider_extended_test.dart** (Zeile 266)
   - Test ruft bereits die erwartete Methode auf
   - Nach Implementierung sollte Test funktionieren

3. **lib/providers/retailers_provider.dart**
   - Separate Warnings (unnecessary_null_comparison)
   - Keine Verbindung zur getNextOpeningTime-Methode

### Provider/Services Auswirkungen
- ✅ Keine Provider-Anpassungen erforderlich
- ✅ Store wird nur als Model verwendet
- ✅ Keine Breaking Changes für bestehenden Code

### Tests
- ✅ retailers_provider_extended_test.dart Test erwartet bereits die Methode
- ✅ Nach Implementierung sollte Test ohne weitere Änderungen funktionieren

### Breaking Changes
- ✅ **KEINE** Breaking Changes
- ✅ Neue Methode erweitert nur die Store-Klasse
- ✅ Bestehender Code nicht betroffen

### Abhängigkeiten
- ✅ Nutzt bestehende OpeningHours-Klasse
- ✅ Keine neuen Dependencies erforderlich

## Lösungsansatz

1. **getNextOpeningTime() Methode implementieren:**
   ```dart
   DateTime? getNextOpeningTime() {
     final now = DateTime.now();

     // Überprüfe heute und die nächsten 7 Tage
     for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
       final checkDate = now.add(Duration(days: dayOffset));
       final weekdayStr = _getWeekdayString(checkDate.weekday);
       final hours = openingHours[weekdayStr];

       if (hours == null || hours.isClosed) continue;

       final openTime = DateTime(
         checkDate.year,
         checkDate.month,
         checkDate.day,
         hours.openMinutes ~/ 60,
         hours.openMinutes % 60,
       );

       // Wenn heute und öffnet später, oder zukünftiger Tag
       if (openTime.isAfter(now)) {
         return openTime;
       }
     }

     return null; // Immer geschlossen oder keine Öffnungszeiten
   }
   ```

2. **Weitere Warnings beheben:**
   - unnecessary_null_comparison in retailers_provider.dart
   - unused_field Warnings

## Status
- [x] Problem identifiziert
- [x] Auswirkungsanalyse abgeschlossen
- [x] Implementierung der getNextOpeningTime Methode
- [x] Behebung weiterer Warnings
- [x] Verifikation mit dart analyze

## Risiken
- ✅ **NIEDRIG** - Nur neue Funktionalität, keine Breaking Changes
- ✅ Bestehende Tests und Code nicht betroffen
- ✅ Einfache Implementierung basierend auf vorhandener OpeningHours-Logik