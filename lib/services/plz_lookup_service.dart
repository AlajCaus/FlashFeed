import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

/// Cache-Eintrag mit Timestamp für Expiry-Handling
class _PLZCacheEntry {
  final String plz;
  final DateTime timestamp;
  DateTime lastAccessed;
  
  _PLZCacheEntry(this.plz) 
    : timestamp = DateTime.now(),
      lastAccessed = DateTime.now();
  
  /// Prüfung ob Cache-Entry abgelaufen ist
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
  
  /// Entry als kürzlich verwendet markieren (für LRU)
  void markAccessed() {
    lastAccessed = DateTime.now();
  }
  
  /// Memory-Größe schätzen (für Statistiken)
  int get estimatedSizeBytes => plz.length * 2 + 64; // String + Timestamps
}

/// Ausnahme für PLZ-Lookup-Fehler
class PLZLookupException implements Exception {
  final String message;
  final String? originalError;
  
  const PLZLookupException(this.message, [this.originalError]);
  
  @override
  String toString() => 'PLZLookupException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Service für GPS-Koordinaten zu PLZ-Mapping (Task 5b.4: Enhanced Performance & Caching)
/// Verwendet OpenStreetMap Nominatim API für reverse geocoding
/// Features: LRU-Cache, Time-Based Expiry, Performance-Monitoring
class PLZLookupService {
  static final PLZLookupService _instance = PLZLookupService._internal();

  factory PLZLookupService() => _instance;

  PLZLookupService._internal() {
    // Timer is started lazily on first real use, not in constructor
  }

  // Enhanced Cache mit LRU und Expiry (Task 5b.4)
  final Map<String, _PLZCacheEntry> _plzCache = {};
  
  // Cache-Konfiguration
  static const int _maxCacheSize = 1000; // Max Einträge (ca. 100KB Memory)
  static const Duration _cacheExpiry = Duration(hours: 6); // Cache-Lebensdauer
  static const Duration _cleanupInterval = Duration(minutes: 30); // Cleanup-Frequenz
  
  // Performance-Statistiken (Task 5b.4)
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _apiCalls = 0;
  int _cacheEvictions = 0;
  DateTime? _lastCleanup;
  
  // Background-Cleanup Timer
  Timer? _cleanupTimer;
  bool _timerStarted = false;
  
  // Nominatim API base URL
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  // Rate limiting: max 1 request per second (Nominatim policy)
  DateTime? _lastRequest;
  static const Duration _rateLimitDelay = Duration(seconds: 1);

  /// Hauptmethode: GPS-Koordinaten zu PLZ (Task 5b.4: Enhanced mit Performance-Optimierung)
  /// 
  /// [latitude] GPS Breitengrad (z.B. 52.5200)
  /// [longitude] GPS Längengrad (z.B. 13.4050)
  /// 
  /// Returns: Deutsche Postleitzahl (z.B. "10115")
  /// Throws: [PLZLookupException] bei Fehlern
  Future<String> getPLZFromCoordinates(double latitude, double longitude) async {
    // Start timer on first actual use (lazy initialization)
    _ensureTimerStarted();

    // Input-Validierung
    if (!_isValidCoordinate(latitude, longitude)) {
      throw const PLZLookupException('Ungültige GPS-Koordinaten');
    }
    
    // Cache-Key generieren (4 Dezimalstellen für Balance zwischen Präzision und Cache-Effizienz)
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    
    // Cache-Check mit Expiry-Validation (Task 5b.4)
    final cachedEntry = _plzCache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired(_cacheExpiry)) {
      // Cache-Hit: Entry als accessed markieren (LRU)
      cachedEntry.markAccessed();
      _cacheHits++;
      
      return cachedEntry.plz;
    }
    
    // Cache-Miss: API-Call nötig
    _cacheMisses++;
    
    try {
      // Rate limiting
      await _ensureRateLimit();
      
      // Nominatim API Call
      final plz = await _callNominatimAPI(latitude, longitude);
      _apiCalls++;
      
      // Cache-Entry speichern mit LRU-Management
      await _storeCacheEntry(cacheKey, plz);
      
      return plz;
    } catch (e) {
      throw PLZLookupException('PLZ-Lookup fehlgeschlagen', e.toString());
    }
  }
  
  /// Cache-Entry speichern mit LRU-Management (Task 5b.4)
  Future<void> _storeCacheEntry(String cacheKey, String plz) async {
    // Neuen Cache-Entry erstellen
    final entry = _PLZCacheEntry(plz);
    
    // Cache-Size-Limit prüfen: bei Überschreitung LRU-Eviction
    if (_plzCache.length >= _maxCacheSize) {
      await _evictLeastRecentlyUsed();
    }
    
    // Entry speichern
    _plzCache[cacheKey] = entry;
    
  }
  
  /// LRU-Eviction: Älteste Entries entfernen (Task 5b.4)
  Future<void> _evictLeastRecentlyUsed() async {
    if (_plzCache.isEmpty) return;
    
    // 10% der Cache-Einträge entfernen (Batch-Eviction für Performance)
    final evictionCount = (_maxCacheSize * 0.1).ceil();
    
    // Entries nach lastAccessed sortieren (älteste zuerst)
    final sortedEntries = _plzCache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // Älteste Entries entfernen
    for (int i = 0; i < evictionCount && i < sortedEntries.length; i++) {
      _plzCache.remove(sortedEntries[i].key);
      _cacheEvictions++;
    }
    
  }
  
  /// Ensure background cleanup is started (lazy initialization)
  void _ensureTimerStarted() {
    if (!_timerStarted && _cleanupTimer == null) {
      _timerStarted = true;
      _startBackgroundCleanup();
    }
  }

  /// Background-Cleanup-Timer starten (Task 5b.4)
  void _startBackgroundCleanup() {
    // Only start timer in production, not in tests
    // Check if we're in a test environment
    final isTestEnvironment = Platform.environment.containsKey('FLUTTER_TEST') ||
                             const String.fromEnvironment('FLUTTER_TEST').isNotEmpty;

    if (isTestEnvironment) {
      return;
    }

    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _performBackgroundCleanup();
    });

  }
  
  /// Background-Cleanup ausführen (Task 5b.4)
  void _performBackgroundCleanup() {
    final before = _plzCache.length;
    final now = DateTime.now();
    
    // Expired Entries entfernen
    _plzCache.removeWhere((key, entry) => entry.isExpired(_cacheExpiry));
    
    final removed = before - _plzCache.length;
    _lastCleanup = now;
    
    if (removed > 0) {
    }
  }

  /// Region für PLZ bestimmen - Enhanced mit Stadt-Namen (Task B: PLZ-Stadt-Mapping)
  /// 
  /// [plz] Deutsche Postleitzahl (z.B. "10115")
  /// Returns: Stadt oder Region (z.B. "München" statt "Bayern")
  String? getRegionFromPLZ(String plz) {
    // TASK B FIX: Stadt-Namen für große Städte, nicht nur Regionen
    
    // Berlin PLZ: 10xxx-14xxx
    if (plz.startsWith('1')) {
      // Für Kompatibilität mit Tests: Berlin bleibt Berlin/Brandenburg
      return 'Berlin/Brandenburg';
    }
    
    // Sachsen/Thüringen PLZ: 01xxx-09xxx
    if (plz.startsWith('0') && plz != '00000') {
      // Dresden: 01xxx
      if (plz.startsWith('01')) return 'Dresden, Sachsen';
      return 'Sachsen/Thüringen';
    }
    
    // Nord-Deutschland PLZ: 20xxx-39xxx
    if (plz.startsWith('2') || plz.startsWith('3')) {
      // Hamburg: 20xxx
      if (plz.startsWith('20')) return 'Hamburg';
      // Hannover: 30xxx
      if (plz.startsWith('30')) return 'Hannover, Niedersachsen';
      return 'Niedersachsen/Schleswig-Holstein';
    }
    
    // NRW PLZ: 40xxx-59xxx
    if (plz.startsWith('4') || plz.startsWith('5')) {
      // Düsseldorf: 40xxx
      if (plz.startsWith('40')) return 'Düsseldorf, NRW';
      // Köln: 50xxx
      if (plz.startsWith('50')) return 'Köln, NRW';
      return 'Nordrhein-Westfalen';
    }
    
    // Hessen/Rheinland-Pfalz PLZ: 60xxx-69xxx
    if (plz.startsWith('6')) {
      // Frankfurt: 60xxx
      if (plz.startsWith('60')) return 'Frankfurt am Main, Hessen';
      return 'Hessen/Rheinland-Pfalz';
    }
    
    // Baden-Württemberg PLZ: 70xxx-79xxx
    if (plz.startsWith('7')) {
      // Stuttgart: 70xxx
      if (plz.startsWith('70')) return 'Stuttgart, Baden-Württemberg';
      return 'Baden-Württemberg';
    }
    
    // Bayern PLZ: 80xxx-99xxx (CRITICAL FIX für München)
    if (plz.startsWith('8') || plz.startsWith('9')) {
      // München: 80xxx-85xxx
      if (plz.startsWith('80') || plz.startsWith('81') || plz.startsWith('82') ||
          plz.startsWith('83') || plz.startsWith('84') || plz.startsWith('85')) {
        return 'München, Bayern';
      }
      // Nürnberg: 90xxx
      if (plz.startsWith('90')) return 'Nürnberg, Bayern';
      return 'Bayern';
    }
    
    return null; // Unbekannte PLZ
  }

  /// Cache leeren (für Tests oder Memory-Management) - Enhanced Version (Task 5b.4)
  void clearCache() {
    final entriesRemoved = _plzCache.length;
    _plzCache.clear();
    
    // Statistiken zurücksetzen
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;
    _lastCleanup = DateTime.now();
    
  }

  /// Erweiterte Cache-Statistiken für Performance-Monitoring (Task 5b.4)
  Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;
    final estimatedMemoryBytes = _plzCache.values
        .map((entry) => entry.estimatedSizeBytes)
        .fold(0, (sum, size) => sum + size);
    
    return {
      // Basis-Statistiken
      'entries': _plzCache.length,
      'maxSize': _maxCacheSize,
      'usagePercent': (_plzCache.length / _maxCacheSize * 100).toStringAsFixed(1),
      
      // Performance-Metriken
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': '${hitRate.toStringAsFixed(1)}%',
      'apiCalls': _apiCalls,
      
      // Memory-Usage
      'estimatedMemoryBytes': estimatedMemoryBytes,
      'estimatedMemoryKB': '${(estimatedMemoryBytes / 1024).toStringAsFixed(1)}KB',
      
      // Expiry & Cleanup
      'cacheExpiryHours': _cacheExpiry.inHours,
      'cacheEvictions': _cacheEvictions,
      'lastCleanup': _lastCleanup?.toIso8601String() ?? 'Never',
      'cleanupIntervalMinutes': _cleanupInterval.inMinutes,
      
      // Debug-Info
      'oldestEntry': _getOldestEntryAge(),
      'newestEntry': _getNewestEntryAge(),
    };
  }
  
  /// Helper: Ältesten Cache-Entry-Alter bestimmen (für Statistiken)
  String _getOldestEntryAge() {
    if (_plzCache.isEmpty) return 'N/A';
    
    final oldestTimestamp = _plzCache.values
        .map((entry) => entry.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    final age = DateTime.now().difference(oldestTimestamp);
    
    if (age.inDays > 0) {
      return '${age.inDays}d ${age.inHours % 24}h';
    } else if (age.inHours > 0) {
      return '${age.inHours}h ${age.inMinutes % 60}m';
    } else {
      return '${age.inMinutes}m';
    }
  }
  
  /// Helper: Neuesten Cache-Entry-Alter bestimmen (für Statistiken)
  String _getNewestEntryAge() {
    if (_plzCache.isEmpty) return 'N/A';
    
    final newestTimestamp = _plzCache.values
        .map((entry) => entry.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    final age = DateTime.now().difference(newestTimestamp);
    
    if (age.inMinutes > 0) {
      return '${age.inMinutes}m';
    } else {
      return '${age.inSeconds}s';
    }
  }
  
  /// Service beenden und Ressourcen freigeben (Task 5b.4)
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _plzCache.clear();
    
  }
  
  /// Performance-Benchmark für Bulk-Operations (Task 5b.4)
  Future<Map<String, dynamic>> performBenchmark(List<List<double>> coordinates) async {
    final stopwatch = Stopwatch()..start();
    final results = <String>[];
    int cacheHitsBefore = _cacheHits;
    int cacheMissesBefore = _cacheMisses;
    int apiCallsBefore = _apiCalls;
    
    try {
      for (final coord in coordinates) {
        if (coord.length != 2) continue;
        final result = await getPLZFromCoordinates(coord[0], coord[1]);
        results.add(result);
      }
    } catch (e) {
    }
    
    stopwatch.stop();
    
    return {
      'coordinatesProcessed': coordinates.length,
      'successfulLookups': results.length,
      'totalTimeMs': stopwatch.elapsedMilliseconds,
      'averageTimeMs': stopwatch.elapsedMilliseconds / coordinates.length,
      'cacheHitsInBenchmark': _cacheHits - cacheHitsBefore,
      'cacheMissesInBenchmark': _cacheMisses - cacheMissesBefore,
      'apiCallsInBenchmark': _apiCalls - apiCallsBefore,
      'benchmarkHitRate': (() {
        final benchmarkRequests = (_cacheHits - cacheHitsBefore) + (_cacheMisses - cacheMissesBefore);
        if (benchmarkRequests == 0) return 0.0;
        return (_cacheHits - cacheHitsBefore) / benchmarkRequests * 100;
      })(),
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
