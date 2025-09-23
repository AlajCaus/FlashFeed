# ANALYSE: Store-Pins werden auf der Karte nicht angezeigt

## Problem
Die Store-Pins (Punkt 2 aus der Map-Funktionalität) werden auf der Karte nicht angezeigt.

## Ursachenanalyse

### 1. Store-Daten werden nicht automatisch geladen
- **Problem**: `retailersProvider.allStores` ist initial leer
- **Zeile**: map_screen.dart:206
- **Grund**: Die Stores werden nur bei Bedarf geladen (lazy loading) via `_loadAllStores()`
- **_loadAllStores()** wird nur aufgerufen wenn:
  - `searchStores()` mit Radius aufgerufen wird UND `_allStores` leer ist (Zeile 478)
  - `searchStores()` mit Text aufgerufen wird UND `_allStores` leer ist (Zeile 1232)

### 2. MapScreen lädt keine Stores beim Start
- **Problem**: Die MapScreen ruft keine Methode auf, die die Stores lädt
- **Code**: `retailersProvider.allStores` gibt eine leere Liste zurück
- **Folge**: `_buildStoreMarkers()` erstellt keine Marker, da die Store-Liste leer ist

## Lösung

### Option 1: Stores in MapScreen laden (EMPFOHLEN)
In `map_screen.dart` initState():
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final locationProvider = context.read<LocationProvider>();
    final retailersProvider = context.read<RetailersProvider>();

    // Ensure location data is loaded
    await locationProvider.ensureLocationData();

    // Load stores near current location
    if (locationProvider.hasLocation) {
      await retailersProvider.searchStores(
        '',  // Empty query to get all stores
        latitude: locationProvider.latitude,
        longitude: locationProvider.longitude,
        radiusKm: _radiusKm,
      );
    }
  });
}
```

### Option 2: Stores automatisch in RetailersProvider laden
Im Konstruktor von RetailersProvider:
```dart
RetailersProvider({
  required RetailersRepository repository,
  required MockDataService mockDataService,
}) : _repository = repository {
  loadRetailers();
  _loadAllStores(); // Stores auch direkt laden
}
```

### Option 3: allStores Getter anpassen (Quick Fix)
Getter so ändern, dass er automatisch lädt wenn leer:
```dart
List<Store> get allStores {
  if (_allStores.isEmpty && !_isLoadingStores) {
    _loadAllStoresSync(); // Neue synchrone Methode
  }
  return List.unmodifiable(_allStores);
}
```

## Empfehlung
**Option 1** ist die beste Lösung, da sie:
- Nur Stores im relevanten Radius lädt (Performance)
- Mit dem bestehenden Location-Flow arbeitet
- Keine Breaking Changes verursacht
- Der Map-Screen die Kontrolle gibt über wann/was geladen wird