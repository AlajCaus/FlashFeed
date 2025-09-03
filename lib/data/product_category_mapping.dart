// FlashFeed Produktgruppen-Mapping System
// Hier trägst du die LEH-Kategorien ein und ordnest sie unseren Produktgruppen zu

class ProductCategoryMapping {
  // Unsere einheitlichen FlashFeed Produktgruppen
  static const List<String> flashFeedCategories = [
    'Obst & Gemüse',
    'Milchprodukte', 
    'Fleisch & Wurst',
    'Brot & Backwaren',
    'Getränke',
    'Tiefkühl',
    'Konserven',
    'Süßwaren',
    'Drogerie',
    'Haushalt'
  ];

  // Mapping: [Händler][Original-Kategorie] -> FlashFeed Kategorie
  static const Map<String, Map<String, String>> categoryMappings = {
    
    'EDEKA': {
      // Hier trägst du ein: 'EDEKA Kategorie' -> 'FlashFeed Kategorie'
      'Molkereiprodukte': 'Milchprodukte',
      'Frischfleisch': 'Fleisch & Wurst',
      'Obst': 'Obst & Gemüse',
      'Gemüse': 'Obst & Gemüse',
      // TODO: Weitere EDEKA Kategorien nach deiner Analyse hinzufügen
    },
    
    'REWE': {
      'Milch & Käse': 'Milchprodukte', 
      'Fleisch & Geflügel': 'Fleisch & Wurst',
      'Frisches Obst': 'Obst & Gemüse',
      'Frisches Gemüse': 'Obst & Gemüse',
      // TODO: Weitere REWE Kategorien nach deiner Analyse hinzufügen
    },
    
    'ALDI': {
      'Milcherzeugnisse': 'Milchprodukte',
      'Frischfleisch': 'Fleisch & Wurst',
      // TODO: ALDI Kategorien nach deiner Analyse hinzufügen
    },
    
    'Netto Marken-Discount': {
      // TODO: Netto Marken-Discount Kategorien hier eintragen nach deiner Analyse
    },
    
    'Lidl': {
      // TODO: Lidl Kategorien hier eintragen nach deiner Analyse
    },
    
    'Penny': {
      // TODO: Penny Kategorien hier eintragen nach deiner Analyse
    },
    
    'Kaufland': {
      // TODO: Kaufland Kategorien hier eintragen nach deiner Analyse
    },
    
    'Real': {
      // TODO: Real Kategorien hier eintragen nach deiner Analyse
    },
    
    'Globus': {
      // TODO: Globus Kategorien hier eintragen nach deiner Analyse
    },
    
    'Marktkauf': {
      // TODO: Marktkauf Kategorien hier eintragen nach deiner Analyse
    }
  };

  // Hilfsfunktion: Händler-Kategorie zu FlashFeed-Kategorie
  static String mapToFlashFeedCategory(String retailer, String originalCategory) {
    return categoryMappings[retailer]?[originalCategory] ?? 'Sonstiges';
  }

  // Alle verfügbaren Händler
  static List<String> get availableRetailers => categoryMappings.keys.toList();
  
  // Alle Kategorien eines bestimmten Händlers
  static List<String> getRetailerCategories(String retailer) {
    return categoryMappings[retailer]?.keys.toList() ?? [];
  }
  
  // Prüfen ob Händler-Kategorie existiert
  static bool hasCategory(String retailer, String category) {
    return categoryMappings[retailer]?.containsKey(category) ?? false;
  }
}

// Mock-Datenklasse für Echtzeit-Rabatte
class FlashDeal {
  final String id;
  final String retailer;
  final String productName;
  final String originalCategory;
  final double originalPrice;
  final double discountPercent;
  final DateTime validUntil;
  final String storeAddress;
  final String storeId;

  FlashDeal({
    required this.id,
    required this.retailer,
    required this.productName, 
    required this.originalCategory,
    required this.originalPrice,
    required this.discountPercent,
    required this.validUntil,
    required this.storeAddress,
    required this.storeId,
  });

  // Berechnet den reduzierten Preis
  double get discountedPrice => originalPrice * (1 - discountPercent / 100);
  
  // Ersparnis in Euro
  double get savings => originalPrice - discountedPrice;
  
  // Verbleibende Zeit in Minuten
  int get remainingMinutes => validUntil.difference(DateTime.now()).inMinutes;
  
  // Zugeordnete FlashFeed Kategorie
  String get flashFeedCategory => 
      ProductCategoryMapping.mapToFlashFeedCategory(retailer, originalCategory);
}

// Simulator für Echtzeit-Rabatte (für Professor-Demo)
class FlashDealSimulator {
  static List<FlashDeal> generateRandomDeals() {
    final random = DateTime.now().millisecondsSinceEpoch;
    
    return [
      FlashDeal(
        id: 'deal_$random',
        retailer: 'EDEKA',
        productName: 'Frische Milch 1L',
        originalCategory: 'Molkereiprodukte',
        originalPrice: 1.29,
        discountPercent: 25.0,
        validUntil: DateTime.now().add(Duration(minutes: 45)),
        storeAddress: 'EDEKA Neukauf, Musterstr. 15, Berlin',
        storeId: 'edeka_berlin_01'
      ),
      FlashDeal(
        id: 'deal_${random + 1}',
        retailer: 'REWE', 
        productName: 'Bio Bananen 1kg',
        originalCategory: 'Frisches Obst',
        originalPrice: 2.99,
        discountPercent: 30.0,
        validUntil: DateTime.now().add(Duration(minutes: 25)),
        storeAddress: 'REWE City, Beispielweg 42, Berlin', 
        storeId: 'rewe_berlin_05'
      ),
      // Weitere Mock-Deals können hier hinzugefügt werden
    ];
  }
  
  // Professor-Demo: Sofortige Rabatt-Generierung
  static FlashDeal generateInstantDemoDeal() {
    final now = DateTime.now();
    return FlashDeal(
      id: 'demo_${now.millisecondsSinceEpoch}',
      retailer: 'ALDI',
      productName: 'Schweineschnitzel 500g',
      originalCategory: 'Frischfleisch', 
      originalPrice: 4.99,
      discountPercent: 40.0,
      validUntil: now.add(Duration(minutes: 15)), // Kurze Demo-Zeit
      storeAddress: 'ALDI SÜD, Professorweg 1, Berlin',
      storeId: 'aldi_berlin_demo'
    );
  }
}
