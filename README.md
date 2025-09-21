# FlashFeed - Digitaler Marktplatz für Angebote & Flash Deals 🛒⚡

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.35.3-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.0-blue?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Mobile%20%7C%20Desktop-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Status](https://img.shields.io/badge/Status-MVP%20Complete-success)

**[🌐 Live Demo](https://flashfeed.app)** | **[📱 QR-Code](#quick-access)** | **[📖 Documentation](#documentation)** | **[🎬 Demo Guide](DEMO_GUIDE.md)**

</div>

---

## 🎯 Über FlashFeed

FlashFeed revolutioniert das digitale Einkaufserlebnis durch Echtzeit-Angebote und Flash Deals von führenden deutschen Einzelhändlern. Unsere Progressive Web App (PWA) bietet standortbasierte Angebote, interaktive Karten und zeitkritische Flash Deals - alles in einer modernen, responsiven Oberfläche.

### 🌟 Kernfunktionen

- **📍 Standortbasierte Angebote** - Automatische PLZ-Erkennung und regionale Filterung
- **⚡ Flash Deals** - Zeitkritische Angebote mit Live-Countdown
- **🗺️ Interaktive Karte** - Filialen in der Nähe mit Navigation
- **🔍 Intelligente Suche** - Echtzeit-Filterung nach Kategorien und Händlern
- **👑 Freemium-Modell** - Free: 1 Händler | Premium: Alle Händler
- **📱 Cross-Platform** - PWA für Web, Mobile und Desktop

---

## 🚀 Quick Start

### Installation & Setup

```bash
# Repository klonen
git clone https://github.com/yourusername/flashfeed.git
cd flashfeed

# Dependencies installieren
flutter pub get

# Development Server starten
flutter run -d chrome

# Production Build
flutter build web --release
```

### 📱 Demo-Zugriff

#### Option 1: QR-Code
1. Öffne die App unter `https://flashfeed.app`
2. Gehe zu Settings (☰ → ⚙️)
3. Aktiviere "QR-Code anzeigen"
4. Scanne mit dem Smartphone

#### Option 2: Demo-URL
```
https://flashfeed.app?demo=true&premium=true
```

---

## 🏗️ Technische Architektur

### Tech Stack
- **Framework:** Flutter 3.35.3 (Web, Mobile, Desktop)
- **State Management:** Provider Pattern
- **Maps:** OpenStreetMap mit flutter_map
- **Styling:** Material Design 3
- **Data:** MockDataService (MVP) → Backend-ready

### Projekt-Struktur
```
flashfeed/
├── lib/
│   ├── providers/          # State Management
│   ├── screens/            # UI Screens
│   ├── widgets/            # Reusable Components
│   ├── services/           # Business Logic
│   ├── repositories/       # Data Layer
│   └── models/            # Data Models
├── web/                   # Web-spezifische Assets
├── test/                  # Unit & Widget Tests
└── docs/                  # Dokumentation
```

---

## ✨ Features im Detail

### 🛍️ Angebote-Panel
- Echtzeit-Filterung nach Händler und Kategorie
- Preisvergleich zwischen Händlern (Premium)
- Skeleton Loading für bessere UX
- Responsive Grid-Layouts

### ⚡ Flash Deals
- Live-Countdown mit Sekundentakt
- Urgency-Level (Kritisch/Mittel/Niedrig)
- Push-Benachrichtigungen bei neuen Deals
- Swipe-to-dismiss mit Undo

### 🗺️ Karten-Integration
- OpenStreetMap-Integration
- Händler-spezifische Marker
- GPS-basierte Standortbestimmung
- Externe Navigation (Google Maps/Apple Maps)

### 👤 Benutzer-Features
- Freemium-Modell (1 vs. alle Händler)
- Dark/Light Theme
- Favoriten-Verwaltung
- Demo-Modus für Präsentationen

### 📊 Analytics & Monitoring
- Privacy-friendly Analytics (DSGVO-konform)
- Web Vitals Tracking
- Session-Management
- Performance-Metriken

---

## 🎬 Demo-Features

### Professor-Demo Highlights
1. **QR-Code Demo-Zugriff** - Instant Access für Präsentationen
2. **Auto-Premium im Demo-Modus** - Alle Features freigeschaltet
3. **Realistische Mock-Daten** - 200+ Angebote, 50+ Flash Deals
4. **Multi-Device Support** - Responsive auf allen Geräten

### Demo-Szenario
```javascript
// Demo-URL mit allen Features
https://flashfeed.app?demo=true&premium=true&tour=true

// Features:
- Auto-Login als Premium User
- Guided Tour Option
- Reset-Button für Demo-Daten
- Performance-Metriken anzeigen
```

---

## 🚢 Deployment

### GitHub Pages (Automatisch)
```yaml
# .github/workflows/deploy.yml
- Automatische Tests bei jedem Push
- Code-Qualitätsprüfung
- Build & Deploy zu GitHub Pages
- PR Preview Deployments
```

### Manuelle Deployment
```bash
# Build erstellen
flutter build web --release --base-href "/FlashFeed/"

# Deploy zu GitHub Pages
git add build/web
git commit -m "Deploy to GitHub Pages"
git push origin main
```

---

## 🧪 Testing

### Test-Ausführung
```bash
# Alle Tests ausführen
flutter test

# Mit Coverage
flutter test --coverage

# Spezifische Test-Suites
flutter test test/providers/
flutter test test/widgets/
```

### Test-Coverage
- **Unit Tests:** 308 Tests ✅
- **Widget Tests:** 68 Tests ✅
- **Integration Tests:** 16 Tests ✅
- **Performance Tests:** 54 Tests ✅
- **Gesamt:** 446 Tests (100% Pass Rate)

---

## 📊 Performance

### Lighthouse Scores
- **Performance:** 95+
- **Accessibility:** 100
- **Best Practices:** 100
- **SEO:** 100
- **PWA:** Optimiert

### Bundle Size
- **Initial Load:** < 2MB
- **Lazy Loading:** Implementiert
- **Tree Shaking:** Aktiviert
- **Compression:** gzip

---

## 🤝 Freemium-Modell

### Free User
- ✅ 1 Händler auswählbar
- ✅ ALLE Angebote dieses Händlers
- ✅ ALLE Flash Deals dieses Händlers
- ✅ Unbegrenzte Suche
- ❌ Preisvergleich
- ❌ Multi-Händler Filter

### Premium User
- ✅ ALLE Händler gleichzeitig
- ✅ Preisvergleich zwischen Händlern
- ✅ Multi-Händler Filter
- ✅ Erweiterte Kartenfeatures
- ✅ Prioritäts-Benachrichtigungen
- ✅ Werbefreie Erfahrung

---

## 🛠️ Development

### Prerequisites
- Flutter SDK 3.35.3+
- Dart SDK 3.9.0+
- Chrome/Edge Browser
- Git

### Environment Setup
```bash
# Flutter Version prüfen
flutter --version

# Flutter Doctor
flutter doctor

# Web Support aktivieren
flutter config --enable-web
```

### Development Workflow
```bash
# Feature Branch erstellen
git checkout -b feature/neue-funktion

# Änderungen committen
git add .
git commit -m "feat: neue Funktion"

# Push & PR erstellen
git push origin feature/neue-funktion
```

---

## 📖 Documentation

- **[FEATURES.md](FEATURES.md)** - Detaillierte Feature-Beschreibungen
- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - Schritt-für-Schritt Demo-Anleitung
- **[KNOWN_ISSUES.md](KNOWN_ISSUES.md)** - Bekannte Probleme & Workarounds
- **[ROADMAP.md](ROADMAP.md)** - Zukunftsplanung & Roadmap
- **[API.md](docs/API.md)** - API-Dokumentation

---

## 🚀 Roadmap

### Phase 1: MVP ✅ (Abgeschlossen)
- [x] Provider-Architektur
- [x] Mock-Daten-Service
- [x] UI-Implementation
- [x] Freemium-Modell
- [x] Maps-Integration
- [x] Flash Deals
- [x] PWA-Features

### Phase 2: Production (Q1 2025)
- [ ] Backend-Integration
- [ ] Echte Händler-APIs
- [ ] Payment-Integration
- [ ] Push-Notifications
- [ ] A/B Testing

### Phase 3: Expansion (Q2 2025)
- [ ] iOS/Android Native Apps
- [ ] Partnerschaften mit Händlern
- [ ] AI-basierte Empfehlungen
- [ ] Social Features

---

## 👥 Team & Kontakt

**Entwickelt für:** Hochschule Demo-Projekt
**Technologie:** Flutter Web PWA
**Status:** MVP Complete
**Demo:** [https://flashfeed.app](https://flashfeed.app)

---

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) für Details.

---

<div align="center">

**[⬆ Nach oben](#flashfeed---digitaler-marktplatz-für-angebote--flash-deals-)**

Made with ❤️ using Flutter

</div>