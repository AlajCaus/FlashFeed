// FlashFeed Produktgruppen-Mapping System
// Vollständiges Mapping aller deutschen LEH-Kategorien zu FlashFeed Produktgruppen

class ProductCategoryMapping {
  // Unsere einheitlichen FlashFeed Produktgruppen (erweitert)
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
    'Haushalt',
    'Bio-Produkte',
    'Fertiggerichte'
  ];

  // Vollständiges Mapping: [Händler][Original-Kategorie] -> FlashFeed Kategorie
  static const Map<String, Map<String, String>> categoryMappings = {
    
    'EDEKA': {
      // EDEKA Kategorien - Premium-Vollsortimenter
      'Molkereiprodukte': 'Milchprodukte',
      'Frischfleisch': 'Fleisch & Wurst',
      'Obst': 'Obst & Gemüse',
      'Gemüse': 'Obst & Gemüse',
      'Obst & Gemüse': 'Obst & Gemüse',  // FIX: Add mapping for combined category
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühlprodukte': 'Tiefkühl',
      'Konserven & Dauerware': 'Konserven',
      'Süßwaren & Knabbereien': 'Süßwaren',
      'Drogerie & Körperpflege': 'Drogerie',
      'Haushalt & Reinigung': 'Haushalt',
      'Bio-Sortiment': 'Bio-Produkte',
      'Fertigprodukte': 'Fertiggerichte',
      'Wurst & Aufschnitt': 'Fleisch & Wurst',
      'Käse & Feinkost': 'Milchprodukte',
      'Milchprodukte': 'Milchprodukte',  // Für Tests: direkte Milchprodukte
    },
    
    'REWE': {
      // REWE Kategorien - Nachhaltiger Vollsortimenter
      'Milch & Käse': 'Milchprodukte', 
      'Fleisch & Geflügel': 'Fleisch & Wurst',
      'Frisches Obst': 'Obst & Gemüse',
      'Frisches Gemüse': 'Obst & Gemüse',
      'Obst & Gemüse': 'Obst & Gemüse',  // FIX: Add mapping for combined category
      'Brot & Bäckerei': 'Brot & Backwaren',
      'Getränke & Alkohol': 'Getränke',
      'Tiefgekühltes': 'Tiefkühl',
      'Haltbare Lebensmittel': 'Konserven',
      'Naschwerk & Snacks': 'Süßwaren',
      'Drogerie': 'Drogerie',
      'Haushaltswaren': 'Haushalt',
      'REWE Bio': 'Bio-Produkte',
      'Convenience': 'Fertiggerichte',
      'Wurstwaren': 'Fleisch & Wurst',
      'Molkerei & Eier': 'Milchprodukte',
      'Milchprodukte': 'Milchprodukte',  // Für Tests: direkte Milchprodukte
    },
    
    'ALDI': {
      // ALDI SÜD Kategorien - Discounter-Sortiment
      'Milcherzeugnisse': 'Milchprodukte',
      'Frischfleisch': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühl': 'Tiefkühl',
      'Konserven': 'Konserven',
      'Süßigkeiten': 'Süßwaren',
      'Non-Food': 'Haushalt',
      'Wurst & Käse': 'Fleisch & Wurst',
      'Simply V': 'Bio-Produkte',
      'Ready Meals': 'Fertiggerichte',
      'Obst': 'Obst & Gemüse',  // Für Tests: einzelnes 'Obst' auch unterstützen
    },
    
    'ALDI SÜD': {
      // ALDI SÜD Kategorien - Discounter-Sortiment (gleiche wie ALDI)
      'Milcherzeugnisse': 'Milchprodukte',
      'Frischfleisch': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Obst': 'Obst & Gemüse',  // Für Tests: einzelnes 'Obst' auch unterstützen
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühl': 'Tiefkühl',
      'Konserven': 'Konserven',
      'Süßigkeiten': 'Süßwaren',
      'Non-Food': 'Haushalt',
      'Wurst & Käse': 'Fleisch & Wurst',
      'Simply V': 'Bio-Produkte',
      'Ready Meals': 'Fertiggerichte',
    },
    
    'NETTO': {
      // NETTO (alternative Schreibweise)
      'Getränke': 'Getränke',
      'Konserven': 'Konserven',
      'Molkereiprodukte': 'Milchprodukte',
      'Fleisch & Wurst': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Obst': 'Obst & Gemüse',  // Für Tests
      'Backshop': 'Brot & Backwaren',
      'Tiefkühlkost': 'Tiefkühl',
      'Süßwaren': 'Süßwaren',
      'Drogerieartikel': 'Drogerie',
      'Haushaltsartikel': 'Haushalt',
      'BioBio': 'Bio-Produkte',
      'Fertiggerichte': 'Fertiggerichte',
    },
    
    'netto scottie': {
      // Netto Marken-Discount Kategorien - Discounter mit Marken
      'Getränke': 'Getränke',
      'Konserven': 'Konserven',
      'Molkereiprodukte': 'Milchprodukte',
      'Fleisch & Wurst': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Backshop': 'Brot & Backwaren',
      'Tiefkühlkost': 'Tiefkühl',
      'Süßwaren': 'Süßwaren',
      'Drogerieartikel': 'Drogerie',
      'Haushaltsartikel': 'Haushalt',
      'BioBio': 'Bio-Produkte',
      'Fertiggerichte': 'Fertiggerichte',
    },
    
    'LIDL': {
      // LIDL Kategorien - Internationaler Discounter (Alternative Schreibweise)
      'Backwaren': 'Brot & Backwaren',
      'Milchprodukte': 'Milchprodukte',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Fleisch & Geflügel': 'Fleisch & Wurst',
      'Getränke': 'Getränke',
      'Tiefkühlprodukte': 'Tiefkühl',
      'Konserven': 'Konserven',
      'Süßwaren': 'Süßwaren',
      'Haushalt': 'Haushalt',
      'Natür': 'Bio-Produkte',
      'Sofort genießen': 'Fertiggerichte',
    },
    
    'Lidl': {
      // Lidl Kategorien - Internationaler Discounter
      'Backwaren': 'Brot & Backwaren',
      'Milchprodukte': 'Milchprodukte',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Fleisch & Geflügel': 'Fleisch & Wurst',
      'Getränke': 'Getränke',
      'Tiefkühl': 'Tiefkühl',
      'Haltbare Lebensmittel': 'Konserven',
      'Süßes & Salziges': 'Süßwaren',
      'Drogerie & Kosmetik': 'Drogerie',
      'Haushalt & Garten': 'Haushalt',
      'Bio Organic': 'Bio-Produkte',
      'Convenience Food': 'Fertiggerichte',
      'Wurst & Käse': 'Fleisch & Wurst',
    },
    
    'Penny': {
      // Penny Kategorien - REWE-Discounter
      'Molkerei': 'Milchprodukte',
      'Fleisch': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Bäckerei': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefgekühltes': 'Tiefkühl',
      'Konserven & Haltbares': 'Konserven',
      'Süßwaren & Snacks': 'Süßwaren',
      'Drogerie & Pflege': 'Drogerie',
      'Haushaltswaren': 'Haushalt',
      'PENNY Ready': 'Fertiggerichte',
    },
    
    'Kaufland': {
      // Kaufland Kategorien - Schwarz-Gruppe Hypermarkt
      'Milch & Molkerei': 'Milchprodukte',
      'Fleisch & Wurst': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühl': 'Tiefkühl',
      'Konserven': 'Konserven',
      'Süßwaren': 'Süßwaren',
      'Drogerie': 'Drogerie',
      'Haushalt': 'Haushalt',
      'K-Bio': 'Bio-Produkte',
      'K-free': 'Bio-Produkte',
      'To Go': 'Fertiggerichte',
    },
    
    'nahkauf': {
      // nahkauf Kategorien - SB-Warenhaus (historisch, größtenteils geschlossen)
      'Molkereiprodukte': 'Milchprodukte',
      'Fleisch & Geflügel': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Bäckerei': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühlprodukte': 'Tiefkühl',
      'Konserven': 'Konserven',
      'Süßwaren': 'Süßwaren',
      'Drogerie': 'Drogerie',
      'Haushaltswaren': 'Haushalt',
      'tip': 'Bio-Produkte',
      'Real Quality': 'Fertiggerichte',
    },
    
    'Globus': {
      // Globus Kategorien - SB-Warenhaus Saar/Südwest
      'Molkerei & Eier': 'Milchprodukte',
      'Fleisch & Wurst': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Bäckerei': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühl': 'Tiefkühl',
      'Konserven & Vorräte': 'Konserven',
      'Süßes & Salziges': 'Süßwaren',
      'Drogerie & Kosmetik': 'Drogerie',
      'Haus & Garten': 'Haushalt',
      'Bio': 'Bio-Produkte',
      'Frische Küche': 'Fertiggerichte',
    },
    
    'norma': {
      // norma Kategorien - EDEKA-Hypermarkt
      'Molkereiprodukte': 'Milchprodukte',
      'Fleischwaren': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühlkost': 'Tiefkühl',
      'Konserven & Dauerware': 'Konserven',
      'Süßwaren & Knabberartikel': 'Süßwaren',
      'Drogerie & Gesundheit': 'Drogerie',
      'Haushalt & Wohnen': 'Haushalt',
      'Bio-Sortiment': 'Bio-Produkte',
      'Convenience': 'Fertiggerichte',
    },

    'BIOCOMPANY': {
      // biocompany Kategorien - Bio-Hypermarkt
      'Molkereiprodukte': 'Milchprodukte',
      'Fleischwaren': 'Fleisch & Wurst',
      'Obst & Gemüse': 'Obst & Gemüse',
      'Backwaren': 'Brot & Backwaren',
      'Getränke': 'Getränke',
      'Tiefkühlkost': 'Tiefkühl',
      'Konserven & Dauerware': 'Konserven',
      'Süßwaren & Knabberartikel': 'Süßwaren',
      'Drogerie & Gesundheit': 'Drogerie',
      'Haushalt & Wohnen': 'Haushalt',
      'Bio-Sortiment': 'Bio-Produkte',
      'Convenience': 'Fertiggerichte',
    },
  };

  // Hilfsfunktion: Händler-Kategorie zu FlashFeed-Kategorie
  static String mapToFlashFeedCategory(String retailer, String originalCategory) {
    // Direkte Übereinstimmung prüfen
    final directMapping = categoryMappings[retailer]?[originalCategory];
    if (directMapping != null) {
      return directMapping;
    }
    
    // Fallback: Normalisierte Retailer-Namen versuchen
    // Z.B. 'ALDI SÜD' → 'ALDI', 'NETTO' statt 'Netto Marken-Discount'
    if (retailer.contains('ALDI')) {
      return categoryMappings['ALDI']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('NETTO')) {
      return categoryMappings['Netto Marken-Discount']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('PENNY')) {
      return categoryMappings['Penny']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('KAUFLAND')) {
      return categoryMappings['Kaufland']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('nahkauf')) {
      return categoryMappings['nahkauf']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('GLOBUS')) {
      return categoryMappings['Globus']?[originalCategory] ?? 'Sonstiges';
    }
    if (retailer.toUpperCase().contains('norma')) {
      return categoryMappings['norma']?[originalCategory] ?? 'Sonstiges';
    }
    
    return 'Sonstiges';
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
