import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/location_provider.dart';
import '../models/models.dart';
import '../utils/responsive_helper.dart';
import '../widgets/flash_deals_filter_bar.dart';
import '../widgets/flash_deals_statistics.dart';

// Conditional import for web audio service
import '../services/web_audio_service_stub.dart'
    if (dart.library.html) '../services/web_audio_service_web.dart';

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

class _FlashDealsScreenState extends State<FlashDealsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  // Track expired deals for animation
  final Set<String> _expiredDealIds = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashDealsProvider>().loadFlashDeals();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashDealsProvider = context.watch<FlashDealsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Statistics Dashboard
          Padding(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const FlashDealsStatistics(),
            ),
          ),

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

          // Filter Bar
          const FlashDealsFilterBar(),

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
                                controller: _scrollController,
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
                                  return _buildAnimatedDealCard(deal, index);
                                },
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: ResponsiveHelper.getScreenPadding(context),
                                itemCount: flashDealsProvider.flashDeals.length,
                                itemBuilder: (context, index) {
                                  final deal = flashDealsProvider.flashDeals[index];
                                  return _buildAnimatedDealCard(deal, index);
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

  Widget _buildAnimatedDealCard(FlashDeal deal, int index) {
    final isExpired = deal.remainingSeconds <= 0;
    final wasExpired = _expiredDealIds.contains(deal.productName);

    if (isExpired && !wasExpired) {
      _expiredDealIds.add(deal.productName);
      // Trigger expired animation
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // Wrap with Dismissible for swipe functionality
    return Dismissible(
      key: Key(deal.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Swipe left: Hide deal
          context.read<FlashDealsProvider>().hideDeal(deal.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${deal.productName}" ausgeblendet'),
              action: SnackBarAction(
                label: 'Rückgängig',
                onPressed: () {
                  context.read<FlashDealsProvider>().unhideDeal(deal.id);
                },
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Swipe right: Favorite deal
          _favoriteDeal(deal);
          // Re-add deal since we don't actually remove favorites
          context.read<FlashDealsProvider>().loadFlashDeals();
        }
      },
      background: Container(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4)),
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.favorite, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4)),
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.visibility_off, color: Colors.white, size: 32),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(isExpired ? 0.05 : 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isExpired ? 0.5 : 1.0,
          child: _buildFlashDealCard(deal, isExpired),
        ),
      ),
    );
  }

  Widget _buildFlashDealCard(FlashDeal deal, bool isExpired) {
    final Color timerColor = _getTimerColor(deal.remainingSeconds);
    final cardPadding = ResponsiveHelper.getCardPadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context, ResponsiveHelper.space4);
    final locationProvider = context.watch<LocationProvider>();
    
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

            // Product Name with Category Icon
            Row(
              children: [
                _getCategoryIcon(deal.productName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deal.productName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: isExpired ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Brand with Regional Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    deal.brand,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
                if (locationProvider.hasPostalCode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text(
                          'Regional',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
            
            // Store Info with Distance
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
                // Distance display
                if (locationProvider.hasLocation)
                  _buildDistanceChip(deal),
              ],
            ),

            // Quick Actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  color: textSecondary,
                  onPressed: () => _shareDeal(deal),
                  tooltip: 'Teilen',
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 20),
                  color: textSecondary,
                  onPressed: () => _favoriteDeal(deal),
                  tooltip: 'Favorit',
                ),
                IconButton(
                  icon: const Icon(Icons.directions, size: 20),
                  color: textSecondary,
                  onPressed: () => _navigateToDeal(deal),
                  tooltip: 'Navigation',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Button
            ElevatedButton(
              onPressed: isExpired ? null : () => _showLageplanModal(context, deal),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired ? Colors.grey : primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(isExpired ? 'Deal abgelaufen' : 'Zum Lageplan'),
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

  // Helper methods for new features
  Icon _getCategoryIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('fleisch') || name.contains('wurst')) {
      return Icon(Icons.set_meal, size: 20, color: primaryRed);
    } else if (name.contains('obst') || name.contains('gemüse')) {
      return Icon(Icons.eco, size: 20, color: primaryGreen);
    } else if (name.contains('milch') || name.contains('käse')) {
      return Icon(Icons.egg, size: 20, color: secondaryOrange);
    } else if (name.contains('brot') || name.contains('backware')) {
      return Icon(Icons.bakery_dining, size: 20, color: Colors.brown);
    } else if (name.contains('getränk')) {
      return Icon(Icons.local_drink, size: 20, color: Colors.blue);
    }
    return Icon(Icons.shopping_basket, size: 20, color: textSecondary);
  }

  // Distance calculation with actual coordinates
  Widget _buildDistanceChip(FlashDeal deal) {
    final locationProvider = context.watch<LocationProvider>();

    if (!locationProvider.hasLocation) return const SizedBox.shrink();

    try {
      final distance = locationProvider.calculateDistance(
        deal.storeLat,
        deal.storeLng,
      );

      Color chipColor;
      if (distance < 1) {
        chipColor = primaryGreen;
      } else if (distance < 3) {
        chipColor = secondaryOrange;
      } else {
        chipColor = textSecondary;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: chipColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 12, color: chipColor),
            const SizedBox(width: 2),
            Text(
              '${distance.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 11,
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _shareDeal(FlashDeal deal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deal "${deal.productName}" geteilt!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _favoriteDeal(FlashDeal deal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${deal.productName}" zu Favoriten hinzugefügt!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDeal(FlashDeal deal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation zu ${deal.storeName} gestartet!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Task 14: Mock Push Notification for new deals
  void _showNewDealNotification(BuildContext context, FlashDeal deal) {
    // Smooth scroll to top to show new deal
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }

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

    // Play a notification sound (web audio API)
    _playNotificationSound();
  }

  void _playNotificationSound() {
    // Use web audio service for cross-platform compatibility
    WebAudioServiceImpl.playNotificationSound();
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
