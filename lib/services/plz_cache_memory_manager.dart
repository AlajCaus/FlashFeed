import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Memory-Monitoring und Auto-Cleanup für PLZLookupService Cache (Task 5b.4)
/// 
/// Features:
/// - Memory-Pressure-Detection basierend auf verfügbarem System-Memory
/// - Adaptive Cache-Size-Limits je nach Speicher-Verfügbarkeit  
/// - Proactive Cleanup bei Memory-Knappheit
/// - Performance-Impact-Minimierung durch intelligente Cleanup-Strategien
class PLZCacheMemoryManager {
  static PLZCacheMemoryManager? _instance;
  static PLZCacheMemoryManager get instance {
    _instance ??= PLZCacheMemoryManager._internal();
    return _instance!;
  }
  
  PLZCacheMemoryManager._internal();
  
  // Memory-Monitoring State
  Timer? _memoryMonitorTimer;
  DateTime? _lastMemoryCheck;
  bool _memoryPressureDetected = false;
  
  // Memory-Thresholds (Konfigurierbar)
  static const int _lowMemoryThresholdMB = 100; // Unter 100MB = Memory-Pressure
  static const int _criticalMemoryThresholdMB = 50; // Unter 50MB = Critical
  static const Duration _memoryCheckInterval = Duration(minutes: 5);
  
  // Adaptive Cache-Limits
  int _currentMaxCacheSize = 1000; // Dynamic, basierend auf Memory-Situation
  static const int _minCacheSize = 100; // Minimum Cache für Funktionalität
  static const int _maxCacheSize = 2000; // Maximum Cache bei viel Memory
  
  // Callback für Cache-Management
  Function(int newMaxSize)? _onCacheSizeChange;
  Function()? _onMemoryPressureCleanup;
  
  /// Memory-Manager starten
  void startMemoryMonitoring({
    Function(int newMaxSize)? onCacheSizeChange,
    Function()? onMemoryPressureCleanup,
  }) {
    _onCacheSizeChange = onCacheSizeChange;
    _onMemoryPressureCleanup = onMemoryPressureCleanup;
    
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (timer) {
      _performMemoryCheck();
    });
    
    debugPrint('PLZ Memory Manager started - checking every ${_memoryCheckInterval.inMinutes}min');
  }
  
  /// Memory-Manager stoppen
  void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    debugPrint('PLZ Memory Manager stopped');
  }
  
  /// Aktuelle Memory-Situation prüfen und Cache-Limits anpassen
  Future<void> _performMemoryCheck() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      _lastMemoryCheck = DateTime.now();
      
      final availableMemoryMB = memoryInfo['availableMB'] ?? 0;
      final usedMemoryMB = memoryInfo['usedMB'] ?? 0;
      
      // Memory-Pressure-Detection
      final previousPressure = _memoryPressureDetected;
      _memoryPressureDetected = availableMemoryMB < _lowMemoryThresholdMB;
      
      // Cache-Size basierend auf Memory-Situation anpassen
      final newCacheSize = _calculateOptimalCacheSize(availableMemoryMB);
      
      if (newCacheSize != _currentMaxCacheSize) {
        _currentMaxCacheSize = newCacheSize;
        _onCacheSizeChange?.call(newCacheSize);
        
        debugPrint('PLZ Cache size adjusted: $newCacheSize (Available memory: ${availableMemoryMB}MB)');
      }
      
      // Bei Critical Memory: Sofortiger Cleanup
      if (availableMemoryMB < _criticalMemoryThresholdMB) {
        debugPrint('PLZ Critical memory detected: ${availableMemoryMB}MB - triggering cleanup');
        _onMemoryPressureCleanup?.call();
      }
      
      // Memory-Pressure-Status-Change loggen
      if (_memoryPressureDetected != previousPressure) {
        debugPrint('PLZ Memory pressure ${_memoryPressureDetected ? "detected" : "resolved"}: ${availableMemoryMB}MB available');
      }
      
    } catch (e) {
      debugPrint('PLZ Memory check failed: $e');
    }
  }
  
  /// Optimale Cache-Size basierend auf verfügbarem Memory berechnen
  int _calculateOptimalCacheSize(int availableMemoryMB) {
    if (availableMemoryMB >= 500) {
      // Viel Memory: Großer Cache
      return _maxCacheSize;
    } else if (availableMemoryMB >= 200) {
      // Mittleres Memory: Standard Cache
      return 1000;
    } else if (availableMemoryMB >= 100) {
      // Wenig Memory: Reduzierter Cache
      return 500;
    } else {
      // Critical Memory: Minimal Cache
      return _minCacheSize;
    }
  }
  
  /// Memory-Information vom System abrufen
  Future<Map<String, int>> _getMemoryInfo() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        return await _getUnixMemoryInfo();
      } else if (Platform.isWindows) {
        return await _getWindowsMemoryInfo();
      } else {
        // Mobile/Web: Memory-Info nicht verfügbar, konservative Schätzung
        return {'availableMB': 200, 'usedMB': 0, 'totalMB': 0};
      }
    } catch (e) {
      debugPrint('Failed to get memory info: $e');
      return {'availableMB': 200, 'usedMB': 0, 'totalMB': 0}; // Safe defaults
    }
  }
  
  /// Unix-basierte Memory-Info (Linux/macOS)
  Future<Map<String, int>> _getUnixMemoryInfo() async {
    try {
      if (Platform.isLinux) {
        // Linux: /proc/meminfo auslesen
        final result = await Process.run('cat', ['/proc/meminfo']);
        return _parseLinuxMemInfo(result.stdout.toString());
      } else if (Platform.isMacOS) {
        // macOS: vm_stat command
        final result = await Process.run('vm_stat', []);
        return _parseMacOSMemInfo(result.stdout.toString());
      }
    } catch (e) {
      debugPrint('Unix memory info failed: $e');
    }
    
    return {'availableMB': 200, 'usedMB': 0, 'totalMB': 0};
  }
  
  /// Windows Memory-Info (über PowerShell)
  Future<Map<String, int>> _getWindowsMemoryInfo() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory'
      ]);
      
      return _parseWindowsMemInfo(result.stdout.toString());
    } catch (e) {
      debugPrint('Windows memory info failed: $e');
      return {'availableMB': 200, 'usedMB': 0, 'totalMB': 0};
    }
  }
  
  /// Linux /proc/meminfo parsen
  Map<String, int> _parseLinuxMemInfo(String memInfo) {
    final lines = memInfo.split('\n');
    int totalKB = 0;
    int availableKB = 0;
    
    for (final line in lines) {
      if (line.startsWith('MemTotal:')) {
        totalKB = int.parse(line.split(RegExp(r'\s+'))[1]);
      } else if (line.startsWith('MemAvailable:')) {
        availableKB = int.parse(line.split(RegExp(r'\s+'))[1]);
      }
    }
    
    return {
      'availableMB': (availableKB / 1024).round(),
      'usedMB': ((totalKB - availableKB) / 1024).round(),
      'totalMB': (totalKB / 1024).round(),
    };
  }
  
  /// macOS vm_stat output parsen
  Map<String, int> _parseMacOSMemInfo(String vmStat) {
    // Vereinfachte macOS Memory-Parsing
    // In production: detailliertere Parsing-Logic implementieren
    return {'availableMB': 500, 'usedMB': 0, 'totalMB': 0}; // Placeholder
  }
  
  /// Windows PowerShell Output parsen
  Map<String, int> _parseWindowsMemInfo(String psOutput) {
    // Vereinfachte Windows Memory-Parsing
    // In production: PowerShell Output detailliert parsen
    return {'availableMB': 300, 'usedMB': 0, 'totalMB': 0}; // Placeholder
  }
  
  /// Memory-Manager-Statistiken für Debug
  Map<String, dynamic> getMemoryStats() {
    return {
      'isMonitoring': _memoryMonitorTimer?.isActive ?? false,
      'memoryPressureDetected': _memoryPressureDetected,
      'currentMaxCacheSize': _currentMaxCacheSize,
      'lastMemoryCheck': _lastMemoryCheck?.toIso8601String() ?? 'Never',
      'lowMemoryThresholdMB': _lowMemoryThresholdMB,
      'criticalMemoryThresholdMB': _criticalMemoryThresholdMB,
      'checkIntervalMinutes': _memoryCheckInterval.inMinutes,
    };
  }
  
  /// Manual Memory-Check (für Tests oder On-Demand)
  Future<Map<String, int>> checkMemoryNow() async {
    return await _getMemoryInfo();
  }
  
  /// Memory-Manager für Tests/Cleanup disposen
  void dispose() {
    stopMemoryMonitoring();
    _instance = null;
  }
}
