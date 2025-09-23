import 'dart:convert';
import 'package:flutter/material.dart';

/// Simple offline caching service using in-memory storage
///
/// Task 17: Error Handling & Loading States
/// Provides fallback data when network is unavailable
///
/// Note: For production, use SharedPreferences or similar persistent storage
class OfflineService {
  // Singleton pattern
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // In-memory cache storage
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache keys
  static const String cachedOffers = 'cached_offers';
  static const String cachedRetailers = 'cached_retailers';
  static const String cachedFlashDeals = 'cached_flash_deals';
  static const String cachedLocation = 'cached_location';

  // Default cache duration
  static const Duration defaultCacheDuration = Duration(hours: 24);

  /// Cache data with timestamp
  Future<void> cacheData(String key, dynamic data) async {
    try {
      _cache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
    }
  }

  /// Get cached data if valid
  Future<dynamic> getCachedData(String key, {Duration? maxAge}) async {
    try {
      if (!_cache.containsKey(key)) {
        return null;
      }

      final timestamp = _cacheTimestamps[key];
      if (timestamp == null) {
        return null;
      }

      final age = DateTime.now().difference(timestamp);
      final maxCacheAge = maxAge ?? defaultCacheDuration;

      if (age > maxCacheAge) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
        return null;
      }

      return _cache[key];
    } catch (e) {
      return null;
    }
  }

  /// Check if cache exists and is valid
  bool isCacheValid(String key, {Duration? maxAge}) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final age = DateTime.now().difference(timestamp);
    final maxCacheAge = maxAge ?? defaultCacheDuration;

    return age <= maxCacheAge;
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache age in minutes
  int? getCacheAgeMinutes(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    return DateTime.now().difference(timestamp).inMinutes;
  }

  /// Cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{};

    for (final key in _cache.keys) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null) {
        final ageMinutes = DateTime.now().difference(timestamp).inMinutes;
        stats[key] = {
          'size': _estimateSize(_cache[key]),
          'ageMinutes': ageMinutes,
          'timestamp': timestamp.toIso8601String(),
        };
      }
    }

    return stats;
  }

  /// Estimate size of cached data (simplified)
  String _estimateSize(dynamic data) {
    try {
      final json = jsonEncode(data);
      final bytes = utf8.encode(json).length;

      if (bytes < 1024) {
        return '${bytes}B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  /// Check network availability (simplified - always returns true for web)
  Future<bool> hasNetworkConnection() async {
    // In a real implementation, you would check actual network connectivity
    // For web, we assume connection is available
    // For mobile, use connectivity_plus package
    return true;
  }

  /// Get offline mode status
  bool isOfflineMode() {
    // Check if we have any valid cached data
    return _cache.isNotEmpty;
  }

  /// Create fallback data for testing
  Map<String, dynamic> createFallbackData() {
    return {
      'offers': [
        {
          'id': 'fallback-1',
          'productName': 'Offline-Angebot',
          'retailerId': 'REWE',
          'price': 1.99,
          'originalPrice': 2.99,
          'discount': 33,
          'imageUrl': '',
          'validUntil': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      ],
      'retailers': [
        {
          'id': 'REWE',
          'name': 'REWE',
          'logoUrl': '',
          'primaryColor': '#CC0000',
        },
      ],
      'flashDeals': [],
      'message': 'Sie sind offline. Dies sind gecachte Daten.',
    };
  }
}