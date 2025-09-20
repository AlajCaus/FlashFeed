# Flutter Testing Best Practices - FlashFeed

## ⚠️ HÄUFIGE TEST-FALLEN UND IHRE LÖSUNGEN

### 1. ❌ **DAS "GESCHLOSSEN" PROBLEM (3x aufgetreten!)**

**Problem:**
```dart
// FALSCH - zu strikt!
expect(find.text('Geschlossen'), findsOneWidget);
```

**Warum es fehlschlägt:**
- Ein Widget kann denselben Text mehrfach anzeigen
- Beispiel: "Geschlossen" erscheint als Status UND als Öffnungszeit
- Race Conditions bei dynamischen Widgets

**Lösung:**
```dart
// RICHTIG - flexibel!
expect(find.text('Geschlossen'), findsAtLeastNWidgets(1));
// Oder wenn mehrere erwartet werden:
expect(find.text('Geschlossen'), findsWidgets);
```

### 2. ❌ **DUPLICATE TEXT IN LISTEN/CARDS**

**Problem:**
```dart
// FALSCH - EDEKA könnte mehrfach vorkommen
expect(find.text('EDEKA'), findsOneWidget);
```

**Lösung:**
```dart
// RICHTIG - mindestens einmal
expect(find.text('EDEKA'), findsAtLeastNWidgets(1));
```

### 3. ❌ **WOCHENTAGE IN ÖFFNUNGSZEITEN**

**Problem:**
```dart
// FALSCH - Montag könnte in Header und Liste sein
expect(find.text('Montag'), findsOneWidget);
```

**Lösung:**
```dart
// RICHTIG - mit Erklärung
// 'Montag' could appear in multiple places (header, list)
expect(find.text('Montag'), findsAtLeastNWidgets(1));
```

## ✅ BEST PRACTICES

### 1. **Verwende `findsAtLeastNWidgets(1)` für Text-Suchen**
- Sicherer als `findsOneWidget`
- Verhindert Race Conditions
- Macht Tests robuster

### 2. **Dokumentiere warum du flexibel testest**
```dart
// 'Nicht verfügbar' might appear in multiple badges/labels
expect(find.text('Nicht verfügbar'), findsAtLeastNWidgets(1));
```

### 3. **Verwende spezifischere Finder wenn möglich**
```dart
// Statt nur Text zu suchen:
expect(find.text('Button'), findsOneWidget);

// Besser: Suche nach Widget-Typ mit Text
expect(
  find.widgetWithText(ElevatedButton, 'Button'),
  findsOneWidget,
);
```

### 4. **Verwende Keys für eindeutige Identifikation**
```dart
// Im Widget:
Text('Geschlossen', key: Key('status-closed'))

// Im Test:
expect(find.byKey(Key('status-closed')), findsOneWidget);
```

## 📊 ENTSCHEIDUNGSMATRIX

| Situation | Verwende |
|-----------|----------|
| Text könnte mehrfach vorkommen | `findsAtLeastNWidgets(1)` |
| Text ist garantiert einzigartig | `findsOneWidget` |
| Mehrere Vorkommen erwartet | `findsWidgets` |
| Exakte Anzahl wichtig | `findsNWidgets(n)` |
| Text könnte fehlen | `findsNothing` oder `findsAny` |

## 🔍 WIE MAN PROBLEME FINDET

### Suche nach potentiellen Problemen:
```bash
# Finde alle strikten Text-Tests
grep -r "expect(find.text.*findsOneWidget" test/

# Finde spezifische problematische Wörter
grep -r "find.text('Geschlossen')" test/
grep -r "find.text('Nicht verfügbar')" test/
grep -r "find.text('EDEKA')" test/
```

## 🛠️ REFACTORING CHECKLIST

Wenn du einen Test refactorst:

- [ ] Prüfe ob der gesuchte Text mehrfach vorkommen kann
- [ ] Verwende `findsAtLeastNWidgets(1)` statt `findsOneWidget` für Text
- [ ] Füge Kommentare hinzu die erklären warum
- [ ] Teste mit verschiedenen Widget-Zuständen
- [ ] Prüfe ob Keys eine bessere Alternative wären

## 📝 BEISPIEL REFACTORING

**Vorher (fragil):**
```dart
testWidgets('should show closed status', (tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Geschlossen'), findsOneWidget);
});
```

**Nachher (robust):**
```dart
testWidgets('should show closed status', (tester) async {
  await tester.pumpWidget(MyWidget());

  // 'Geschlossen' might appear as status and in opening hours
  expect(find.text('Geschlossen'), findsAtLeastNWidgets(1));

  // Or be more specific:
  expect(
    find.descendant(
      of: find.byType(StatusWidget),
      matching: find.text('Geschlossen'),
    ),
    findsOneWidget,
  );
});
```

## ⚡ QUICK FIXES

### Problem: "Expected: exactly one matching candidate, Actual: Found 2 widgets"
**Fix:** Ändere `findsOneWidget` zu `findsAtLeastNWidgets(1)`

### Problem: "Expected: exactly one matching candidate, Actual: Found 0 widgets"
**Fix:** Widget wurde noch nicht gerendert → Füge `await tester.pump()` hinzu

### Problem: Test ist flaky (funktioniert manchmal)
**Fix:** Verwende `findsAtLeastNWidgets(1)` statt `findsOneWidget`

## 🎯 FAZIT

**Die wichtigste Regel:**
> Wenn ein Text in einem Widget mehrfach vorkommen KÖNNTE, verwende NIEMALS `findsOneWidget`!

**Merke:**
- 3x hatten wir das "Geschlossen" Problem
- Es ist besser zu liberal als zu strikt zu testen
- Dokumentiere immer WARUM du flexibel testest

---

*Letzte Aktualisierung: Nach dem dritten "Geschlossen" Fehler 😅*