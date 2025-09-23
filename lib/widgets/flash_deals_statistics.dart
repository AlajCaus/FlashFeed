import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/location_provider.dart';
import '../utils/responsive_helper.dart';

/// Statistik-Dashboard für Flash Deals
/// Zeigt Live-Counter, Ersparnis und Update-Status
class FlashDealsStatistics extends StatefulWidget {
  const FlashDealsStatistics({super.key});

  @override
  State<FlashDealsStatistics> createState() => _FlashDealsStatisticsState();
}

class _FlashDealsStatisticsState extends State<FlashDealsStatistics>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashProvider = context.watch<FlashDealsProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.1),
            primaryRed.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Live-Update Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFFDC143C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Updates alle 1 Sek',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statistics Grid
          isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      icon: Icons.local_offer,
                      label: 'Aktive Deals',
                      value: '${flashProvider.totalDealsCount}',
                      color: primaryGreen,
                      subtitle: flashProvider.hasRegionalFiltering
                          ? 'In ${locationProvider.postalCode}'
                          : null,
                    ),
                    _buildStatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Kritische Deals',
                      value: '${flashProvider.urgentDealsCount}',
                      color: primaryRed,
                      subtitle: '< 30 Min',
                    ),
                    _buildStatCard(
                      icon: Icons.savings,
                      label: 'Mögliche Ersparnis',
                      value: '${flashProvider.totalPotentialSavings.toStringAsFixed(2)}€',
                      color: secondaryOrange,
                      subtitle: 'Gesamt',
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.local_offer,
                            label: 'Aktive Deals',
                            value: '${flashProvider.totalDealsCount}',
                            color: primaryGreen,
                            subtitle: flashProvider.hasRegionalFiltering
                                ? 'PLZ ${locationProvider.postalCode}'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.warning_amber_rounded,
                            label: 'Kritisch',
                            value: '${flashProvider.urgentDealsCount}',
                            color: primaryRed,
                            subtitle: '< 30 Min',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatCard(
                      icon: Icons.savings,
                      label: 'Mögliche Ersparnis',
                      value: '${flashProvider.totalPotentialSavings.toStringAsFixed(2)}€',
                      color: secondaryOrange,
                      subtitle: 'Gesamt',
                      fullWidth: true,
                    ),
                  ],
                ),

          // Regional Info
          if (flashProvider.hasRegionalFiltering) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Regionale Deals für ${locationProvider.postalCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}