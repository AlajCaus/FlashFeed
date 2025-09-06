import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
        debugPrint('✅ LocalStorage: User-PLZ "$plz" gespeichert');
        return true;
      } else {
        debugPrint('❌ LocalStorage: Fehler beim Speichern der PLZ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler beim Speichern: $e');
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
        debugPrint('💭 LocalStorage: Keine User-PLZ gespeichert');
        return null;
      }
      
      final timestamp = _prefs!.getInt(_plzCacheTimestampKey);
      if (timestamp == null) {
        debugPrint('⚠️ LocalStorage: PLZ ohne Timestamp gefunden, Cache ungültig');
        await clearUserPLZ(); // Cleanup
        return null;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAgeMs = maxAgeHours * 60 * 60 * 1000;
      
      if (cacheAge > maxAgeMs) {
        debugPrint('🕐 LocalStorage: PLZ-Cache abgelaufen (${cacheAge / 1000 / 3600}h alt)');
        await clearUserPLZ(); // Cleanup
        return null;
      }
      
      debugPrint('✅ LocalStorage: User-PLZ "$plz" geladen (${cacheAge / 1000 / 60}min alt)');
      return plz;
      
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler beim Laden: $e');
      return null;
    }
  }
  
  /// User-PLZ Cache löschen
  Future<bool> clearUserPLZ() async {
    try {
      final success1 = await _prefs!.remove(_userPLZKey);
      final success2 = await _prefs!.remove(_plzCacheTimestampKey);
      
      if (success1 && success2) {
        debugPrint('🧹 LocalStorage: User-PLZ Cache geleert');
        return true;
      } else {
        debugPrint('⚠️ LocalStorage: Teilweises Löschen fehlgeschlagen');
        return false;
      }
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler beim Löschen: $e');
      return false;
    }
  }
  
  /// Location-Permission-Status speichern
  /// 
  /// Verhindert wiederholte Permission-Dialoge
  Future<bool> setHasAskedForLocation(bool hasAsked) async {
    try {
      final success = await _prefs!.setBool(_hasAskedForLocationKey, hasAsked);
      debugPrint('📍 LocalStorage: Location-Permission-Status gesetzt: $hasAsked');
      return success;
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler bei Permission-Status: $e');
      return false;
    }
  }
  
  /// Location-Permission-Status laden
  bool getHasAskedForLocation() {
    try {
      final hasAsked = _prefs!.getBool(_hasAskedForLocationKey) ?? false;
      debugPrint('📍 LocalStorage: Location-Permission-Status: $hasAsked');
      return hasAsked;
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler beim Laden des Permission-Status: $e');
      return false;
    }
  }
  
  /// Gesamten Cache löschen (für Tests oder Reset)
  Future<bool> clearAll() async {
    try {
      final keys = [_userPLZKey, _plzCacheTimestampKey, _hasAskedForLocationKey];
      final results = await Future.wait(
        keys.map((key) => _prefs!.remove(key))
      );
      
      final allSuccess = results.every((result) => result == true);
      debugPrint('🧹 LocalStorage: Gesamter Cache geleert - Erfolg: $allSuccess');
      return allSuccess;
    } catch (e) {
      debugPrint('❌ LocalStorage Fehler beim Gesamt-Reset: $e');
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
