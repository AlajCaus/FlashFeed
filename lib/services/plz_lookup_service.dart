import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Ausnahme für PLZ-Lookup-Fehler
class PLZLookupException implements Exception {
  final String message;
  final String? originalError;
  
  const PLZLookupException(this.message, [this.originalError]);
  
  @override
  String toString() => 'PLZLookupException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Service für GPS-Koordinaten zu PLZ-Mapping
/// Verwendet OpenStreetMap Nominatim API für reverse geocoding
class PLZLookupService {
  static final PLZLookupService _instance = PLZLookupService._internal();
  factory PLZLookupService() => _instance;
  PLZLookupService._internal();

  // Cache für GPS → PLZ Lookups (in-memory)
  final Map<String, String> _plzCache = {};
  
  // Nominatim API base URL
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  // Rate limiting: max 1 request per second (Nominatim policy)
  DateTime? _lastRequest;
  static const Duration _rateLimitDelay = Duration(seconds: 1);

  /// Hauptmethode: GPS-Koordinaten zu PLZ
  /// 
  /// [latitude] GPS Breitengrad (z.B. 52.5200)
  /// [longitude] GPS Längengrad (z.B. 13.4050)
  /// 
  /// Returns: Deutsche Postleitzahl (z.B. "10115")
  /// Throws: [PLZLookupException] bei Fehlern
  Future<String> getPLZFromCoordinates(double latitude, double longitude) async {
    // Input-Validierung
    if (!_isValidCoordinate(latitude, longitude)) {
      throw const PLZLookupException('Ungültige GPS-Koordinaten');
    }
    
    // Cache-Check
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_plzCache.containsKey(cacheKey)) {
      return _plzCache[cacheKey]!;
    }
    
    try {
      // Rate limiting
      await _ensureRateLimit();
      
      // Nominatim API Call
      final plz = await _callNominatimAPI(latitude, longitude);
      
      // Cache speichern
      _plzCache[cacheKey] = plz;
      
      return plz;
    } catch (e) {
      throw PLZLookupException('PLZ-Lookup fehlgeschlagen', e.toString());
    }
  }

  /// Region für PLZ bestimmen (Integration mit PLZHelper)
  /// 
  /// [plz] Deutsche Postleitzahl (z.B. "10115")
  /// Returns: Region (z.B. "Berlin/Brandenburg")
  String? getRegionFromPLZ(String plz) {
    // Import PLZHelper für Region-Mapping
    // Diese Methode wird in Task 5b.5 mit PLZHelper integriert
    
    // Basis-Region-Mapping (wird erweitert)
    if (plz.startsWith('1')) return 'Berlin/Brandenburg';
    if (plz.startsWith('0') && plz != '00000') return 'Sachsen/Thüringen'; // 00000 ist ungültig
    if (plz.startsWith('2') || plz.startsWith('3')) return 'Niedersachsen/Schleswig-Holstein';
    if (plz.startsWith('4') || plz.startsWith('5')) return 'Nordrhein-Westfalen';
    if (plz.startsWith('6')) return 'Hessen/Rheinland-Pfalz';
    if (plz.startsWith('7')) return 'Baden-Württemberg';
    if (plz.startsWith('8') || plz.startsWith('9')) return 'Bayern';
    
    return null; // Unbekannte PLZ
  }

  /// Cache leeren (für Tests oder Memory-Management)
  void clearCache() {
    _plzCache.clear();
  }

  /// Cache-Statistiken für Debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'entries': _plzCache.length,
      'memoryUsage': '${_plzCache.length * 50}B (approx)', // ~50 Bytes pro Entry
    };
  }

  // PRIVATE METHODS

  /// GPS-Koordinaten Validierung
  bool _isValidCoordinate(double latitude, double longitude) {
    // Deutschland GPS-Grenzen (grob):
    // Lat: 47.3 (Süden) bis 55.1 (Norden)  
    // Lng: 5.9 (Westen) bis 15.0 (Osten)
    return latitude >= 47.0 && latitude <= 56.0 && 
           longitude >= 5.0 && longitude <= 16.0;
  }

  /// Rate-Limiting für Nominatim API (max 1 request/second)
  Future<void> _ensureRateLimit() async {
    if (_lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequest!);
      if (timeSinceLastRequest < _rateLimitDelay) {
        await Future.delayed(_rateLimitDelay - timeSinceLastRequest);
      }
    }
    _lastRequest = DateTime.now();
  }

  /// Nominatim API Call für reverse geocoding
  Future<String> _callNominatimAPI(double latitude, double longitude) async {
    final url = Uri.parse(
      '$_nominatimBaseUrl/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1'
      '&zoom=18'
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FlashFeed/1.0 (Prototype App)', // Required by Nominatim
      },
    );

    if (response.statusCode != 200) {
      throw PLZLookupException(
        'Nominatim API Fehler: ${response.statusCode}',
        response.body,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    
    // PLZ aus response extrahieren
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      throw const PLZLookupException('Keine Adress-Information gefunden');
    }

    // Verschiedene PLZ-Felder probieren (Nominatim kann variieren)
    final plz = address['postcode'] as String? ??
               address['postal_code'] as String? ??
               address['zipcode'] as String?;

    if (plz == null || plz.isEmpty) {
      throw const PLZLookupException('Keine PLZ in Nominatim-Response gefunden');
    }

    // Deutsche PLZ validieren (5 Ziffern)
    if (!RegExp(r'^\d{5}$').hasMatch(plz)) {
      throw PLZLookupException('Ungültige PLZ-Format: $plz');
    }

    return plz;
  }
}
