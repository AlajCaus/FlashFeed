import 'dart:async';
import 'package:flutter/material.dart';
import '../services/plz_lookup_service.dart';
import '../services/plz_cache_memory_manager.dart';

/// Performance Metrics Dashboard für PLZLookupService (Task 5b.4)
/// 
/// Debug-Widget für Development-Environment
/// Zeigt Real-time Cache-Stats, Memory-Usage, Performance-Metriken
/// 
/// Verwendung:
/// ```dart
/// PLZPerformanceDashboard(
///   plzService: PLZLookupService(),
///   refreshInterval: Duration(seconds: 5),
/// )
/// ```
class PLZPerformanceDashboard extends StatefulWidget {
  final PLZLookupService plzService;
  final Duration refreshInterval;
  final bool showDetailedStats;
  
  const PLZPerformanceDashboard({
    super.key,
    required this.plzService,
    this.refreshInterval = const Duration(seconds: 5),
    this.showDetailedStats = true,
  });
  
  @override
  State<PLZPerformanceDashboard> createState() => _PLZPerformanceDashboardState();
}

class _PLZPerformanceDashboardState extends State<PLZPerformanceDashboard> {
  Timer? _refreshTimer;
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _memoryStats = {};
  final List<Map<String, dynamic>> _performanceHistory = [];
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _startPerformanceMonitoring() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      _updatePerformanceMetrics();
    });
    
    // Initial Update
    _updatePerformanceMetrics();
  }
  
  void _updatePerformanceMetrics() {
    if (!mounted) return;
    
    setState(() {
      _cacheStats = widget.plzService.getCacheStats();
      _memoryStats = PLZCacheMemoryManager.instance.getMemoryStats();
      
      // Performance-History für Trend-Analyse (letzten 20 Measurements)
      _performanceHistory.add({
        'timestamp': DateTime.now(),
        'cacheHits': _cacheStats['cacheHits'] ?? 0,
        'cacheMisses': _cacheStats['cacheMisses'] ?? 0,
        'memoryKB': double.tryParse((_cacheStats['estimatedMemoryKB'] as String? ?? '0KB').replaceAll('KB', '')) ?? 0,
      });
      
      if (_performanceHistory.length > 20) {
        _performanceHistory.removeAt(0);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.analytics, size: 20),
            const SizedBox(width: 8),
            const Text('PLZ Cache Performance'),
            const Spacer(),
            _buildQuickStats(),
          ],
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCacheStatistics(),
                const SizedBox(height: 16),
                _buildMemoryStatistics(),
                if (widget.showDetailedStats) ...[
                  const SizedBox(height: 16),
                  _buildPerformanceTrends(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats() {
    final hitRate = _cacheStats['hitRate'] ?? '0%';
    final entries = _cacheStats['entries'] ?? 0;
    final memoryKB = _cacheStats['estimatedMemoryKB'] ?? '0KB';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickStat('Hit Rate', hitRate, Colors.green),
        const SizedBox(width: 8),
        _buildQuickStat('Entries', entries.toString(), Colors.blue),
        const SizedBox(width: 8),
        _buildQuickStat('Memory', memoryKB, Colors.orange),
      ],
    );
  }
  
  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCacheStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cache Statistics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatRow('Cache Entries', '${_cacheStats['entries']}/${_cacheStats['maxSize']}'),
            ),
            Expanded(
              child: _buildStatRow('Usage', '${_cacheStats['usagePercent']}%'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatRow('Cache Hits', '${_cacheStats['cacheHits']}'),
            ),
            Expanded(
              child: _buildStatRow('Cache Misses', '${_cacheStats['cacheMisses']}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatRow('Hit Rate', '${_cacheStats['hitRate']}'),
            ),
            Expanded(
              child: _buildStatRow('API Calls', '${_cacheStats['apiCalls']}'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMemoryStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Memory Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatRow('Memory Usage', '${_cacheStats['estimatedMemoryKB']}'),
            ),
            Expanded(
              child: _buildStatRow('Evictions', '${_cacheStats['cacheEvictions']}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatRow('Memory Pressure', _memoryStats['memoryPressureDetected'] == true ? 'Yes' : 'No'),
            ),
            Expanded(
              child: _buildStatRow('Max Cache Size', '${_memoryStats['currentMaxCacheSize']}'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPerformanceTrends() {
    if (_performanceHistory.isEmpty) {
      return const Text('Performance trends will appear after a few measurements...');
    }
    
    final latestEntry = _performanceHistory.last;
    final oldestEntry = _performanceHistory.first;
    final hitsTrend = (latestEntry['cacheHits'] as int) - (oldestEntry['cacheHits'] as int);
    final missesTrend = (latestEntry['cacheMisses'] as int) - (oldestEntry['cacheMisses'] as int);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trends',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTrendRow('Cache Hits Trend', '+$hitsTrend', hitsTrend >= 0),
            ),
            Expanded(
              child: _buildTrendRow('Cache Misses Trend', '+$missesTrend', missesTrend <= 0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatRow('Oldest Entry Age', '${_cacheStats['oldestEntry']}'),
        _buildStatRow('Last Cleanup', '${_cacheStats['lastCleanup']}'),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cache Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                widget.plzService.clearCache();
                _updatePerformanceMetrics();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear Cache'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Test-Benchmark mit 10 zufälligen Koordinaten
                final coordinates = [
                  [52.5200, 13.4050], // Berlin
                  [48.1351, 11.5820], // München
                  [53.5511, 9.9937],  // Hamburg
                  [50.9375, 6.9603],  // Köln
                  [50.1109, 8.6821],  // Frankfurt
                  [48.7758, 9.1829],  // Stuttgart
                  [51.2277, 6.7735],  // Düsseldorf
                  [52.3759, 9.7320],  // Hannover
                  [49.4521, 11.0767], // Nürnberg
                  [51.0504, 13.7373], // Dresden
                ];
                
                try {
                  final benchmark = await widget.plzService.performBenchmark(coordinates);
                  _updatePerformanceMetrics();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Benchmark completed: ${benchmark['totalTimeMs']}ms for ${coordinates.length} coordinates'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Benchmark failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.speed, size: 16),
              label: const Text('Run Benchmark'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildTrendRow(String label, String value, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone Performance Monitor für Console/Debug-Output
class PLZPerformanceMonitor {
  static Timer? _consoleTimer;
  
  /// Console-basiertes Performance-Monitoring starten
  static void startConsoleMonitoring(PLZLookupService service, {
    Duration interval = const Duration(minutes: 1),
  }) {
    _consoleTimer = Timer.periodic(interval, (timer) {
      _printPerformanceStats(service);
    });
    
  }
  
  /// Console-Monitoring stoppen
  static void stopConsoleMonitoring() {
    _consoleTimer?.cancel();
    _consoleTimer = null;
  }
  
  /// Performance-Stats in Console ausgeben
  static void _printPerformanceStats(PLZLookupService service) {
    final stats = service.getCacheStats();
    final memoryStats = PLZCacheMemoryManager.instance.getMemoryStats();
    
  }
}
