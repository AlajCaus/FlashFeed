# FlashFeed - Live Shopping Deals App 🛒⚡

## 🎯 Demo Links & Quick Access

- **🌐 Live Demo:** `https://YOUR-USERNAME.github.io/FlashFeed/` (Nach GitHub Pages Setup)
- **📱 QR-Code:** [Wird nach erstem Build generiert]
- **🔄 Status:** Task 4b - Deployment Setup in Progress

---

## 🚀 Quick Setup für GitHub Pages (NÄCHSTER SCHRITT)

### 1. GitHub Pages aktivieren:
```
1. Gehe zu GitHub Repository Settings
2. Scrolle zu "Pages" Sektion  
3. Source: "Deploy from a branch"
4. Branch: "gh-pages" (wird automatisch erstellt)
5. Save
```

### 2. Automatisches Deployment aktivieren:
```bash
# Workflow-Datei wird erstellt in .github/workflows/deploy.yml
# Jeder Push zu main löst automatisch Web-Build aus
```

### 3. Erste Deployment:
```bash
flutter build web
# Build-Ordner wird automatisch auf gh-pages branch deployed
```

---

## 📱 Lokales Multi-Device Testing

### **Desktop Development:**
```bash
# Chrome (Standard)
flutter run -d chrome

# Edge Browser  
flutter run -d edge

# Web-Server für alle Geräte
flutter run -d web-server --web-port=8080
```

### **Mobile Browser Testing:**
```bash
# 1. Web-Server starten
flutter run -d web-server --web-port=8080

# 2. IP-Adresse des PCs herausfinden
ipconfig  # Windows
ifconfig  # Mac/Linux

# 3. Vom Handy aus aufrufen:
http://[PC-IP-ADRESSE]:8080
# Beispiel: http://192.168.1.100:8080
```

### **Cross-Platform Testing:**
- **Desktop:** Chrome, Firefox, Safari, Edge
- **Mobile:** iOS Safari, Android Chrome  
- **Tablets:** iPad Safari, Android Tablets
- **Live-Demo:** Funktioniert überall identisch

---

## 🏗️ Entwicklungsstand (Persistent Documentation)

### ✅ **PHASE 1: GRUNDLAGEN & PROVIDER SETUP** 
- [x] **Task 1:** Provider Package (`provider: ^6.1.1`) ✅
- [x] **Task 2:** Ordnerstruktur (`providers/`, `repositories/`, etc.) ✅  
- [x] **Task 3:** Repository Pattern (4 Repository-Dateien) ✅
- [x] **Task 4:** Core Provider (4 Provider implementiert) ✅
- [🔄] **Task 4b:** Quick Deployment Setup (IN PROGRESS)

### 🔄 **NÄCHSTE TASKS:**
- **Task 5:** Mock-Daten-Service implementieren
- **Task 6:** Drei-Panel-Layout erstellen  
- **Task 7:** AppProvider Integration in main.dart

### 📍 **LAST CLAUDE POSITION:**
- **Aktueller Task:** Task 4b (Quick Deployment Setup)
- **Status:** GitHub Pages Setup-Anweisungen erstellt
- **Nächster Schritt:** GitHub Actions Workflow + todo.md Update
- **Ready for:** Task 5 (Mock-Daten-Service)

---

## 🎮 Professor-Demo Features (Geplant)

### **Live-Demo-Bereit:**
- **🌐 URL:** Direkt aufrufbar auf jedem Gerät
- **📱 QR-Code:** Schneller Handy-Zugriff  
- **⚡ Flash Deal Button:** Instant Deal-Generierung
- **🗺️ GPS-Simulation:** Berlin/München Standorte

### **Multi-Device-Optimiert:**
- **Desktop:** Drei-Panel-Layout (Angebote | Karte | Flash Deals)
- **Tablet:** Responsive Design mit Touch-Navigation
- **Mobile:** Stackable Panels mit Swipe-Gesten

### **Regionale Demo:**
- **Berlin:** EDEKA, REWE, BioCompany verfügbar
- **München:** EDEKA, REWE, Globus verfügbar  
- **PLZ-Eingabe:** Alternative zu GPS für Demo

---

## 🧪 Testing-Strategien

### **Lokale Entwicklung:**
```bash
# Hot Reload Development
flutter run -d chrome --hot

# Production Build Testing  
flutter build web --release
cd build/web && python -m http.server 8000
```

### **Live-Testing:**
- **GitHub Pages:** Automatisch aktualisiert nach Push
- **Multi-Browser:** Alle modernen Browser supported
- **Mobile-First:** Touch-Gesten und Responsive Design

### **Performance Testing:**
- **Desktop:** Chrome DevTools Performance  
- **Mobile:** Safari Developer Tools (iOS)
- **Cross-Platform:** Lighthouse Audits

---

## 📋 Manual Setup Fallback (falls automatisch nicht klappt)

```bash
# 1. Web Build erstellen
flutter build web

# 2. Build-Ordner content kopieren
cp -r build/web/* docs/

# 3. GitHub Pages auf docs/ folder umstellen  
# Settings > Pages > Source: "docs folder"

# 4. Live-Demo URL:
# https://YOUR-USERNAME.github.io/REPOSITORY-NAME/
```

---

## 🎯 Deployment-Ziele (Task 4b)

- [🔄] GitHub Pages konfiguriert
- [🔄] Automatisches Deployment (GitHub Actions)  
- [🔄] Live-Demo URL generiert
- [🔄] Multi-Device Testing Setup
- [🔄] QR-Code für schnellen Zugriff
- [🔄] Dokumentation für nächsten Claude updated

**Nach Abschluss von Task 4b → Task 5: Mock-Daten-Service beginnen**