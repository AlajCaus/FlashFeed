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
  final Random _random = Random();
  
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

  // Initialization (aufgerufen von main.dart)
  Future<void> initializeMockData() async {
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
      
      // Start periodic updates for real-time simulation
      _startPeriodicUpdates();
      
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
      ),
    ];
  }

  Future<void> _generateStores() async {
    final berlinCoordinates = [
      {'name': 'Berlin Mitte', 'lat': 52.5200, 'lng': 13.4050},
      {'name': 'Berlin Prenzlauer Berg', 'lat': 52.5482, 'lng': 13.4193},
      {'name': 'Berlin Kreuzberg', 'lat': 52.4987, 'lng': 13.4180},
      {'name': 'Berlin Charlottenburg', 'lat': 52.5048, 'lng': 13.2977},
      {'name': 'Berlin Friedrichshain', 'lat': 52.5147, 'lng': 13.4545},
    ];
    
    final munichCoordinates = [
      {'name': 'München Zentrum', 'lat': 48.1374, 'lng': 11.5755},
      {'name': 'München Schwabing', 'lat': 48.1642, 'lng': 11.5816},
    ];
    
    final storeTemplates = [
      'Hauptstraße',
      'Bahnhofstraße',
      'Marktplatz',
      'Zentrum',
      'Nordstadt',
      'Altstadt',
      'City'
    ];
    
    _stores = [];
    int storeCounter = 1;
    
    for (final retailer in _retailers) {
      for (int i = 0; i < retailer.storeCount; i++) {
        // 60% Berlin, 40% München (realistische Verteilung)
        final isBerlin = _random.nextDouble() < 0.6;
        final coordinates = isBerlin ? berlinCoordinates : munichCoordinates;
        final location = coordinates[_random.nextInt(coordinates.length)];
        final template = storeTemplates[i % storeTemplates.length];
        
        _stores.add(Store(
          id: 'store_${storeCounter.toString().padLeft(3, '0')}',
          chainId: retailer.id,
          retailerName: retailer.name,
          name: '${retailer.displayName} $template',
          street: '$template ${_random.nextInt(200) + 1}',
          zipCode: isBerlin 
              ? '${10000 + _random.nextInt(5000)}' // Berlin PLZ 10000-14999
              : '${80000 + _random.nextInt(6000)}', // München PLZ 80000-85999
          city: isBerlin ? 'Berlin' : 'München',
          latitude: (location['lat'] as double) + (_random.nextDouble() - 0.5) * 0.02,
          longitude: (location['lng'] as double) + (_random.nextDouble() - 0.5) * 0.02,
          phoneNumber: '+49 30 ${_random.nextInt(90000000) + 10000000}',
          openingHours: _generateOpeningHours(),
          services: _generateStoreServices(retailer.name),
          hasWifi: _random.nextBool(),
          hasPharmacy: false,
          hasBeacon: _random.nextBool(), // 50% haben Beacon für Indoor-Navigation
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
        {'name': 'Tomaten 500g', 'brand': 'Bioland', 'price': 199},
        {'name': 'Gurken 1 Stück', 'brand': 'Regional', 'price': 89},
        {'name': 'Kartoffeln 2.5kg', 'brand': 'Linda', 'price': 299},
      ],
      'Milchprodukte': [
        {'name': 'Vollmilch 1L', 'brand': 'Landliebe', 'price': 129},
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
    
    // Generate 100 regular offers (Prospekt-Angebote)
    for (int i = 0; i < 100; i++) {
      final product = _products[_random.nextInt(_products.length)];
      final store = _stores[_random.nextInt(_stores.length)];
      final retailer = _retailers.firstWhere((r) => r.id == store.chainId);
      
      final discountPercent = _random.nextInt(31) + 10; // 10-40% Rabatt
      final originalPrice = product.basePriceCents;
      final discountedPrice = (originalPrice * (1 - discountPercent / 100)).round();
      
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
      
      final durationHours = _random.nextInt(6) + 1; // 1-6 Stunden
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
      
      if (remainingSeconds <= 0) {
        // Deal expired
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
    
    final durationHours = _random.nextInt(6) + 1;
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
    _flashDealTimer?.cancel();
    _countdownTimer?.cancel();
    debugPrint('🧹 MockDataService: Timer gestoppt');
  }
}
