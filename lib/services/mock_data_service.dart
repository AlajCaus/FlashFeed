import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/product_category_mapping.dart';
import '../models/models.dart';

/*
 * FlashFeed Mock Data Service - Provider-optimiert
 * 
 * ARCHITEKTUR-ÄNDERUNG: Provider statt BLoC
 * 
 * URSPRÜNGLICH (Flutter Projektstruktur):
 * - BLoC-basiert mit Storage-only Updates
 * - Timer-Updates schrieben nur in SharedPreferences
 * - BLoCs lasen periodisch aus Storage
 * 
 * ANGEPASST FÜR PROVIDER:
 * - Direkte Provider-Callbacks für Live-Updates
 * - Timer-System benachrichtigt Provider sofort
 * - Kein Storage-Polling nötig
 * 
 * MIGRATION-READY:
 * - Service-Interface bleibt architektur-agnostisch
 * - Repository Pattern unverändert  
 * - Spätere BLoC-Migration: nur Callback-System ändern
 */

class MockDataService {
  Timer? _flashDealTimer;
  Timer? _countdownTimer;
  final Random _random;
  
  // Constructor with optional seed for deterministic testing
  MockDataService({int? seed}) 
    : _seed = seed,
      _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    if (seed != null) {
      debugPrint('🎲 MockDataService: Using seed $seed for deterministic data');
    }
  }
  
  // Provider Callbacks (statt BLoC Events)
  VoidCallback? _onFlashDealsUpdated;
  VoidCallback? _onOffersUpdated;
  VoidCallback? _onStoresUpdated;
  
  // Generated Mock Data (basierend auf Datenbank-Schema)
  List<Retailer> _retailers = [];
  List<Store> _stores = [];
  List<Product> _products = [];
  List<Offer> _offers = [];
  List<FlashDeal> _flashDeals = [];
  
  bool _isInitialized = false;
  
  // Getters für generierte Daten
  List<Retailer> get retailers => List.unmodifiable(_retailers);
  List<Store> get stores => List.unmodifiable(_stores);
  List<Product> get products => List.unmodifiable(_products);
  List<Offer> get offers => List.unmodifiable(_offers);
  List<FlashDeal> get flashDeals => List.unmodifiable(_flashDeals);
  
  bool get isInitialized => _isInitialized;
  
  // Expose random seed for testing
  int? _seed;
  int? get seed => _seed;

  // Provider-Callback Registration
  void setFlashDealsCallback(VoidCallback callback) {
    _onFlashDealsUpdated = callback;
  }
  
  void setOffersCallback(VoidCallback callback) {
    _onOffersUpdated = callback;
  }
  
  void setStoresCallback(VoidCallback callback) {
    _onStoresUpdated = callback;
  }

  // Provider-Callback Unregistration (FIX: für proper disposal)
  void clearFlashDealsCallback() {
    _onFlashDealsUpdated = null;
  }
  
  void clearOffersCallback() {
    _onOffersUpdated = null;
  }
  
  void clearStoresCallback() {
    _onStoresUpdated = null;
  }

  // Initialization (aufgerufen von main.dart)
  Future<void> initializeMockData({bool testMode = false}) async {
    if (_isInitialized) return;
    
    debugPrint('🏗️ MockDataService: Initialisiere Mock-Daten...');
    
    try {
      // Generate all mock data based on database schema
      await _generateRetailers();
      await _generateStores();
      await _generateProducts();
      await _generateOffers();
      await _generateFlashDeals();
      
      _isInitialized = true;
      
      // Start periodic updates for real-time simulation (nicht in Tests)
      if (!testMode) {
        _startPeriodicUpdates();
      } else {
        debugPrint('⚠️ MockDataService: Test-Mode - Timer werden nicht gestartet');
      }
      
      debugPrint('✅ MockDataService: Initialisierung abgeschlossen');
      debugPrint('   • ${_retailers.length} Retailers generiert');
      debugPrint('   • ${_stores.length} Stores generiert');
      debugPrint('   • ${_products.length} Products generiert');
      debugPrint('   • ${_offers.length} Offers generiert');
      debugPrint('   • ${_flashDeals.length} Flash Deals generiert');
      
    } catch (e) {
      debugPrint('❌ MockDataService Fehler: $e');
      rethrow;
    }
  }

  // Timer-System für Provider (statt BLoC Storage-Updates)
  void _startPeriodicUpdates() {
    // Flash Deals Updates: alle 2 Stunden neue Deals
    _flashDealTimer?.cancel();
    _flashDealTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _updateFlashDeals();
      _onFlashDealsUpdated?.call(); // Direkte Provider-Benachrichtigung
    });
    
    // Countdown Updates: alle 60 Sekunden Timer aktualisieren
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdownTimers();
      _onFlashDealsUpdated?.call(); // Provider-Update für Timer
    });
    
    debugPrint('⏰ MockDataService: Timer gestartet (Flash Deals: 2h, Countdown: 1min)');
  }

  // Mock Data Generation basierend auf Datenbank-Schema
  Future<void> _generateRetailers() async {
    _retailers = [
      Retailer(
        id: 'edeka',
        name: 'EDEKA',
        displayName: 'EDEKA',
        logoUrl: 'assets/images/logos/edeka.png',
        primaryColor: '#005CA9',
        description: 'Deutschlands größte Supermarkt-Kooperation',
        categories: ['Molkereiprodukte', 'Frischfleisch', 'Obst', 'Gemüse', 'Backwaren', 'Getränke', 'Tiefkühlprodukte'],
        isPremiumPartner: true,
        website: 'https://www.edeka.de',
        storeCount: 7,
        // Task 5a: EDEKA ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'rewe',
        name: 'REWE',
        displayName: 'REWE',
        logoUrl: 'assets/images/logos/rewe.png',
        primaryColor: '#CC071E',
        description: 'Ihr Nahversorger mit nachhaltigen Produkten',
        categories: ['Milch & Käse', 'Fleisch & Geflügel', 'Frisches Obst', 'Frisches Gemüse', 'Brot & Bäckerei', 'Getränke & Alkohol'],
        isPremiumPartner: true,
        website: 'https://www.rewe.de',
        storeCount: 7,
        // Task 5a: REWE ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'aldi',
        name: 'ALDI SÜD',
        displayName: 'ALDI',
        logoUrl: 'assets/images/logos/aldi.png',
        primaryColor: '#00549F',
        description: 'Einfach günstig - Qualität zum besten Preis',
        categories: ['Milcherzeugnisse', 'Frischfleisch', 'Obst & Gemüse', 'Backwaren', 'Getränke', 'Tiefkühl'],
        isPremiumPartner: false,
        website: 'https://www.aldi-sued.de',
        storeCount: 7,
        // Task 5a: ALDI SÜD ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'lidl',
        name: 'LIDL',
        displayName: 'LIDL',
        logoUrl: 'assets/images/logos/lidl.png',
        primaryColor: '#0050AA',
        description: 'Mehr frische Ideen - Qualität und Frische',
        categories: ['Backwaren', 'Milchprodukte', 'Obst & Gemüse', 'Fleisch & Geflügel', 'Getränke', 'Tiefkühl'],
        isPremiumPartner: false,
        website: 'https://www.lidl.de',
        storeCount: 7,
        // Task 5a: LIDL ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'netto_schwarz',
        name: 'NETTO',
        displayName: 'Netto',
        logoUrl: 'assets/images/logos/netto-schwarz.png',
        primaryColor: '#FFD100',
        description: 'Jeden Tag ein bisschen besser',
        categories: ['Getränke', 'Konserven', 'Molkereiprodukte', 'Fleisch & Wurst', 'Obst & Gemüse', 'Backshop'],
        isPremiumPartner: false,
        website: 'https://www.netto-online.de',
        storeCount: 7,
        // Task 5a: Netto (schwarz) primär in Nord/Ost-Deutschland
        availablePLZRanges: [
          PLZRange(startPLZ: '01000', endPLZ: '39999', regionName: 'Nord/Ost-Deutschland'),
        ],
      ),
      // Task 5.6: Erweiterte Händler für vollständige deutsche LEH-Landschaft
      Retailer(
        id: 'penny',
        name: 'PENNY',
        displayName: 'Penny',
        logoUrl: 'assets/images/logos/penny.png',
        primaryColor: '#D4001A',
        description: 'Preise gut, alles gut',
        categories: ['Getränke', 'Süßwaren', 'Molkereiprodukte', 'Obst & Gemüse', 'Fleisch & Wurst', 'Backwaren'],
        isPremiumPartner: false,
        website: 'https://www.penny.de',
        storeCount: 3,
        // Task 5a: Penny ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'kaufland',
        name: 'KAUFLAND',
        displayName: 'Kaufland',
        logoUrl: 'assets/images/logos/kaufland.png',
        primaryColor: '#C8102E',
        description: 'Das ist gut für alle',
        categories: ['Molkereiprodukte', 'Obst & Gemüse', 'Fleisch & Geflügel', 'Backwaren', 'Getränke', 'Tiefkühl', 'Bio-Produkte'],
        isPremiumPartner: true,
        website: 'https://www.kaufland.de',
        storeCount: 2,
        // Task 5a: Kaufland ist bundesweit verfügbar (keine PLZ-Beschränkungen)
        availablePLZRanges: [], // Bundesweit
      ),
      Retailer(
        id: 'real',
        name: 'REAL',
        displayName: 'Real',
        logoUrl: 'assets/images/logos/real.png',
        primaryColor: '#005CA9',
        description: 'Einmal hin. Alles drin',
        categories: ['Frische-Theke', 'Molkereiprodukte', 'Obst & Gemüse', 'Fleisch & Fisch', 'Backwaren', 'Getränke', 'Bio-Produkte'],
        isPremiumPartner: true,
        website: 'https://www.real.de',
        storeCount: 2,
        // Task 5a: Real nur in NRW (Stores in PLZ 42277, 40249)
        availablePLZRanges: [
          PLZRange(startPLZ: '40000', endPLZ: '59999', regionName: 'Nordrhein-Westfalen'),
        ],
      ),
      Retailer(
        id: 'globus',
        name: 'GLOBUS',
        displayName: 'Globus',
        logoUrl: 'assets/images/logos/globus.png',
        primaryColor: '#0033A0',
        description: 'Meine Zeit. Mein Globus',
        categories: ['Premium-Fleisch', 'Bio-Produkte', 'Molkereiprodukte', 'Obst & Gemüse', 'Backwaren', 'Getränke', 'Feinkost'],
        isPremiumPartner: true,
        website: 'https://www.globus.de',
        storeCount: 1,
        // Task 5a: Globus in Süd/West-Deutschland (Store in PLZ 54974)
        availablePLZRanges: [
          PLZRange(startPLZ: '50000', endPLZ: '99999', regionName: 'Süd/West-Deutschland'),
        ],
      ),
      Retailer(
        id: 'marktkauf',
        name: 'MARKTKAUF',
        displayName: 'Marktkauf',
        logoUrl: 'assets/images/logos/marktkauf.png',
        primaryColor: '#009639',
        description: 'Hier kauf ich gern',
        categories: ['Molkereiprodukte', 'Obst & Gemüse', 'Fleisch & Wurst', 'Backwaren', 'Getränke', 'Tiefkühl'],
        isPremiumPartner: false,
        website: 'https://www.marktkauf.de',
        storeCount: 1,
        // Task 5a: Marktkauf in Brandenburg/NRW (Store in PLZ 14503 Teltow)
        availablePLZRanges: [
          PLZRange(startPLZ: '14500', endPLZ: '59999', regionName: 'Brandenburg bis NRW'),
        ],
      ),
      // Task 5a: Beispiel für regionalen Händler (BioCompany)
      Retailer(
        id: 'biocompany',
        name: 'BIOCOMPANY',
        displayName: 'BioCompany',
        logoUrl: 'assets/images/logos/biocompany.png',
        primaryColor: '#7CB342',
        description: 'Bio für die Stadt',
        categories: ['Bio-Obst', 'Bio-Gemüse', 'Bio-Milchprodukte', 'Bio-Backwaren', 'Naturkosmetik'],
        isPremiumPartner: true,
        website: 'https://www.biocompany.de',
        storeCount: 0, // Keine Mock-Filialen für Demo
        // Task 5a: BioCompany nur in Berlin/Brandenburg
        availablePLZRanges: [
          PLZRange(startPLZ: '10000', endPLZ: '16999', regionName: 'Berlin/Brandenburg'),
        ],
      ),
    ];
  }

  Future<void> _generateStores() async {
    // Task 5.6: Realistische Berliner Standorte für alle 10 deutschen LEH-Händler
    // 35+ Filialen mit präzisen GPS-Koordinaten für Professor-Demo
    final realisticStoreLocations = {
      'edeka': [
        {'name': 'EDEKA Neukauf Alexanderplatz', 'street': 'Alexanderstraße 9', 'plz': '10178', 'lat': 52.521918, 'lng': 13.413209},
        {'name': 'EDEKA Center Potsdamer Platz', 'street': 'Potsdamer Platz 1', 'plz': '10785', 'lat': 52.509618, 'lng': 13.376208},
        {'name': 'EDEKA Supermarkt Prenzlauer Berg', 'street': 'Kastanienallee 77', 'plz': '10435', 'lat': 52.533845, 'lng': 13.401947},
        {'name': 'EDEKA Markt Charlottenburg', 'street': 'Kantstraße 108', 'plz': '10627', 'lat': 52.504829, 'lng': 13.307739},
        {'name': 'EDEKA Friedrichshain', 'street': 'Warschauer Straße 33', 'plz': '10243', 'lat': 52.506738, 'lng': 13.453014},
        {'name': 'EDEKA Kreuzberg', 'street': 'Bergmannstraße 88', 'plz': '10961', 'lat': 52.493918, 'lng': 13.389634},
        {'name': 'EDEKA Mitte Hackescher Markt', 'street': 'Rosenthaler Straße 40', 'plz': '10178', 'lat': 52.525847, 'lng': 13.401534}
      ],
      'rewe': [
        {'name': 'REWE City Unter den Linden', 'street': 'Unter den Linden 26', 'plz': '10117', 'lat': 52.517037, 'lng': 13.388860},
        {'name': 'REWE Markt Schöneberg', 'street': 'Hauptstraße 155', 'plz': '10827', 'lat': 52.482743, 'lng': 13.356912},
        {'name': 'REWE Center Wedding', 'street': 'Müllerstraße 143', 'plz': '13353', 'lat': 52.543089, 'lng': 13.366834},
        {'name': 'REWE Neukölln', 'street': 'Karl-Marx-Straße 78', 'plz': '12043', 'lat': 52.476924, 'lng': 13.440284},
        {'name': 'REWE Steglitz', 'street': 'Schloßstraße 82', 'plz': '12165', 'lat': 52.456745, 'lng': 13.326534},
        {'name': 'REWE Wilmersdorf', 'street': 'Bundesallee 39', 'plz': '10717', 'lat': 52.489834, 'lng': 13.326512},
        {'name': 'REWE Spandau Altstadt', 'street': 'Carl-Schurz-Straße 15', 'plz': '13597', 'lat': 52.537012, 'lng': 13.200334}
      ],
      'aldi': [
        {'name': 'ALDI SÜD Mitte', 'street': 'Torstraße 104', 'plz': '10119', 'lat': 52.526734, 'lng': 13.402534},
        {'name': 'ALDI SÜD Tempelhof', 'street': 'Tempelhofer Damm 227', 'plz': '12099', 'lat': 52.458123, 'lng': 13.387012},
        {'name': 'ALDI SÜD Pankow', 'street': 'Breite Straße 43', 'plz': '13187', 'lat': 52.569234, 'lng': 13.401534},
        {'name': 'ALDI SÜD Lichtenberg', 'street': 'Frankfurter Allee 69', 'plz': '10247', 'lat': 52.514723, 'lng': 13.469312},
        {'name': 'ALDI SÜD Reinickendorf', 'street': 'Residenzstraße 90', 'plz': '13409', 'lat': 52.569234, 'lng': 13.326512},
        {'name': 'ALDI SÜD Treptow', 'street': 'Elsenstraße 15', 'plz': '12435', 'lat': 52.490612, 'lng': 13.453634},
        {'name': 'ALDI SÜD Mariendorf', 'street': 'Mariendorfer Damm 47', 'plz': '12109', 'lat': 52.443123, 'lng': 13.389634}
      ],
      'lidl': [
        {'name': 'Lidl Berlin-Mitte', 'street': 'Chausseestraße 125', 'plz': '10115', 'lat': 52.535812, 'lng': 13.366834},
        {'name': 'Lidl Friedenau', 'street': 'Rheinstraße 32', 'plz': '12161', 'lat': 52.472034, 'lng': 13.339612},
        {'name': 'Lidl Hellersdorf', 'street': 'Hellersdorfer Straße 159', 'plz': '12627', 'lat': 52.534234, 'lng': 13.608912},
        {'name': 'Lidl Köpenick', 'street': 'Bahnhofstraße 33', 'plz': '12555', 'lat': 52.445834, 'lng': 13.574812},
        {'name': 'Lidl Hohenschönhausen', 'street': 'Konrad-Wolf-Straße 52', 'plz': '13055', 'lat': 52.553612, 'lng': 13.469312},
        {'name': 'Lidl Zehlendorf', 'street': 'Clayallee 336', 'plz': '14169', 'lat': 52.443123, 'lng': 13.263012},
        {'name': 'Lidl Weißensee', 'street': 'Berliner Allee 260', 'plz': '13088', 'lat': 52.553612, 'lng': 13.453634}
      ],
      'netto_schwarz': [
        {'name': 'Netto Marken-Discount Alt-Moabit', 'street': 'Alt-Moabit 88', 'plz': '10559', 'lat': 52.521934, 'lng': 13.347812},
        {'name': 'Netto Marken-Discount Rudow', 'street': 'Neuköllner Straße 311', 'plz': '12357', 'lat': 52.443123, 'lng': 13.483234},
        {'name': 'Netto Marken-Discount Gesundbrunnen', 'street': 'Gesundbrunnenstraße 61', 'plz': '13357', 'lat': 52.553612, 'lng': 13.389634},
        {'name': 'Netto Marken-Discount Buch', 'street': 'Wiltbergstraße 24', 'plz': '13125', 'lat': 52.630834, 'lng': 13.453634},
        {'name': 'Netto Marken-Discount Adlershof', 'street': 'Dorfaue 4', 'plz': '12489', 'lat': 52.434223, 'lng': 13.542734},
        {'name': 'Netto Marken-Discount Spandau', 'street': 'Klosterstraße 36', 'plz': '13581', 'lat': 52.537012, 'lng': 13.200334},
        {'name': 'Netto Marken-Discount Britz', 'street': 'Britzer Damm 127', 'plz': '12347', 'lat': 52.434223, 'lng': 13.440284}
      ],
      'penny': [
        {'name': 'Penny Markt Alexanderplatz', 'street': 'Karl-Liebknecht-Straße 13', 'plz': '10178', 'lat': 52.521445, 'lng': 13.412834},
        {'name': 'Penny Markt Steglitz', 'street': 'Schloßstraße 94', 'plz': '12165', 'lat': 52.456234, 'lng': 13.327123},
        {'name': 'Penny Markt Weißensee', 'street': 'Berliner Allee 270', 'plz': '13088', 'lat': 52.554123, 'lng': 13.454234}
      ],
      'kaufland': [
        {'name': 'Kaufland Ostbahnhof', 'street': 'Stralauer Platz 33-34', 'plz': '10243', 'lat': 52.507834, 'lng': 13.434512},
        {'name': 'Kaufland Spandau', 'street': 'Neuendorfer Straße 60', 'plz': '13585', 'lat': 52.537923, 'lng': 13.201234}
      ],
      'real': [
        {'name': 'Real Wuppertal', 'street': 'Großbeerenstraße 263', 'plz': '42277', 'lat': 52.418734, 'lng': 13.373912},
        {'name': 'Real Düsseldorf', 'street': 'Landsberger Allee 563', 'plz': '40249', 'lat': 52.524123, 'lng': 13.491234}
      ],
      'globus': [
        {'name': 'Globus Neustadt', 'street': 'Lüdenscheider Weg 1', 'plz': '54974', 'lat': 52.367834, 'lng': 13.212345}
      ],
      'marktkauf': [
        {'name': 'Marktkauf Teltow', 'street': 'Unter den Eichen 96a', 'plz': '14503', 'lat': 52.436712, 'lng': 13.318456}
      ]
    };
    
    // München Standorte (für Diversität - wenige Fallback-Filialen)
    final munichLocations = [
      {'name': 'München Zentrum', 'street': 'Marienplatz 8', 'plz': '80331', 'lat': 48.137434, 'lng': 11.575512},
      {'name': 'München Schwabing', 'street': 'Leopoldstraße 82', 'plz': '80802', 'lat': 48.164223, 'lng': 11.581634}
    ];
    
    _stores = [];
    int storeCounter = 1;
    
    for (final retailer in _retailers) {
      final retailerLocations = realisticStoreLocations[retailer.id] ?? [];
      
      for (int i = 0; i < (retailer.storeCount ?? 0); i++) {
        Map<String, dynamic> storeLocation;
        
        if (i < retailerLocations.length) {
          // Verwende realistische Berliner Standorte
          storeLocation = retailerLocations[i];
        } else {
          // Fallback: München für übrige Filialen
          storeLocation = munichLocations[i % munichLocations.length];
        }
        
        final storeZipCode = storeLocation['plz'].toString();
        final isInBerlin = storeZipCode.startsWith('1');
        
        _stores.add(Store(
          id: 'store_${storeCounter.toString().padLeft(3, '0')}',
          chainId: retailer.id,
          retailerName: retailer.name,
          name: storeLocation['name'] as String,
          street: storeLocation['street'] as String,
          zipCode: storeZipCode,
          city: isInBerlin ? 'Berlin' : 'München',
          latitude: storeLocation['lat'] as double,
          longitude: storeLocation['lng'] as double,
          phoneNumber: isInBerlin ? '+49 30 ${_random.nextInt(90000000) + 10000000}' : '+49 89 ${_random.nextInt(90000000) + 10000000}',
          openingHours: _generateOpeningHours(),
          services: _generateStoreServices(retailer.name),
          hasWifi: _random.nextBool(),
          hasPharmacy: false,
          hasBeacon: _random.nextBool(),
          isActive: true,
        ));
        storeCounter++;
      }
    }
  }

  Future<void> _generateProducts() async {
    final productTemplates = {
      'Obst & Gemüse': [
        {'name': 'Äpfel 1kg', 'brand': 'Bio Regional', 'price': 249},
        {'name': 'Bananen 1kg', 'brand': 'Chiquita', 'price': 179},
        {'name': 'Bio-Äpfel Braeburn 1kg', 'brand': 'Bio Regional', 'price': 249},
        {'name': 'Bio-Bananen 1kg', 'brand': 'Chiquita', 'price': 179},
        {'name': 'Tomaten 500g', 'brand': 'Bioland', 'price': 199},
        {'name': 'Gurken 1 Stück', 'brand': 'Regional', 'price': 89},
        {'name': 'Kartoffeln 2.5kg', 'brand': 'Linda', 'price': 299},
      ],
      'Milchprodukte': [
        {'name': 'Vollmilch 1L', 'brand': 'Landliebe', 'price': 129},
        {'name': 'Bio-Vollmilch 1L', 'brand': 'Landliebe', 'price': 129},
        {'name': 'Joghurt Natur 500g', 'brand': 'Danone', 'price': 89},
        {'name': 'Butter 250g', 'brand': 'Kerrygold', 'price': 219},
        {'name': 'Käse Gouda 200g', 'brand': 'Meine Käserei', 'price': 189},
        {'name': 'Quark 500g', 'brand': 'Ehrmann', 'price': 109},
      ],
      'Fleisch & Wurst': [
        {'name': 'Hähnchenbrust 1kg', 'brand': 'Wiesenhof', 'price': 699},
        {'name': 'Rinderhack 500g', 'brand': 'Meine Metzgerei', 'price': 449},
        {'name': 'Bratwurst 4 Stück', 'brand': 'Thüringer', 'price': 349},
        {'name': 'Schnitzel 400g', 'brand': 'Landfleisch', 'price': 599},
      ],
      'Brot & Backwaren': [
        {'name': 'Vollkornbrot 500g', 'brand': 'Harry', 'price': 189},
        {'name': 'Brötchen 6 Stück', 'brand': 'Goldähren', 'price': 149},
        {'name': 'Milchbrötchen 4 Stück', 'brand': 'Bäckerei', 'price': 179},
        {'name': 'Croissants 4 Stück', 'brand': 'Coppenrath', 'price': 199},
      ],
      'Getränke': [
        {'name': 'Mineralwasser 12x1L', 'brand': 'Volvic', 'price': 399},
        {'name': 'Apfelsaft 1L', 'brand': 'Hohes C', 'price': 179},
        {'name': 'Cola 1.5L', 'brand': 'Coca Cola', 'price': 149},
      ],
    };
    
    _products = [];
    int productCounter = 1;
    
    productTemplates.forEach((categoryName, templates) {
      for (final template in templates) {
        _products.add(Product(
          id: 'prod_${productCounter.toString().padLeft(3, '0')}',
          categoryName: categoryName,
          name: template['name'] as String,
          brand: template['brand'] as String,
          basePriceCents: template['price'] as int,
          isActive: true,
        ));
        productCounter++;
      }
    });
  }

  Future<void> _generateOffers() async {
    _offers = [];
    int offerCounter = 1;
    const int totalOffers = 120; // Generate more offers to ensure distribution
    
    // Calculate proportional offer distribution based on store count
    final totalStores = _stores.length;
    
    for (final retailer in _retailers) {
      final retailerStores = _stores.where((s) => s.chainId == retailer.id).toList();
      if (retailerStores.isEmpty) continue;
      
      // Calculate how many offers this retailer should get
      // Minimum 3 offers per retailer for test reliability
      final proportionalOffers = ((retailerStores.length / totalStores) * totalOffers).round();
      final offersForRetailer = proportionalOffers < 3 ? 3 : proportionalOffers;
      
      // Generate offers for this retailer
      for (int j = 0; j < offersForRetailer; j++) {
        final product = _products[_random.nextInt(_products.length)];
        final store = retailerStores[_random.nextInt(retailerStores.length)];
        
        final discountPercent = _random.nextInt(31) + 10; // 10-40% Rabatt
        final originalPrice = product.basePriceCents;
        final discountedPrice = (originalPrice * (100 - discountPercent) / 100).round();
        
        _offers.add(Offer(
          id: 'offer_${offerCounter.toString().padLeft(3, '0')}',
          retailer: retailer.name,
          productName: product.name,
          originalCategory: _getRetailerCategory(retailer.id, product.categoryName),
          price: discountedPrice / 100.0, // Convert to Euro
          originalPrice: originalPrice / 100.0,
          discountPercent: discountPercent.toDouble(),
          storeAddress: store.address,
          storeId: store.id,
          validUntil: DateTime.now().add(Duration(days: _random.nextInt(14) + 1)),
          storeLat: store.latitude,
          storeLng: store.longitude,
        ));
        offerCounter++;
      }
    }
    
    debugPrint('📊 Offer Distribution:');
    for (final retailer in _retailers) {
      final count = _offers.where((o) => o.retailer == retailer.name).length;
      if (count > 0) {
        debugPrint('   • ${retailer.name}: $count offers');
      }
    }
    
    // Notify offers provider
    _onOffersUpdated?.call();
  }

  Future<void> _generateFlashDeals() async {
    _flashDeals = [];
    final currentTime = DateTime.now();
    
    // Generate 15-20 initial flash deals
    final dealCount = _random.nextInt(6) + 15;
    
    for (int i = 0; i < dealCount; i++) {
      final product = _products[_random.nextInt(_products.length)];
      final beaconStores = _stores.where((s) => s.hasBeacon).toList();
      if (beaconStores.isEmpty) continue;
      
      final store = beaconStores[_random.nextInt(beaconStores.length)];
      final retailer = _retailers.firstWhere((r) => r.id == store.chainId);
      
      final discountPercent = _random.nextInt(41) + 30; // 30-70% Flash-Rabatt
      final originalPrice = product.basePriceCents;
      final flashPrice = (originalPrice * (1 - discountPercent / 100)).round();
      
      final durationHours = _random.nextInt(2) + 1; // FIX: 1-2 hours for test reliability
      final expiresAt = currentTime.add(Duration(hours: durationHours));
      final remainingHours = expiresAt.difference(currentTime).inHours;
      
      _flashDeals.add(FlashDeal(
        id: 'flash_${(i + 1).toString().padLeft(3, '0')}',
        productName: product.name,
        brand: product.brand,
        retailer: retailer.name,
        storeName: store.name,
        storeAddress: store.address,
        originalPriceCents: originalPrice,
        flashPriceCents: flashPrice,
        discountPercentage: discountPercent,
        expiresAt: expiresAt,
        remainingSeconds: expiresAt.difference(currentTime).inSeconds,
        urgencyLevel: remainingHours < 2 ? 'high' : remainingHours < 4 ? 'medium' : 'low',
        estimatedStock: _random.nextInt(50) + 5,
        shelfLocation: _generateShelfLocation(),
        storeLat: store.latitude,
        storeLng: store.longitude,
      ));
    }
  }

  // Flash Deal Updates (Timer-basiert)
  void _updateFlashDeals() {
    final now = DateTime.now();
    
    // Remove expired deals
    _flashDeals.removeWhere((deal) => deal.expiresAt.isBefore(now));
    
    // Add new deals if below minimum
    while (_flashDeals.length < 15) {
      final newDeal = _generateSingleFlashDeal(now);
      if (newDeal != null) _flashDeals.add(newDeal);
    }
    
    debugPrint('🔄 Flash Deals aktualisiert: ${_flashDeals.length} aktive Deals');
  }

  void _updateCountdownTimers() {
    final now = DateTime.now();
    bool hasChanges = false;
    
    for (int i = 0; i < _flashDeals.length; i++) {
      final deal = _flashDeals[i];
      final remainingSeconds = deal.expiresAt.difference(now).inSeconds;
      final remainingHours = remainingSeconds / 3600;
      
      // FIX: Remove deals with invalid timer values or expired deals
      if (remainingSeconds <= 0 || remainingSeconds > 3600) {
        // Deal expired or has invalid timer value
        _flashDeals.removeAt(i);
        i--;
        hasChanges = true;
      } else {
        // Update countdown and urgency
        final newUrgencyLevel = remainingHours < 1 ? 'high' : 
                               remainingHours < 3 ? 'medium' : 'low';
        
        _flashDeals[i] = deal.copyWith(
          remainingSeconds: remainingSeconds,
          urgencyLevel: newUrgencyLevel,
        );
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      debugPrint('⏱️ Countdown Timer aktualisiert: ${_flashDeals.length} aktive Deals');
    }
  }

  FlashDeal? _generateSingleFlashDeal(DateTime currentTime) {
    if (_products.isEmpty || _stores.isEmpty) return null;
    
    final beaconStores = _stores.where((s) => s.hasBeacon).toList();
    if (beaconStores.isEmpty) return null;
    
    final product = _products[_random.nextInt(_products.length)];
    final store = beaconStores[_random.nextInt(beaconStores.length)];
    final retailer = _retailers.firstWhere((r) => r.id == store.chainId);
    
    final discountPercent = _random.nextInt(41) + 30;
    final originalPrice = product.basePriceCents;
    final flashPrice = (originalPrice * (1 - discountPercent / 100)).round();
    
    // FIX: Generate shorter durations for test reliability
    final durationHours = _random.nextInt(3) + 1; // 1-3 hours instead of 1-6
    final expiresAt = currentTime.add(Duration(hours: durationHours));
    final remainingHours = expiresAt.difference(currentTime).inHours;
    
    return FlashDeal(
      id: 'flash_${DateTime.now().millisecondsSinceEpoch}',
      productName: product.name,
      brand: product.brand,
      retailer: retailer.name,
      storeName: store.name,
      storeAddress: store.address,
      originalPriceCents: originalPrice,
      flashPriceCents: flashPrice,
      discountPercentage: discountPercent,
      expiresAt: expiresAt,
      remainingSeconds: expiresAt.difference(currentTime).inSeconds,
      urgencyLevel: remainingHours < 2 ? 'high' : remainingHours < 4 ? 'medium' : 'low',
      estimatedStock: _random.nextInt(50) + 5,
      shelfLocation: _generateShelfLocation(),
      storeLat: store.latitude,
      storeLng: store.longitude,
    );
  }

  // Professor Demo Features
  FlashDeal generateInstantFlashDeal() {
    final now = DateTime.now();
    final deal = _generateSingleFlashDeal(now)!;
    
    // Add to active deals
    _flashDeals.add(deal);
    
    // Notify providers immediately
    _onFlashDealsUpdated?.call();
    
    debugPrint('🎓 Professor Demo: Instant Flash Deal generiert - ${deal.productName}');
    return deal;
  }
  
  // Test Helper: Manual timer update for test mode
  void updateTimersForTesting() {
    _updateCountdownTimers();
    _onFlashDealsUpdated?.call();
  }

  // Helper Methods
  String _getRetailerCategory(String retailerId, String flashFeedCategory) {
    // Use ProductCategoryMapping to get retailer-specific category
    final mappings = ProductCategoryMapping.categoryMappings[retailerId] ?? {};
    
    // Find the retailer category for this FlashFeed category
    for (final entry in mappings.entries) {
      if (entry.value == flashFeedCategory) {
        return entry.key; // Return retailer-specific category
      }
    }
    
    // Fallback to FlashFeed category
    return flashFeedCategory;
  }

  // Helper Methods für Store-Generierung
  Map<String, OpeningHours> _generateOpeningHours() {
    return {
      'Montag': OpeningHours.standard(7, 0, 21, 0),
      'Dienstag': OpeningHours.standard(7, 0, 21, 0),
      'Mittwoch': OpeningHours.standard(7, 0, 21, 0),
      'Donnerstag': OpeningHours.standard(7, 0, 21, 0),
      'Freitag': OpeningHours.standard(7, 0, 22, 0),
      'Samstag': OpeningHours.standard(7, 0, 21, 0),
      'Sonntag': OpeningHours.closed(),
    };
  }
  
  List<String> _generateStoreServices(String retailerName) {
    final commonServices = ['Parkplatz'];
    
    switch (retailerName.toLowerCase()) {
      case 'edeka':
        return [...commonServices, 'Lieferservice', 'Click & Collect'];
      case 'rewe':
        return [...commonServices, 'REWE Lieferservice', 'PayBack'];
      case 'aldi':
      case 'aldi süd':
        return [...commonServices, 'Pfandautomat'];
      case 'lidl':
        return [...commonServices, 'Lidl Plus App', 'Bäckerei'];
      case 'netto':
        return [...commonServices, 'DeutschlandCard'];
      case 'penny':
        return [...commonServices, 'Payback', 'DHL Paketstation'];
      case 'kaufland':
        return [...commonServices, 'Kaufland Card', 'Metzgerei', 'Bäckerei'];
      case 'real':
        return [...commonServices, 'Real Quality', 'SB-Warenhaus'];
      case 'globus':
        return [...commonServices, 'Metzgerei', 'Bäckerei', 'Restaurant'];
      case 'marktkauf':
        return [...commonServices, 'Frische-Theke'];
      default:
        return commonServices;
    }
  }

  ShelfLocation _generateShelfLocation() {
    final aisles = ['A', 'B', 'C', 'D', 'E', 'F'];
    final sides = ['links', 'rechts', 'mitte'];
    
    return ShelfLocation(
      aisle: '${aisles[_random.nextInt(aisles.length)]}${_random.nextInt(8) + 1}',
      shelf: sides[_random.nextInt(sides.length)],
      x: _random.nextInt(600) + 100,
      y: _random.nextInt(400) + 100,
    );
  }

  // Cleanup
  void dispose() {
    // Prevent double disposal
    if (!_isInitialized) return;
    
    // Cancel timers safely
    _flashDealTimer?.cancel();
    _flashDealTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    
    // Clear all callback references (FIX: prevent "used after disposed" errors)
    _onFlashDealsUpdated = null;
    _onOffersUpdated = null;
    _onStoresUpdated = null;
    
    // Mark as disposed
    _isInitialized = false;
    
    debugPrint('🧹 MockDataService: Timer gestoppt');
  }
}
