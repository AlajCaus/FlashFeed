import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';
import '../models/models.dart';
import '../utils/responsive_helper.dart';

/// FlashDealsScreen - Panel 3: Echtzeit-Rabatte
/// 
/// UI-Spezifikationen:
/// - Flash-Cards: 12px radius, 4px crimson left-border
/// - Countdown: HH:MM:SS mit Farb-Coding
/// - Professor-Demo-Button prominent
class FlashDealsScreen extends StatefulWidget {
  const FlashDealsScreen({super.key});

  @override
  State<FlashDealsScreen> createState() => _FlashDealsScreenState();
}

class _FlashDealsScreenState extends State<FlashDealsScreen> {
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashDealsProvider>().loadFlashDeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flashDealsProvider = context.watch<FlashDealsProvider>();
    // Location provider is available if needed
    // final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Professor Demo Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // Task 14: Enhanced Professor Demo with notification
                try {
                  final newDeal = flashDealsProvider.generateInstantFlashDeal();

                  // Show impressive notification
                  _showNewDealNotification(context, newDeal);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 28),
                  SizedBox(width: 8),
                  Text('PROFESSOR DEMO - NEUE DEALS'),
                ],
              ),
            ),
          ),

          // Flash Deals List
          Expanded(
            child: flashDealsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : flashDealsProvider.flashDeals.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await flashDealsProvider.loadFlashDeals();
                        },
                        child: ResponsiveHelper.isDesktop(context)
                            ? GridView.builder(
                                padding: ResponsiveHelper.getScreenPadding(context),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: ResponsiveHelper.isTablet(context) ? 2 : 3,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: ResponsiveHelper.space4,
                                  mainAxisSpacing: ResponsiveHelper.space4,
                                ),
                                itemCount: flashDealsProvider.flashDeals.length,
                                itemBuilder: (context, index) {
                                  final deal = flashDealsProvider.flashDeals[index];
                                  return _buildFlashDealCard(deal);
                                },
                              )
                            : ListView.builder(
                                padding: ResponsiveHelper.getScreenPadding(context),
                                itemCount: flashDealsProvider.flashDeals.length,
                                itemBuilder: (context, index) {
                                  final deal = flashDealsProvider.flashDeals[index];
                                  return _buildFlashDealCard(deal);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_off, size: 64, color: textSecondary.withAlpha(102)),
          const SizedBox(height: 16),
          Text(
            'Keine Flash Deals verfügbar',
            style: TextStyle(fontSize: 16, color: textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drücken Sie den Demo-Button!',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDealCard(FlashDeal deal) {
    final Color timerColor = _getTimerColor(deal.remainingSeconds);
    final cardPadding = ResponsiveHelper.getCardPadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4);
    
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: primaryRed,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer & Discount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Countdown Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: timerColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: timerColor),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(deal.remainingSeconds),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Discount Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${deal.discountPercentage}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Product Name
            Text(
              deal.productName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Brand
            Text(
              deal.brand,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Prices
            Row(
              children: [
                Text(
                  '${deal.originalPrice.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${deal.flashPrice.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Store Info
            Row(
              children: [
                Icon(Icons.store, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${deal.retailer} - ${deal.storeName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Button
            ElevatedButton(
              onPressed: () => _showLageplanModal(context, deal),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Zum Lageplan'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimerColor(int seconds) {
    if (seconds > 3600) return primaryGreen; // > 1 hour
    if (seconds > 1800) return secondaryOrange; // 30-60 min
    return primaryRed; // < 30 min
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')}';
  }

  // Task 14: Mock Push Notification for new deals
  void _showNewDealNotification(BuildContext context, FlashDeal deal) {
    // Show impressive notification banner
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: primaryRed,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '🔥 FLASH DEAL!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${deal.productName} - ${deal.discountPercentage}% RABATT!',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              'Nur noch ${deal.remainingMinutes} Minuten! Bei ${deal.retailer}',
              style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(204)),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'ANSEHEN',
          textColor: Colors.yellow,
          onPressed: () {
            // Scroll to top to see the new deal
          },
        ),
      ),
    );

    // Optional: Play a notification sound (web audio API)
    // This would require additional implementation
  }

  void _showLageplanModal(BuildContext context, FlashDeal deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.storeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        deal.storeAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Lageplan
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SVG Placeholder
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Text(
                              'Lageplan\n(SVG in Phase 2)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          // Pulsing red dot
                          Positioned(
                            left: deal.shelfLocation.x.toDouble(),
                            top: deal.shelfLocation.y.toDouble(),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryRed.withAlpha(102),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Shelf Location
                    Text(
                      'Gang ${deal.shelfLocation.aisle}, ${deal.shelfLocation.shelf}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Indoor-Navigation in Phase 2'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation),
                    SizedBox(width: 8),
                    Text('Navigation starten'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
