# FlashFeed MVP Entwicklungsplan - Provider Pattern (3 Wochen)

## **STATUS-ANALYSE**
- ✅ **Git Setup:** Repository erfolgreich eingerichtet
- ✅ **Flutter Template:** Standard-App läuft  
- ✅ **Produktkategorien-Mapping:** Bereits implementiert (`lib/data/product_category_mapping.dart`)
- ❌ **Provider Package:** Fehlt noch in pubspec.yaml
- ❌ **App-Architektur:** Standard Demo-Code muss komplett ersetzt werden

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
- [ ] `lib/providers/app_provider.dart` - Navigation & Global State
- [ ] `lib/providers/offers_provider.dart` - Angebote & Preisvergleich (mit regionaler Filterung)
- [ ] `lib/providers/user_provider.dart` - Freemium Logic & Settings
- [ ] `lib/providers/location_provider.dart` - GPS & Standort (Basis-Implementierung)

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

#### **Task 19: Flutter Web Build** 
- [ ] `flutter build web --web-renderer html` (bessere Kompatibilität)
- [ ] Build-Errors beheben
- [ ] Web-spezifische Anpassungen (URL-Routing)
- [ ] Performance für Web optimieren

#### **Task 20: GitHub Pages Setup**
- [ ] `build/web/` Ordner zu GitHub Pages hochladen
- [ ] Custom Domain konfigurieren (falls gewünscht)
- [ ] QR-Code für schnellen Demo-Zugriff generieren
- [ ] README mit Live-Demo-Link aktualisieren

#### **Task 21: Cross-Device Testing**
- [ ] Desktop Browser Testing (Chrome, Firefox, Safari)
- [ ] Mobile Browser Testing (iOS Safari, Android Chrome)  
- [ ] Responsive Design Validierung
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
*Wird nach Abschluss aller Tasks aktualisiert*

### **Abgeschlossene Änderungen:**
<!-- Hier werden nach Implementierung die tatsächlichen Änderungen dokumentiert -->

### **Aufgetretene Probleme & Lösungen:**
<!-- Dokumentation von Problemen und wie sie gelöst wurden -->

### **Abweichungen vom Plan:**
<!-- Was musste angepasst werden und warum -->

### **Nächste Schritte (BLoC-Migration):**
<!-- Vorbereitung für die Migration nach MVP -->

---

**GESAMT-TASKS: 26 Aufgaben (23 ursprünglich + 3 regionale Tasks)**  
**GESCHÄTZTE ZEIT: 3-3.5 Wochen**  
**ARCHITEKTUR: Provider → BLoC Migration Ready + Regionale Verfügbarkeit**

### **🗺️ NEUE FEATURES DURCH REGIONALE VERFÜGBARKEIT:**
- **Realistische UX:** Nur verfügbare Händler anzeigen
- **PLZ-basierte Filterung:** BioCompany nur Berlin, Globus nur Süden, etc.
- **GPS + Manual:** Automatische Standorterkennung mit Fallback
- **Cross-Provider Integration:** Regionale Daten zwischen allen Providern
- **Error Handling:** "Nicht in Ihrer Region verfügbar" Cases