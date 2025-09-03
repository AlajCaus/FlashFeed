# FlashFeed Entwicklungsplan - Gestaffelte Phasen

## PHASE 1: MVP (3 Wochen - KRITISCHER PFAD)

### Woche 1: Grundlagen & UI Framework
**Tage 1-2: Projekt Setup**
- [x] GitHub Repository mit Flutter Web Setup
- [ ] CI/CD Pipeline für GitHub Pages 
- [ ] BLoC State Management Architektur
- [ ] Responsive Design Framework
- [ ] Mock-Daten-Architektur

**Tage 3-7: Drei-Panel-Navigation**  
- [ ] Statisches Top-Panel mit Hamburger-Menü
- [ ] Tab-Navigation zwischen 3 Panels
- [ ] Overlay-Einstellungsmenü
- [ ] Basis-Styling & Responsive Breakpoints
- [ ] Navigation State Management (BLoC)

### Woche 2: Core Features
**Tage 8-10: Panel 1 - Angebotsvergleich**
- [ ] Händler-Icon-Leiste (horizontal scrollbar)
- [ ] Produktgruppen-Grid (10 Kategorien)
- [ ] Mock-Angebotsdaten Integration
- [ ] Freemium-Logik (1 kostenlos, Rest Premium)
- [ ] Produktgruppen-Mapping implementieren

**Tage 11-14: Panel 2 & 3 - Maps & Echtzeit**
- [ ] Google Maps Integration
- [ ] GPS-Standorterkennung  
- [ ] Filial-Pins auf Karte
- [ ] Echtzeit-Rabatte Feed
- [ ] Countdown-Timer für Angebote
- [ ] **PROFESSOR-DEMO-BUTTON** für sofortige Rabatt-Generierung

### Woche 3: Polish & Deployment
**Tage 15-17: Feature-Integration**
- [ ] Cross-Panel Daten-Synchronisation
- [ ] Preisvergleich zwischen Händlern
- [ ] Ersparnis-Berechnungen
- [ ] Mock-Freemium-Kaufprozess
- [ ] Performance-Optimierung

**Tage 18-21: Deployment & Testing**
- [ ] GitHub Pages automatisches Deployment
- [ ] QR-Code Generator für Professor-Zugang
- [ ] Cross-Browser Testing
- [ ] Mobile Responsive Testing
- [ ] Dokumentation für Professor

---

## PHASE 2: STRETCH GOALS (Falls Zeit bleibt)

### Priorität A (Wenn 2-3 Tage extra Zeit):
- [ ] Intelligente Einkaufsliste (Basis-Version)
- [ ] Web Push Notifications
- [ ] Erweiterte Filial-Details auf Karte

### Priorität B (Wenn 4-7 Tage extra Zeit):
- [ ] FlashFeed Coins Gamification  
- [ ] B2B Mock-Dashboard
- [ ] Erweiterte Analytics-Simulation

### Priorität C (Wenn 1+ Wochen extra Zeit):
- [ ] Indoor-Navigation Simulator
- [ ] Lageplan-System mit SVG
- [ ] Community Features (Bewertungen)

---

## RISIKO-MANAGEMENT

### Kritische Pfad-Abhängigkeiten:
1. **Google Maps API** - Fallback: OpenStreetMap
2. **GitHub Pages Deployment** - Fallback: Netlify
3. **Mock-Daten Komplexität** - Fallback: Vereinfachte Datensätze

### Time-Saver Strategien:
- **UI-Kit verwenden** statt Custom Design
- **Existing Flutter Packages** für Maps/State Management  
- **Vereinfachte Mock-Daten** statt realistische komplexe Datensätze
- **Template-basierte Komponenten** für schnelle Entwicklung

### Qualität vs. Geschwindigkeit:
- **MVP:** Funktionalität > Perfektion
- **Stretch Goals:** Nur hinzufügen wenn MVP 100% stabil

---

## ERFOLGS-DEFINITION

### MVP Minimum (für Note): 
✅ Drei-Panel-Navigation funktioniert  
✅ Produktgruppen-Mapping demonstriert  
✅ Echtzeit-Rabatte mit Professor-Demo-Button  
✅ Deployment auf GitHub Pages mit QR-Code  

### MVP Ideal (für sehr gute Note):
✅ Alle MVP Features + Mock-Freemium-System
✅ Google Maps mit GPS-Integration  
✅ Cross-Händler Preisvergleich funktional  
✅ Responsive Design perfekt  

### Stretch Goal Erfolg:
✅ MVP + mindestens 2 Priorität A Features  
✅ Zusätzliche "Wow-Faktoren" für Präsentation
