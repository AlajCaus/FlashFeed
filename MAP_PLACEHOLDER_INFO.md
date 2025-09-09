# Map Placeholder Setup

Da Google Maps erst in Phase 2 kommt, brauchen wir ein Placeholder-Bild.

## Option 1: Einfarbiger Placeholder
Erstelle eine Datei `assets/images/map_placeholder.png` mit einem grauen Hintergrund.

## Option 2: Screenshot
Nimm einen Screenshot von Google Maps Berlin und speichere als `assets/images/map_placeholder.png`.

## pubspec.yaml Update
```yaml
flutter:
  assets:
    - assets/images/
```

Alternativ kann das Bild-Widget durch einen Container ersetzt werden:
```dart
Container(
  color: Colors.grey[200],
  child: Center(...)
)
```
