# FlashFeed Entwicklungsplan - Provider Pattern

## ⚠️ WICHTIG: FREEMIUM-MODELL - NICHT ÄNDERN! ⚠️

### **FREEMIUM-MODELL DEFINITION (FESTGELEGT - KEINE WILLKÜRLICHEN ÄNDERUNGEN!)**

**FREE USER (Kostenlos):**
- ✅ Kann **EINEN (1) Händler** auswählen (z.B. REWE oder EDEKA)
- ✅ Sieht **ALLE Angebote** dieses einen Händlers (KEIN LIMIT!)
- ✅ Sieht **ALLE Flash Deals** dieses einen Händlers (KEIN LIMIT!)
- ✅ Unbegrenzte Suche innerhalb dieses Händlers
- ✅ Vollständige App-Funktionalität für diesen einen Händler

**PREMIUM USER (Bezahlt):**
- ✅ Zugriff auf **ALLE Händler gleichzeitig**
- ✅ Preisvergleich zwischen allen Händlern
- ✅ Multi-Händler-Filter und Suche
- ✅ Karten-Features mit allen Filialen aller Händler
- ✅ Aggregierte Ansicht aller Angebote

**❌ NIEMALS DIESE LIMITS VERWENDEN (FALSCH!):**
- ❌ NICHT: "Max 10 Angebote für Free User"
- ❌ NICHT: "Max 3 Flash Deals für Free User"
- ❌ NICHT: "Max 5 Suchen pro Tag"
- ❌ NICHT: Irgendwelche Content-Limits

**📝 GRUND:**
Free User sollen die volle Funktionalität mit einem Händler erleben können.
Das Upgrade-Argument ist der Preisvergleich zwischen Händlern, nicht künstliche Limits!

---

## PHASE 1: MVP (3 Wochen - Provider-basiert)

### Woche 1: Grundlagen & Provider Setup
**Tage 1-2: Projekt Setup**
- [x] GitHub Repository mit Flutter Web Setup
- [x] Provider Package Integration (provider: ^6.1.1)
- [ ] Basis Provider-Architektur
- [ ] Repository Pattern Setup
- [ ] Mock-Daten-Service

**Tage 3-7: UI Framework & Navigation**  
- [ ] Drei-Panel-Navigation mit Provider State
- [ ] Responsive Design Framework
- [ ] AppProvider für Global State Management
- [ ] Theme Provider Setup

### Woche 2: Core Features mit Provider
**Tage 8-10: Panel 1 - Angebotsvergleich**
- [ ] OffersProvider (statt OffersBloc)
- [ ] RetailerProvider für Händler-Management
- [ ] ProductCategoryProvider mit deinem Mapping-System
- [ ] Freemium-Logic in UserProvider

**Tage 11-14: Panel 2 & 3 - Maps & Flash Deals**
- [ ] MapProvider für GPS & Filialen
- [ ] FlashDealsProvider mit Timer-Logic
- [ ] LocationProvider für Standort-Services
- [ ] Professor-Demo-Button Integration

### Woche 3: Integration & Deployment
**Tage 15-17: Provider-Integration**
- [ ] Provider-to-Provider Communication
- [ ] Shared State Management
- [ ] Error Handling across Providers
- [ ] Performance-Optimierung

**Tage 18-21: Deployment & Testing**
- [ ] Manueller Flutter Web Build
- [ ] GitHub Pages Upload
- [ ] QR-Code Generator
- [ ] Cross-Device Testing

---

## PROVIDER ARCHITECTURE (Vereinfacht)

### Core Providers:
```dart
// Nur 4-5 Provider statt 8+ BLoCs:
AppProvider          // Navigation + Global App State
OffersProvider       // Angebote + Preisvergleich
FlashDealsProvider   // Echtzeit-Rabatte + Timer
UserProvider         // Freemium + Einstellungen
LocationProvider     // GPS + Maps + Filialen
```

### Repository Layer (bleibt für BLoC-Migration):
```dart
// Diese Struktur ist migration-ready:
abstract class OffersRepository {
  Future<List<Offer>> getOffers();
}

class MockOffersRepository implements OffersRepository {
  // Mock-Implementation
}
```

---

## MIGRATION-PFAD (Post-Prototyp)

### Was bleibt unverändert:
- Repository Interfaces
- Model Classes  
- Mock-Data Services
- UI Widgets (größtenteils)

### Was geändert wird:
- Provider → BLoC (State Management Layer)
- ChangeNotifier → Stream-basierte Events
- Direkte setState → Event-driven Updates

### Migration-Timeline:
- **Vorbereitung:** 2-3 Tage (BLoC Package Integration)
- **Core Migration:** 1-2 Wochen (Provider zu BLoC umschreiben)
- **Testing & Integration:** 3-5 Tage
- **Gesamt:** ~3 Wochen für vollständige Migration

---

## ZEIT-ERSPARNIS Provider vs. BLoC

### Provider Development (geschätzt):
- **Setup:** 0.5 Tage
- **Core Providers:** 4-5 Tage  
- **Integration:** 2-3 Tage
- **Gesamt:** ~7-8 Tage für State Management

### BLoC Development (geschätzt):
- **Setup:** 1-2 Tage
- **Core BLoCs:** 8-10 Tage
- **Integration:** 4-5 Tage  
- **Gesamt:** ~13-17 Tage für State Management

**Zeit-Ersparnis: ~6-9 Tage** - perfekt für deine 3-Wochen-Deadline

---

## NÄCHSTE SCHRITTE

1. **Provider Package** zu pubspec.yaml hinzufügen
2. **Repository Pattern** implementieren (migration-ready)
3. **AppProvider** als erstes erstellen (Navigation State)
4. **Mock-Data Service** aufsetzen
5. **UI mit Provider** verbinden

---

## RISIKOMANAGEMENT

### Fallback-Strategien:
- Wenn Provider zu komplex wird → setState() als Notfall
- Wenn Zeit knapp wird → Features reduzieren, nicht Architektur
- Wenn Migration später schwierig → Repository Layer ist sauber getrennt

### Critical Path:
1. Navigation funktioniert
2. Mock-Daten werden angezeigt
3. Basis-Funktionalität läuft
4. Deployment klappt

**Alles andere sind Bonus-Features.**
