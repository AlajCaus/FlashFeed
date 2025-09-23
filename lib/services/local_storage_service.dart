import 'package:shared_preferences/shared_preferences.dart';

/// Service für lokale Speicherung von User-Präferenzen
/// 
/// Hauptfunktion: PLZ-Caching als GPS-Fallback
/// Pattern: Singleton mit SharedPreferences Integration
/// Testing: Unit Tests für alle Storage-Operationen erforderlich
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;
  
  // Private Constructor für Singleton
  LocalStorageService._();
  
  /// Factory Constructor für Singleton-Zugriff
  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }
  
  // Storage Keys
  static const String _userPLZKey = 'user_plz';
  static const String _plzCacheTimestampKey = 'plz_cache_timestamp';
  static const String _hasAskedForLocationKey = 'has_asked_for_location';
  static const String _searchHistoryKey = 'search_history';
  
  /// User-PLZ speichern mit Timestamp
  /// 
  /// [plz] Deutsche PLZ (5 Ziffern, bereits validiert)
  /// Returns: true bei Erfolg, false bei Fehler
  Future<bool> saveUserPLZ(String plz) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final success1 = await _prefs!.setString(_userPLZKey, plz);
      final success2 = await _prefs!.setInt(_plzCacheTimestampKey, now);
      
      if (success1 && success2) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// User-PLZ laden (mit Cache-Expiry)
  /// 
  /// [maxAgeHours] Cache-Gültigkeit in Stunden (default: 24h)
  /// Returns: PLZ wenn gültig, null wenn nicht vorhanden/abgelaufen
  Future<String?> getUserPLZ({int maxAgeHours = 24}) async {
    try {
      final plz = _prefs!.getString(_userPLZKey);
      if (plz == null) {
        return null;
      }
      
      final timestamp = _prefs!.getInt(_plzCacheTimestampKey);
      if (timestamp == null) {
        await clearUserPLZ(); // Cleanup
        return null;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAgeMs = maxAgeHours * 60 * 60 * 1000;
      
      if (cacheAge > maxAgeMs) {
        await clearUserPLZ(); // Cleanup
        return null;
      }
      
      return plz;
      
    } catch (e) {
      return null;
    }
  }
  
  /// User-PLZ Cache löschen
  Future<bool> clearUserPLZ() async {
    try {
      final success1 = await _prefs!.remove(_userPLZKey);
      final success2 = await _prefs!.remove(_plzCacheTimestampKey);
      
      if (success1 && success2) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Location-Permission-Status speichern
  /// 
  /// Verhindert wiederholte Permission-Dialoge
  Future<bool> setHasAskedForLocation(bool hasAsked) async {
    try {
      final success = await _prefs!.setBool(_hasAskedForLocationKey, hasAsked);
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// Location-Permission-Status laden
  bool getHasAskedForLocation() {
    try {
      final hasAsked = _prefs!.getBool(_hasAskedForLocationKey) ?? false;
      return hasAsked;
    } catch (e) {
      return false;
    }
  }
  
  /// Search History Methods
  Future<List<String>> getSearchHistory() async {
    try {
      final history = _prefs!.getStringList(_searchHistoryKey) ?? [];
      return history;
    } catch (e) {
      return [];
    }
  }
  
  Future<bool> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return false;
    
    try {
      List<String> history = _prefs!.getStringList(_searchHistoryKey) ?? [];
      
      // Remove if already exists (to move to top)
      history.remove(query);
      
      // Add to beginning
      history.insert(0, query);
      
      // Keep only last 10 searches
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }
      
      return await _prefs!.setStringList(_searchHistoryKey, history);
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> clearSearchHistory() async {
    try {
      return await _prefs!.remove(_searchHistoryKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Gesamten Cache löschen (für Tests oder Reset)
  Future<bool> clearAll() async {
    try {
      final keys = [_userPLZKey, _plzCacheTimestampKey, _hasAskedForLocationKey, _searchHistoryKey];
      final results = await Future.wait(
        keys.map((key) => _prefs!.remove(key))
      );
      
      final allSuccess = results.every((result) => result == true);
      return allSuccess;
    } catch (e) {
      return false;
    }
  }
  
  /// Debug-Informationen für alle gespeicherten Werte
  Map<String, dynamic> getDebugInfo() {
    try {
      return {
        'userPLZ': _prefs!.getString(_userPLZKey),
        'cacheTimestamp': _prefs!.getInt(_plzCacheTimestampKey),
        'hasAskedForLocation': _prefs!.getBool(_hasAskedForLocationKey),
        'searchHistory': _prefs!.getStringList(_searchHistoryKey),
        'cacheAgeMinutes': () {
          final timestamp = _prefs!.getInt(_plzCacheTimestampKey);
          if (timestamp == null) return null;
          return (DateTime.now().millisecondsSinceEpoch - timestamp) / 1000 / 60;
        }(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
