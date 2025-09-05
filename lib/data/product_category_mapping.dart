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

// FlashDeal und FlashDealSimulator wurden nach lib/models/models.dart verschoben
// Import: import '../models/models.dart';
