# FlashFeed MVP Entwicklungsplan - Provider Pattern (3 Wochen)

## **STATUS-ANALYSE & AKTUELLER FORTSCHRITT**
- ✅ **Git Setup:** Repository erfolgreich eingerichtet
- ✅ **Flutter Template:** Standard-App läuft  
- ✅ **Produktkategorien-Mapping:** Bereits implementiert (`lib/data/product_category_mapping.dart`)
- ✅ **Provider Package:** `provider: ^6.1.1` in pubspec.yaml implementiert
- ✅ **App-Architektur:** Provider-Pattern vollständig setup
- ✅ **Repository Pattern:** 4 Repository-Dateien implementiert
- ✅ **Core Provider:** 4 Provider erstellt (App, Offers, User, Location)
- ✅ **Deployment Setup:** GitHub Pages + Actions konfiguriert

---

## 📍 **LAST CLAUDE POSITION (PERSISTENT HANDOFF)**

### **✅ ABGESCHLOSSEN:** 
**Task 4b: Quick Deployment Setup** - 100% fertig!

**Erstellte/Aktualisierte Dateien:**
- `.github/workflows/static.yml` - Alle Actions auf neueste Versionen aktualisiert
- `DEPLOYMENT_SETUP.md` - Schritt-für-Schritt Setup-Anleitung  
- `README.md` - Aktualisiert mit Live-Demo Links und Testing-Strategien
- **ALLE ACTIONS KONSISTENT:** checkout@v5, flutter-action@v2, gh-pages@v4, upload-artifact@v4

### **⏭️ DANACH SOFORT:**
**Task 5: Mock-Daten-Service** - Vollständig vorbereitet!

**Was zu tun ist:**
1. `lib/services/mock_data_service.dart` erstellen
2. Mock-Angebote für alle Händler generieren (EDEKA, REWE, ALDI, etc.)
3. Mock-Filialen mit GPS-Koordinaten (Berlin/München Focus)
4. Integration mit `product_category_mapping.dart`
5. Provider mit Mock-Service verbinden

### **📋 FÜR ENTWICKLER:**
Vor Task 5:
1. Code committen und pushen
2. GitHub Pages setup gemäß `DEPLOYMENT_SETUP.md`
3. Live-Demo URL testen
4. Dann Task 5 starten

---

## **PHASE 1: GRUNDLAGEN & PROVIDER SETUP** 
*Ziel: Provider-Architektur + Navigation (Woche 1)*

### **🔧 SETUP & DEPENDENCIES**

#### **Task 1: Provider Package Integration**
- [x] Provider Package zu `pubspec.yaml` hinzufügen (`provider: ^6.1.1`)
- [x] `flutter pub get` ausführen (manuell von Entwickler durchzuführen)
- [x] Import-Tests in main.dart

#### **Task 2: Ordnerstruktur erweitern**
- [x] `lib/providers/` erstellen
- [x] `lib/repositories/` erstellen  
- [x] `lib/widgets/` erstellen
- [x] `lib/screens/` erstellen
- [x] `lib/services/` erstellen

---

### **🏗️ PROVIDER-ARCHITEKTUR SETUP**

#### **Task 3: Repository Pattern implementieren**
- [x] `lib/repositories/offers_repository.dart` - Interface für Angebote
- [x] `lib/repositories/mock_offers_repository.dart` - Mock-Implementation
- [x] `lib/repositories/retailers_repository.dart` - Interface für Händler
- [x] `lib/repositories/mock_retailers_repository.dart` - Mock-Implementation

#### **Task 4: Core Provider erstellen**
- [x] `lib/providers/app_provider.dart` - Navigation & Global State
- [x] `lib/providers/offers_provider.dart` - Angebote & Preisvergleich (mit regionaler Filterung)
- [x] `lib/providers/user_provider.dart` - Freemium Logic & Settings
- [x] `lib/providers/location_provider.dart` - GPS & Standort (Basis-Implementierung)

#### **Task 4b: Quick Deployment Setup**
- [x] GitHub Pages aktivieren und konfigurieren (Anleitung erstellt)
- [x] GitHub Actions Workflow erstellt (automatisches Deployment)
- [x] Live-Demo-URL Setup (nach erstem Push verfügbar)
- [x] README mit Demo-Links und Testing-Anleitungen aktualisiert  
- [x] Multi-Device-Testing Setup dokumentiert
- [x] DEPLOYMENT_SETUP.md mit Schritt-für-Schritt Anleitung erstellt

#### **Task 5: Mock-Daten-Service**
- [ ] `lib/services/mock_data_service.dart` - Zentrale Mock-Daten
- [ ] Mock-Angebote für alle Händler generieren
- [ ] Mock-Filialen mit GPS-Koordinaten
- [ ] Integration mit `product_category_mapping.dart`

---

### **🗺️ REGIONALE VERFÜGBARKEIT**
*Neue Task-Gruppe für realistische Händler-Verfügbarkeit*

#### **Task 5a: PLZ-basierte Retailer-Verfügbarkeit**
- [ ] Retailer-Klasse um `availablePLZRanges: List<PLZRange>` erweitern
- [ ] PLZRange-Model-Klasse implementieren (`startPLZ`, `endPLZ`, `regionName`)
- [ ] Mock-Retailer mit realistischen PLZ-Bereichen aktualisieren
- [ ] BioCompany: Berlin/Brandenburg, Globus: Süd/West, Netto (schwarz): Nord/Ost

#### **Task 5b: PLZ-Lookup-Service**  
- [ ] `lib/services/plz_lookup_service.dart` erstellen
- [ ] GPS-Koordinaten zu PLZ-Mapping (Reverse-Geocoding oder Lookup-Table)
- [ ] User-PLZ-Eingabe Alternative (Fallback wenn GPS nicht verfügbar)
- [ ] PLZ-zu-Region Zuordnung (Bayern: 80000-99999, Berlin: 10000-14999, etc.)
- [ ] Caching für Performance

#### **Task 5c: Regionale Provider-Logik**
- [ ] LocationProvider um regionale PLZ-Logik erweitern
- [ ] OffersProvider um regionale Filterung erweitern (`getRegionalOffers()`)
- [ ] RetailersProvider um Verfügbarkeitsprüfung erweitern (`getAvailableRetailers(plz)`)
- [ ] "Nicht verfügbar in Ihrer Region"-Fallback-Logic
- [ ] Cross-Provider Integration (LocationProvider → OffersProvider/RetailersProvider)

---

### **🎨 UI FRAMEWORK & NAVIGATION**

#### **Task 6: Drei-Panel-Layout**
- [ ] `lib/screens/main_layout_screen.dart` - Responsive 3-Panel-Layout
- [ ] `lib/widgets/navigation_panel.dart` - Seitennavigation  
- [ ] `lib/widgets/offers_panel.dart` - Panel 1: Angebotsvergleich
- [ ] `lib/widgets/map_panel.dart` - Panel 2: Karten-Ansicht
- [ ] `lib/widgets/flash_deals_panel.dart` - Panel 3: Flash Deals

#### **Task 7: App Provider Integration**
- [ ] AppProvider in main.dart einbinden (MultiProvider Setup)
- [ ] Navigation State Management
- [ ] Panel-Wechsel-Logik implementieren

#### **Task 8: Theme & Responsive Design**
- [ ] FlashFeed Theme in `lib/theme/app_theme.dart`
- [ ] Responsive Breakpoints für Web
- [ ] Mobile/Desktop Layout-Unterschiede

---

## **PHASE 2: CORE FEATURES MIT PROVIDER**
*Ziel: Funktionale Panels (Woche 2)*

### **📊 PANEL 1: ANGEBOTSVERGLEICH**

#### **Task 9: OffersProvider Implementation**
- [ ] Angebote laden über Repository Pattern
- [ ] Produktkategorien-Filter (Integration mit `product_category_mapping.dart`)
- [ ] Händler-spezifische Filter mit regionaler Verfügbarkeit
- [ ] Sortierung (Preis, Entfernung, Rabatt)
- [ ] Suchfunktion implementieren
- [ ] Regionale Filterung: nur verfügbare Händler anzeigen

#### **Task 10: Offers Panel UI**
- [ ] Produktkarten mit Preisvergleich
- [ ] Filter-Widgets (Kategorie, Händler, Preis)
- [ ] Sortierungs-Dropdown
- [ ] Suchleiste
- [ ] Freemium-Features (limitierte Anzahl ohne Premium)
- [ ] "Nicht in Ihrer Region verfügbar" UI-Messages

#### **Task 11: Retailer Management**
- [ ] RetailerProvider für Händler-Daten
- [ ] Händler-Logos & Branding (mit displayName + iconUrl)
- [ ] Öffnungszeiten Integration
- [ ] Filial-Suche Funktionalität
- [ ] Regionale Verfügbarkeitsprüfung basierend auf User-PLZ

---

### **🗺️ PANEL 2: MAPS & STANDORT**

#### **Task 12: LocationProvider Setup**
- [ ] GPS-Berechtigung anfordern (Web Geolocation API)
- [ ] Aktuelle Position ermitteln
- [ ] Integration mit PLZ-Lookup-Service (GPS → PLZ → Region)
- [ ] Standort-basierte Filial-Suche (nur regionale Filialen)
- [ ] Entfernungsberechnung zu Filialen
- [ ] Fallback: User-PLZ-Eingabe wenn GPS fehlschlägt

#### **Task 13: Map Panel Implementation** 
- [ ] Web-Map Integration (Google Maps oder OpenStreetMap)
- [ ] Filial-Marker auf Karte (nur regionale Händler)
- [ ] Aktuelle Position anzeigen
- [ ] Klickbare Marker mit Filial-Info
- [ ] Route zur Filiale anzeigen
- [ ] Regionale Marker-Filterung basierend auf User-Standort

---

### **⚡ PANEL 3: FLASH DEALS**

#### **Task 14: FlashDealsProvider**
- [ ] Echtzeit-Rabatt-Simulation (Timer-basiert)
- [ ] Integration mit `FlashDealSimulator` aus `product_category_mapping.dart`
- [ ] Countdown-Timer für Deals
- [ ] Push-Notification-Logik (Mock)

#### **Task 15: Flash Deals Panel UI**
- [ ] Live-Deal-Karten mit Countdown
- [ ] "Professor Demo"-Button (Instant Deal Generation)
- [ ] Deal-Kategorien Filter
- [ ] Standort-basierte Deal-Anzeige (nur regionale Händler)
- [ ] "Deal verpasst"-Animation
- [ ] Regionale Verfügbarkeitsinformation bei Deals

---

## **PHASE 3: INTEGRATION & DEPLOYMENT** 
*Ziel: Funktionsfähiger Prototyp (Woche 3)*

### **🔗 PROVIDER-INTEGRATION**

#### **Task 16: Cross-Provider Communication**
- [ ] LocationProvider ↔ OffersProvider (standortbasierte Angebote + regionale Filterung)
- [ ] FlashDealsProvider ↔ LocationProvider (lokale Deals + regionale Verfügbarkeit)
- [ ] UserProvider ↔ All Providers (Freemium-Limits)
- [ ] RetailersProvider ↔ LocationProvider (regionale Händler-Filterung)
- [ ] Shared State für Panel-übergreifende Daten
- [ ] Regionale Daten-Synchronisation zwischen Providern

#### **Task 17: Error Handling & Loading States**
- [ ] Loading Indicators für alle Provider
- [ ] Error-Recovery Mechanismen  
- [ ] Offline-Fallback (cached Mock-Daten)
- [ ] User-friendly Error Messages
- [ ] "Keine Händler in Ihrer Region" Error-Cases
- [ ] PLZ-Lookup Fehlerbehandlung (GPS nicht verfügbar, ungültige PLZ)

#### **Task 18: Performance-Optimierung**
- [ ] Provider Disposal richtig implementieren
- [ ] Unnötige Rebuilds vermeiden (Consumer vs Selector)
- [ ] Mock-Daten lazy loading
- [ ] Memory Leak Prevention

---

### **🚀 DEPLOYMENT & TESTING**

#### **Task 19: Flutter Web Build Optimierung** 
- [ ] Build-Errors beheben und Performance optimieren
- [ ] Web-spezifische Anpassungen (URL-Routing)
- [ ] PWA-Features aktivieren (Manifest, Service Worker)
- [ ] Cross-Browser Kompatibilität testen

#### **Task 20: Continuous Deployment Verbesserung**
- [ ] Automatische GitHub Actions für Build & Deploy
- [ ] Custom Domain konfigurieren (falls gewünscht)
- [ ] Performance Monitoring und Analytics
- [ ] SEO-Optimierungen für Web

#### **Task 21: Cross-Device Testing & QR-Code**
- [ ] QR-Code Generator für schnellen Demo-Zugriff
- [ ] Desktop Browser Testing (Chrome, Firefox, Safari)
- [ ] Mobile Browser Testing (iOS Safari, Android Chrome)  
- [ ] Responsive Design Validierung auf verschiedenen Geräten
- [ ] Professor-Demo Durchlauf testen

#### **Task 22: Dokumentation & Demo-Preparation**
- [ ] Feature-Liste für Professor erstellen
- [ ] Screenshot-Serie für Präsentation
- [ ] Known Issues dokumentieren
- [ ] Migration-Plan zu BLoC dokumentieren

---

## **MIGRATION-VORBEREITUNG** (Post-MVP)

#### **Task 23: BLoC-Migration Prep**
- [ ] Repository Interfaces BLoC-ready machen
- [ ] Event/State-Klassen-Entwürfe
- [ ] Migration-Timeline verfeinern
- [ ] Testabdeckung für Repository Layer

---

## **RISIKOMANAGEMENT & FALLBACKS**

### **Critical Path Prioritäten:**
1. **MUSS:** Navigation funktioniert
2. **MUSS:** Mock-Daten werden angezeigt  
3. **MUSS:** Basis-Funktionalität läuft
4. **MUSS:** Deployment klappt
5. **NICE-TO-HAVE:** Animationen, erweiterte Features

### **Zeit-Fallbacks:**
- **Wenn Provider zu komplex:** setState() als Notfall-Lösung
- **Wenn Features zu viele:** Scope reduzieren, nicht Architektur  
- **Wenn Deployment schwierig:** Local-Demo als Backup

---

## **REVIEW-BEREICH**
*Wird nach jedem abgeschlossenen Task aktualisiert*

### **Abgeschlossene Änderungen (Task 4b):**

**✅ GitHub Actions Deployment Setup:**
- Erstellt: `.github/workflows/deploy.yml`
- Automatisches Flutter Web Build bei jedem Push
- Deployment auf GitHub Pages mit `peaceiris/actions-gh-pages@v3`
- Base-href konfiguriert: `--base-href "/FlashFeed/"`

**✅ Dokumentation komplett überarbeitet:**
- `README.md`: Live-Demo Links, Multi-Device Testing, Deployment-Status
- `DEPLOYMENT_SETUP.md`: Schritt-für-Schritt Anleitung + Troubleshooting
- Persistent Claude Handoff System implementiert

**✅ Multi-Device Testing Setup:**
- Lokaler Web-Server Setup dokumentiert (`flutter run -d web-server --web-port=8080`)
- Cross-Platform Testing Strategien
- QR-Code Generation Workflow

### **Aufgetretene Probleme & Lösungen:**
- **Problem:** Kontinuität zwischen Claude-Sessions gewährleisten
- **Lösung:** "LAST CLAUDE POSITION" System in todo.md implementiert
- **Problem:** Deployment-Komplexität reduzieren
- **Lösung:** Automatisches + Manuelles Deployment als Fallback

### **Abweichungen vom Plan:**
- **Änderung:** Task 4b vor Task 5 priorisiert für frühes Live-Testing
- **Grund:** Professor-Demo und 3-Wochen-Timeline profitieren von sofortigem Deployment
- **Vorteil:** Kontinuierliches Testing ab sofort möglich

### **Nächste Schritte:**
**Task 5 (Mock-Daten-Service) ist bereit zum Starten!**
- Repository Pattern ist bereits implementiert
- Provider sind vorbereitet für Mock-Daten Integration  
- Deployment-Pipeline läuft für sofortige Live-Tests

### **Für BLoC-Migration (Post-MVP):**
- Repository Interfaces bleiben unverändert ✅
- Provider → BLoC Migration-Path ist sauber getrennt ✅
- Mock-Daten-Service ist architektur-agnostisch designed ✅

---

**GESAMT-TASKS: 27 Aufgaben (23 ursprünglich + 3 regionale Tasks + 1 Quick Deployment)**  
**GESCHÄTZTE ZEIT: 3-3.5 Wochen**  
**ARCHITEKTUR: Provider → BLoC Migration Ready + Regionale Verfügbarkeit + Continuous Deployment**

### **🗺️ NEUE FEATURES DURCH REGIONALE VERFÜGBARKEIT:**
- **Realistische UX:** Nur verfügbare Händler anzeigen
- **PLZ-basierte Filterung:** BioCompany nur Berlin, Globus nur Süden, etc.
- **GPS + Manual:** Automatische Standorterkennung mit Fallback
- **Cross-Provider Integration:** Regionale Daten zwischen allen Providern
- **Error Handling:** "Nicht in Ihrer Region verfügbar" Cases

### **🚀 CONTINUOUS DEPLOYMENT & TESTING:**
- **Frühes Deployment:** Live-Demo ab Task 4b statt Task 20
- **Multi-Device Testing:** Lokaler Server + GitHub Pages
- **Live-Demo-URL:** Kontinuierliche Updates nach jedem Feature
- **Professor-Ready:** QR-Code Demo und Cross-Platform Testing