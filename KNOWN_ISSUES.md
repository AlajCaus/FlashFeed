# Known Issues & Workarounds 🔧

## Übersicht

Dieses Dokument listet alle bekannten Probleme, Einschränkungen und deren Workarounds für FlashFeed MVP auf.

**Letzte Aktualisierung:** Dezember 2024
**Version:** 1.0.0 (MVP)

---

## 🚨 Kritische Issues

### 1. Flash Deals Timer-Synchronisation
**Problem:** Timer können bei Tab-Wechsel desynchronisieren
**Betrifft:** Alle Browser
**Status:** 🟡 Bekannt

**Workaround:**
```dart
// Manueller Refresh
Pull-to-Refresh auf Flash Deals Screen
// oder
Settings → Demo-Modus → Reset
```

**Geplante Lösung:** Web Workers für Background Timer (Q1 2025)

---

### 2. iOS Safari GPS-Berechtigung
**Problem:** GPS-Abfrage erscheint nicht immer
**Betrifft:** iOS 14+ Safari
**Status:** 🟡 Bekannt

**Workaround:**
1. Safari Einstellungen → Standort → Erlauben
2. Alternativ: PLZ manuell eingeben
```
Hamburger-Menü → PLZ ändern → 10115
```

**Geplante Lösung:** Verbessertes Permission Handling

---

## ⚠️ Performance Issues

### 3. Initiales Laden bei vielen Angeboten
**Problem:** Erste Ladezeit > 3 Sekunden bei schwachen Geräten
**Betrifft:** Mobile Geräte < 4GB RAM
**Status:** 🟡 Optimierung geplant

**Workaround:**
- Skeleton Loading zeigt Fortschritt
- Nach erstem Load: Cache aktiv
- Reduzierte Animation auf schwachen Geräten

**Metriken:**
```
High-End Device:  1-2 Sekunden
Mid-Range:         2-3 Sekunden
Low-End:           3-5 Sekunden
```

---

### 4. Map Performance bei vielen Markern
**Problem:** Ruckeln bei 600+ Markern auf Mobile
**Betrifft:** Mobile Browser
**Status:** 🟡 Bekannt

**Workaround:**
```javascript
// Marker-Clustering aktiviert bei > 100 Markern
// Zoom-Level abhängige Anzeige
Zoom 10-12: Cluster
Zoom 13+: Einzelne Marker
```

**Geplante Lösung:** WebGL-Renderer für Maps

---

## 🎨 UI/UX Issues

### 5. Dark Mode Kontrast-Probleme
**Problem:** Einige Texte schwer lesbar in Dark Mode
**Betrifft:** OLED-Displays
**Status:** 🟢 Fix in Progress

**Workaround:**
```
Settings → Theme → Light Mode verwenden
```

**Betroffene Komponenten:**
- Disabled Buttons
- Sekundäre Texte
- Input-Placeholder

---

### 6. Responsive Layout Breakpoint
**Problem:** Layout-Sprung bei genau 768px Breite
**Betrifft:** Tablet-Rotation
**Status:** 🟡 Low Priority

**Workaround:**
- Fenster leicht größer/kleiner ziehen
- Oder: Vollbild-Modus verwenden

---

## 📱 Browser-spezifische Issues

### 7. Firefox: Notification API
**Problem:** Web Notifications funktionieren nicht immer
**Browser:** Firefox 88+
**Status:** 🟡 Browser-Bug

**Workaround:**
1. `about:config` öffnen
2. `dom.webnotifications.enabled` → true
3. Browser neustarten

---

### 8. Safari: PWA Installation
**Problem:** "Add to Home" nicht immer sichtbar
**Browser:** Safari iOS/macOS
**Status:** 🟡 Platform-Limitation

**Workaround:**
```
iOS: Share-Button → Add to Home Screen
macOS: File → Add to Dock
```

---

### 9. Edge: Cache-Probleme
**Problem:** Alte Version wird gecacht
**Browser:** Edge 90+
**Status:** 🟢 Fix deployed

**Workaround:**
```
Ctrl + Shift + R (Hard Refresh)
oder
Settings → Privacy → Clear Cache
```

---

## 🔧 Funktionale Einschränkungen

### 10. Mock-Daten Limitations
**Problem:** Daten sind statisch, nicht von echten APIs
**Status:** 🔵 By Design (MVP)

**Einschränkungen:**
- Angebote aktualisieren sich nicht real
- Flash Deals sind randomisiert
- Stores haben feste Öffnungszeiten

**Nach Backend-Integration gelöst (Q1 2025)**

---

### 11. Offline-Funktionalität eingeschränkt
**Problem:** Nur Cache, keine echte Offline-Sync
**Status:** 🟡 Enhancement planned

**Aktueller Stand:**
- Letzte 50 Angebote gecacht
- Keine Flash Deals offline
- Karte nicht verfügbar offline

---

### 12. Barcode-Scanner nicht implementiert
**Problem:** Produkt-Scan Feature fehlt
**Status:** 🔵 Future Feature

**Alternative:**
- Manuelle Suche verwenden
- Produkt-Name eingeben

---

## 🐛 Bekannte Bugs

### 13. Swipe-to-Dismiss Undo
**Problem:** Undo funktioniert nur 5 Sekunden
**Component:** Flash Deals
**Status:** 🟢 Working as intended

**Verhalten:**
```dart
// Nach 5 Sekunden:
- Deal endgültig ausgeblendet
- Bis zum nächsten Refresh
```

---

### 14. Filter-Reset bei Navigation
**Problem:** Filter werden bei Tab-Wechsel zurückgesetzt
**Component:** Offers Screen
**Status:** 🟡 Enhancement

**Workaround:**
- Filter neu setzen nach Rückkehr
- Oder: In einem Tab bleiben

---

### 15. Doppelte Notifications
**Problem:** Manchmal zwei Notifications für einen Flash Deal
**Component:** Flash Deals Provider
**Status:** 🟢 Fix in Test

**Workaround:**
- Notifications temporär deaktivieren
- Browser-Notifications blockieren

---

## 💻 Development Issues

### 16. Hot Reload Probleme mit Providers
**Problem:** State geht verloren bei Hot Reload
**Environment:** Development
**Status:** 🟡 Flutter Limitation

**Workaround:**
```bash
# Full Restart statt Hot Reload
flutter run -d chrome
# dann 'R' (Shift+R) für full restart
```

---

### 17. Test Warnings
**Problem:** 87 Warnings bei `flutter analyze`
**Type:** Code Quality
**Status:** 🟢 Non-Critical

**Hauptprobleme:**
- `deprecated withOpacity()` (54x)
- `unused fields` (15x)
- `unnecessary null checks` (18x)

**Lösung geplant für v1.1**

---

### 18. Build-Size für Web
**Problem:** Initial Bundle ~2.5MB
**Environment:** Production
**Status:** 🟡 Optimization planned

**Aktuelle Optimierungen:**
- Tree Shaking aktiv
- Deferred Loading implementiert
- gzip Compression

**Ziel: < 2MB (Q1 2025)**

---

## 📋 Feature Requests (Nicht implementiert)

### Häufig gewünschte Features:
1. **Preisalarm** - Notification bei Zielpreis
2. **Einkaufsliste** - Mit Angebots-Matching
3. **Favoritenverwaltung** - Produkte speichern
4. **Historie** - Vergangene Deals ansehen
5. **Social Sharing** - Deals teilen
6. **Coupons** - Digitale Rabattcodes
7. **Bewertungen** - Produkt-Reviews

**Status:** Für Post-MVP Roadmap vorgesehen

---

## 🔄 Version-spezifische Issues

### v1.0.0 (Current MVP)
- Alle oben genannten Issues
- Fokus auf Core-Functionality

### v0.9.0 (Beta)
- ✅ Fixed: Memory Leaks in Providers
- ✅ Fixed: Navigation State Loss
- ✅ Fixed: Timer Disposal Issues

---

## 📞 Support & Reporting

### Neue Issues melden:
```markdown
GitHub: https://github.com/yourusername/flashfeed/issues
Template verwenden: BUG_REPORT.md
```

### Prioritäten:
- 🔴 **Critical:** App-Breaking, Datenverlust
- 🟡 **Major:** Feature eingeschränkt
- 🟢 **Minor:** Cosmetic, UX
- 🔵 **Enhancement:** Nice-to-have

---

## ✅ Behobene Issues (Latest Release)

### Recently Fixed:
1. ✅ **Timer Memory Leaks** - v0.9.5
2. ✅ **Provider Disposal Crashes** - v0.9.6
3. ✅ **Infinite Scroll Bug** - v0.9.7
4. ✅ **GPS Permission Loop** - v0.9.8
5. ✅ **Dark Mode Toggle** - v0.9.9
6. ✅ **Compiler Errors in Settings** - v1.0.0

---

## 🎯 Testing Recommendations

### Vor Demo/Präsentation:
1. Browser-Cache leeren
2. Stabiles WLAN sicherstellen
3. Backup-Device bereithalten
4. Known Issues durchlesen
5. Workarounds notieren

### Test-Szenarien:
```bash
# Kritische Pfade testen:
1. Freemium → Premium Upgrade
2. Filter → Search → Results
3. Flash Deal → Countdown → Expire
4. Map → Marker → Navigation
5. Settings → Theme → QR Code
```

---

<div align="center">

## 📌 Quick Reference

**Most Common Issues:**
1. GPS nicht verfügbar → PLZ eingeben
2. Alte Version → Hard Refresh (Ctrl+F5)
3. Performance → Reduce Animations
4. Timer-Probleme → Pull-to-Refresh

**Status:** Continuous Improvement

</div>