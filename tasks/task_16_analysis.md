# Task 16: Cross-Provider Communication - Analyse & Implementierung

## 🔍 AKTUELLE SITUATION

### Bereits vorhandene Provider-Kommunikation:
1. **OffersProvider → LocationProvider** ✅
   - `registerWithLocationProvider()` bereits implementiert (Zeile 129-147)
   - Callbacks für Location & Regional Data vorhanden
   - `_onLocationChanged()` und `_onRegionalDataChanged()` implementiert

2. **FlashDealsProvider → LocationProvider** ✅
   - `registerWithLocationProvider()` bereits implementiert (Zeile 72-88)
   - Callbacks für Location & Regional Data vorhanden
   - Timer-Reset bei Location-Änderung implementiert

3. **RetailersProvider → LocationProvider** ❓
   - Muss noch überprüft werden

4. **UserProvider → All Providers** ❌
   - Freemium-Limits noch nicht implementiert

## 📋 IMPLEMENTIERUNGSPLAN

### Phase 1: Analyse bestehender Integration
- [x] OffersProvider Integration analysiert
- [x] FlashDealsProvider Integration analysiert
- [ ] RetailersProvider Integration prüfen
- [ ] UserProvider Status prüfen

### Phase 2: Fehlende Integrationen
1. **RetailersProvider ↔ LocationProvider**
   - Store-Filterung nach Standort
   - Entfernungsberechnung für alle Stores
   - Regionale Händler-Priorisierung

2. **UserProvider → All Providers (Freemium)**
   - Max 5 Angebote für Free-User
   - Max 3 Flash Deals für Free-User
   - Premium-Badge in UI

3. **Shared State Management**
   - Zentrale selectedRetailer State
   - Cross-Panel Navigation
   - Konsistente Filter-States

### Phase 3: Testing
- Unit Tests für Provider-Kommunikation
- Integration Tests für Cross-Provider Events
- Performance Tests für Event-Propagation

## 🎯 AUSWIRKUNGSANALYSE

### Betroffene Dateien:
1. **lib/providers/retailers_provider.dart**
   - LocationProvider Integration hinzufügen
   - Store-Filterung nach Distanz

2. **lib/providers/user_provider.dart**
   - Freemium-Logic implementieren
   - Premium-Status Management

3. **lib/screens/main_layout_screen.dart**
   - Provider-Registrierung bei App-Start
   - Cleanup bei Dispose

4. **lib/main.dart**
   - Provider-Reihenfolge prüfen
   - Dependencies korrekt setzen

### Breaking Changes:
- KEINE - Nur Erweiterungen

### Test-Auswirkungen:
- Bestehende Tests müssen Provider-Mocking erweitern
- Neue Tests für Cross-Provider Communication

## ⚠️ WICHTIGE PUNKTE

1. **Memory Leaks vermeiden:**
   - Alle Callbacks müssen in dispose() entfernt werden
   - Provider-Referenzen cleanen

2. **Circular Dependencies vermeiden:**
   - Keine direkten Provider-zu-Provider Referenzen
   - Nur Callbacks und Events verwenden

3. **Performance:**
   - Debouncing für häufige Updates
   - Selective rebuilds mit Consumer/Selector

## 🚀 NÄCHSTE SCHRITTE

1. RetailersProvider Integration implementieren
2. UserProvider Freemium-Logic hinzufügen
3. Shared State für selectedRetailer
4. Tests schreiben
5. Integration in main_layout_screen.dart