import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/product_category_mapping.dart';

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
  List<Chain> _chains = [];
  List<Store> _stores = [];
  List<Product> _products = [];
  List<Offer> _offers = [];
  List<FlashDeal> _flashDeals = [];
  
  bool _isInitialized = false;
  
  // Getters für generierte Daten
  List<Chain> get chains => List.unmodifiable(_chains);
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
      await _generateChains();
      await _generateStores();
      await _generateProducts();
      await _generateOffers();
      await _generateFlashDeals();
      
      _isInitialized = true;
      
      // Start periodic updates for real-time simulation
      _startPeriodicUpdates();
      
      debugPrint('✅ MockDataService: Initialisierung abgeschlossen');
      debugPrint('   • ${_chains.length} Chains generiert');
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
    _flashDealTimer = Timer.periodic(Duration(hours: 2), (timer) {
      _updateFlashDeals();
      _onFlashDealsUpdated?.call(); // Direkte Provider-Benachrichtigung
    });
    
    // Countdown Updates: alle 60 Sekunden Timer aktualisieren
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateCountdownTimers();
      _onFlashDealsUpdated?.call(); // Provider-Update für Timer
    });
    
    debugPrint('⏰ MockDataService: Timer gestartet (Flash Deals: 2h, Countdown: 1min)');
  }

  // Mock Data Generation basierend auf Datenbank-Schema
  Future<void> _generateChains() async {
    _chains = [
      Chain(
        id: 'edeka',
        name: 'EDEKA',
        displayName: 'EDEKA',
        logoUrl: 'assets/images/logos/edeka.png',
        primaryColor: '#005CA9', // aus Datenbank-Schema
        website: 'https://www.edeka.de',
        isActive: true,
        storeCount: 7,
      ),
      Chain(
        id: 'rewe',
        name: 'REWE',
        displayName: 'REWE',
        logoUrl: 'assets/images/logos/rewe.png',
        primaryColor: '#CC071E',
        website: 'https://www.rewe.de',
        isActive: true,
        storeCount: 7,
      ),
      Chain(
        id: 'aldi',
        name: 'ALDI SÜD',
        displayName: 'ALDI',
        logoUrl: 'assets/images/logos/aldi.png',
        primaryColor: '#00549F',
        website: 'https://www.aldi-sued.de',
        isActive: true,
        storeCount: 7,
      ),
      Chain(
        id: 'lidl',
        name: 'LIDL',
        displayName: 'LIDL',
        logoUrl: 'assets/images/logos/lidl.png',
        primaryColor: '#0050AA',
        website: 'https://www.lidl.de',
        isActive: true,
        storeCount: 7,
      ),
      Chain(
        id: 'netto_schwarz',
        name: 'NETTO',
        displayName: 'Netto',
        logoUrl: 'assets/images/logos/netto-schwarz.png',
        primaryColor: '#FFD100',
        website: 'https://www.netto-online.de',
        isActive: true,
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
    
    for (final chain in _chains) {
      for (int i = 0; i < chain.storeCount; i++) {
        // 60% Berlin, 40% München (realistische Verteilung)
        final isBerl in = _random.nextDouble() < 0.6;
        final coordinates = isBerl in ? berlinCoordinates : munichCoordinates;
        final location = coordinates[_random.nextInt(coordinates.length)];
        final template = storeTemplates[i % storeTemplates.length];
        
        _stores.add(Store(
          id: 'store_${storeCounter.toString().padLeft(3, '0')}',
          chainId: chain.id,
          name: '${chain.displayName} $template',
          street: '$template ${_random.nextInt(200) + 1}',
          zipCode: isBerl in 
              ? '${10000 + _random.nextInt(5000)}' // Berlin PLZ 10000-14999
              : '${80000 + _random.nextInt(6000)}', // München PLZ 80000-85999
          city: isBerl in ? 'Berlin' : 'München',
          latitude: location['lat'] as double + (_random.nextDouble() - 0.5) * 0.02,
          longitude: location['lng'] as double + (_random.nextDouble() - 0.5) * 0.02,
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
      final chain = _chains.firstWhere((c) => c.id == store.chainId);
      
      final discountPercent = _random.nextInt(31) + 10; // 10-40% Rabatt
      final originalPrice = product.basePriceCents;
      final discountedPrice = (originalPrice * (1 - discountPercent / 100)).round();
      
      _offers.add(Offer(
        id: 'offer_${offerCounter.toString().padLeft(3, '0')}',
        retailer: chain.name,
        productName: product.name,
        originalCategory: _getChainCategory(chain.id, product.categoryName),
        price: discountedPrice / 100.0, // Convert to Euro
        originalPrice: originalPrice / 100.0,
        discountPercent: discountPercent.toDouble(),
        storeAddress: '${store.street}, ${store.zipCode} ${store.city}',
        storeId: store.id,
        validUntil: DateTime.now().add(Duration(days: _random.nextInt(14) + 1)),
        storeLat: store.latitude,
        storeLng: store.longitude,
      ));
      offerCounter++;
    }
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
      final chain = _chains.firstWhere((c) => c.id == store.chainId);
      
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
        retailer: chain.name,
        storeName: store.name,
        storeAddress: '${store.street}, ${store.zipCode} ${store.city}',
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
    final chain = _chains.firstWhere((c) => c.id == store.chainId);
    
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
      retailer: chain.name,
      storeName: store.name,
      storeAddress: '${store.street}, ${store.zipCode} ${store.city}',
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
  String _getChainCategory(String chainId, String flashFeedCategory) {
    // Use ProductCategoryMapping to get chain-specific category
    final mappings = ProductCategoryMapping.categoryMappings[chainId] ?? {};
    
    // Find the chain category for this FlashFeed category
    for (final entry in mappings.entries) {
      if (entry.value == flashFeedCategory) {
        return entry.key; // Return chain-specific category
      }
    }
    
    // Fallback to FlashFeed category
    return flashFeedCategory;
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

// Model Classes (basierend auf Datenbank-Schema)

class Chain {
  final String id;
  final String name;
  final String displayName;
  final String logoUrl;
  final String primaryColor;
  final String website;
  final bool isActive;
  final int storeCount;

  Chain({
    required this.id,
    required this.name,
    required this.displayName,
    required this.logoUrl,
    required this.primaryColor,
    required this.website,
    required this.isActive,
    required this.storeCount,
  });
}

class Store {
  final String id;
  final String chainId;
  final String name;
  final String street;
  final String zipCode;
  final String city;
  final double latitude;
  final double longitude;
  final bool hasBeacon;
  final bool isActive;

  Store({
    required this.id,
    required this.chainId,
    required this.name,
    required this.street,
    required this.zipCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.hasBeacon,
    required this.isActive,
  });
}

class Product {
  final String id;
  final String categoryName;
  final String name;
  final String brand;
  final int basePriceCents;
  final bool isActive;

  Product({
    required this.id,
    required this.categoryName,
    required this.name,
    required this.brand,
    required this.basePriceCents,
    required this.isActive,
  });
}

class Offer {
  final String id;
  final String retailer;
  final String productName;
  final String originalCategory;
  final double price;
  final double? originalPrice;
  final double? discountPercent;
  final String storeAddress;
  final String storeId;
  final DateTime validUntil;
  final double storeLat;
  final double storeLng;

  Offer({
    required this.id,
    required this.retailer,
    required this.productName,
    required this.originalCategory,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.storeAddress,
    required this.storeId,
    required this.validUntil,
    required this.storeLat,
    required this.storeLng,
  });

  bool get hasDiscount => originalPrice != null && discountPercent != null;
  double get savings => hasDiscount ? (originalPrice! - price) : 0.0;
  bool get isValid => DateTime.now().isBefore(validUntil);
  
  String get flashFeedCategory {
    return ProductCategoryMapping.mapToFlashFeedCategory(retailer, originalCategory);
  }
}

class FlashDeal {
  final String id;
  final String productName;
  final String brand;
  final String retailer;
  final String storeName;
  final String storeAddress;
  final int originalPriceCents;
  final int flashPriceCents;
  final int discountPercentage;
  final DateTime expiresAt;
  final int remainingSeconds;
  final String urgencyLevel; // 'low', 'medium', 'high'
  final int estimatedStock;
  final ShelfLocation shelfLocation;
  final double storeLat;
  final double storeLng;

  FlashDeal({
    required this.id,
    required this.productName,
    required this.brand,
    required this.retailer,
    required this.storeName,
    required this.storeAddress,
    required this.originalPriceCents,
    required this.flashPriceCents,
    required this.discountPercentage,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.urgencyLevel,
    required this.estimatedStock,
    required this.shelfLocation,
    required this.storeLat,
    required this.storeLng,
  });

  double get originalPrice => originalPriceCents / 100.0;
  double get flashPrice => flashPriceCents / 100.0;
  double get savings => originalPrice - flashPrice;
  int get remainingMinutes => (remainingSeconds / 60).ceil();
  bool get isExpired => remainingSeconds <= 0;

  FlashDeal copyWith({
    String? id,
    String? productName,
    String? brand,
    String? retailer,
    String? storeName,
    String? storeAddress,
    int? originalPriceCents,
    int? flashPriceCents,
    int? discountPercentage,
    DateTime? expiresAt,
    int? remainingSeconds,
    String? urgencyLevel,
    int? estimatedStock,
    ShelfLocation? shelfLocation,
    double? storeLat,
    double? storeLng,
  }) {
    return FlashDeal(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      retailer: retailer ?? this.retailer,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      originalPriceCents: originalPriceCents ?? this.originalPriceCents,
      flashPriceCents: flashPriceCents ?? this.flashPriceCents,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      estimatedStock: estimatedStock ?? this.estimatedStock,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      storeLat: storeLat ?? this.storeLat,
      storeLng: storeLng ?? this.storeLng,
    );
  }
}

class ShelfLocation {
  final String aisle;
  final String shelf;
  final int x;
  final int y;

  ShelfLocation({
    required this.aisle,
    required this.shelf,
    required this.x,
    required this.y,
  });
}
