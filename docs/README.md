# FlashFeed Landing Page

Diese Landing Page wird über GitHub Pages gehostet und dient als Ziel für QR-Codes.

## Setup GitHub Pages

1. Gehen Sie zu den Repository-Einstellungen auf GitHub
2. Navigieren Sie zu "Pages" im Seitenmenü
3. Wählen Sie unter "Source":
   - Branch: `main` (oder Ihr Hauptbranch)
   - Folder: `/docs`
4. Klicken Sie auf "Save"
5. Die Seite wird verfügbar sein unter: `https://[IHR-GITHUB-USERNAME].github.io/FlashFeed/`

## URL-Struktur

- **Produktion**: `https://alajcaus.github.io/FlashFeed/`
- **Lokal testen**: `http://localhost:8000/docs/`

## Lokaler Test

Um die Landing Page lokal zu testen:

```bash
# Im flashfeed Verzeichnis:
cd docs
python -m http.server 8000
# Oder mit Python 2:
python -m SimpleHTTPServer 8000
```

Dann öffnen Sie: `http://localhost:8000/`

## Features der Landing Page

- Automatische Geräteerkennung (iOS/Android)
- Responsive Design
- Weiterleitung zu App Stores (sobald App veröffentlicht ist)
- Temporäre Info-Seite bis zur Veröffentlichung

## Anpassungen für App-Veröffentlichung

Wenn die App in den Stores veröffentlicht wird, aktualisieren Sie in `index.html`:

1. iOS App Store ID in Zeile 133
2. Android Package ID in Zeile 134
3. Entfernen Sie die "Kommt bald" Hinweise