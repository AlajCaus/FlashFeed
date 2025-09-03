# FlashFeed GitHub Pages Setup - Schritt-für-Schritt

## 🚀 AUTOMATISCHES DEPLOYMENT (Empfohlen)

### 1. GitHub Pages aktivieren:
```
1. Gehe zu deinem GitHub Repository
2. Klicke auf "Settings" Tab
3. Scrolle runter zu "Pages" in der Sidebar
4. Bei "Source" wähle: "GitHub Actions"
5. Save/Speichern
```

### 2. Erste Deployment starten:
```bash
# Einfach Code pushen - GitHub Actions macht automatisch den Rest!
git add .
git commit -m "Add GitHub Pages deployment"
git push origin main

# GitHub Actions läuft automatisch und erstellt:
# - Flutter Web Build
# - Deployment auf GitHub Pages  
# - Live-Demo URL verfügbar nach ~2-3 Minuten
```

### 3. Live-Demo URL finden:
```
Nach erstem erfolgreichen Build:
- Repository > Settings > Pages
- Deine URL: https://YOUR-USERNAME.github.io/FlashFeed/
- Status: "Your site is published at ..." wird angezeigt
```

---

## 🔧 MANUELLES DEPLOYMENT (Fallback)

Falls GitHub Actions nicht funktioniert:

### Option 1: docs/ Folder Method
```bash
# 1. Web Build erstellen
flutter build web --base-href "/FlashFeed/"

# 2. docs/ Ordner erstellen
mkdir docs
cp -r build/web/* docs/

# 3. GitHub Pages konfigurieren
# Settings > Pages > Source: "Deploy from a branch"  
# Branch: main, Folder: /docs

# 4. Commit und Push
git add docs/
git commit -m "Add manual deployment"
git push
```

### Option 2: gh-pages Branch Method  
```bash
# 1. Web Build
flutter build web --base-href "/FlashFeed/"

# 2. gh-pages Branch erstellen
git checkout --orphan gh-pages
git rm -rf .
cp -r build/web/* .
git add .
git commit -m "Deploy web build"
git push origin gh-pages

# 3. GitHub Pages auf gh-pages branch umstellen
```

---

## 📱 QR-CODE GENERIERUNG

Nach erfolgreichem Deployment:

### Online QR-Generator verwenden:
```
1. Live-Demo URL kopieren: https://YOUR-USERNAME.github.io/FlashFeed/
2. Gehe zu: https://qr-code-generator.com
3. URL eingeben und QR-Code generieren  
4. PNG herunterladen und zu Repository hinzufügen
5. In README.md verlinken
```

### QR-Code in README einbinden:
```markdown
## 📱 Quick Access
![FlashFeed QR Code](docs/qr-code.png)
**Live Demo:** https://YOUR-USERNAME.github.io/FlashFeed/
```

---

## 🧪 TESTING NACH DEPLOYMENT

### 1. Desktop Testing:
- Chrome: Normale Desktop-Ansicht
- Firefox: Cross-Browser Kompatibilität
- Safari: Mac-Compatibility (falls verfügbar)
- Edge: Windows-Integration

### 2. Mobile Testing:
```bash
# QR-Code mit Handy scannen ODER
# Live-Demo URL direkt im Mobile Browser öffnen:
https://YOUR-USERNAME.github.io/FlashFeed/
```

### 3. Multi-Device Testing:
- **Tablet (iPad/Android):** Touch-Navigation testen
- **Verschiedene Screen-Sizes:** Responsive Design prüfen  
- **Cross-Platform:** iOS Safari vs Android Chrome

---

## ❗ TROUBLESHOOTING

### Build-Fehler:
```bash
# Dependencies updaten
flutter clean
flutter pub get
flutter build web

# Falls web nicht enabled:
flutter config --enable-web
```

### GitHub Actions Fehler:
```bash  
# Actions Tab in GitHub prüfen
# Logs anschauen für spezifische Fehlermeldungen
# base-href korrekt setzen: --base-href "/REPOSITORY-NAME/"
```

### GitHub Pages nicht erreichbar:
```bash
# 10-15 Minuten warten nach erstem Deployment
# Settings > Pages prüfen ob "published" status
# Cache leeren: Ctrl+F5 / Cmd+Shift+R
```

---

## 🎯 ERFOLG-CHECKLISTE

- [ ] GitHub Pages aktiviert ✅
- [ ] GitHub Actions läuft erfolgreich ✅  
- [ ] Live-Demo URL erreichbar ✅
- [ ] Mobile Browser funktioniert ✅
- [ ] QR-Code generiert und getestet ✅
- [ ] Multi-Device Testing erfolgreich ✅

**Nach Erfolg → Task 4b als ✅ markieren und Task 5 beginnen!**