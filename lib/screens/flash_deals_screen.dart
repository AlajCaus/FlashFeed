import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../models/models.dart';
import '../utils/responsive_helper.dart';
import '../widgets/flash_deals_filter_bar.dart';
import '../widgets/flash_deals_statistics.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/skeleton_loader.dart';

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
    final userProvider = context.watch<UserProvider>();

    // Task 16: No limits for free users - they see ALL flash deals from their selected retailer
    // Premium users see flash deals from ALL retailers
    var flashDeals = flashDealsProvider.flashDeals;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _buildContentArea(flashDealsProvider, flashDeals, userProvider),
    );
  }

  /// Build content area with proper error handling and loading states
  Widget _buildContentArea(FlashDealsProvider flashDealsProvider, List<FlashDeal> flashDeals, UserProvider userProvider) {
    // Check for error state first
    if (flashDealsProvider.errorMessage != null && !flashDealsProvider.isLoading) {
      ErrorType errorType = ErrorType.general;

      // Determine error type based on message
      if (flashDealsProvider.errorMessage!.toLowerCase().contains('netzwerk') ||
          flashDealsProvider.errorMessage!.toLowerCase().contains('internet')) {
        errorType = ErrorType.network;
      } else if (flashDealsProvider.errorMessage!.toLowerCase().contains('region')) {
        errorType = ErrorType.region;
      } else if (flashDealsProvider.errorMessage!.toLowerCase().contains('keine')) {
        errorType = ErrorType.noData;
      }

      return ErrorStateWidget(
        errorMessage: flashDealsProvider.errorMessage,
        errorType: errorType,
        onRetry: () async {
          await flashDealsProvider.loadFlashDeals();
        },
      );
    }

    // Check for loading state
    if (flashDealsProvider.isLoading && flashDealsProvider.flashDeals.isEmpty) {
      // Initial loading - show skeleton
      return const SingleChildScrollView(
        child: FlashDealsListSkeleton(itemCount: 6),
      );
    }

    // Check for empty state
    if (!flashDealsProvider.isLoading && flashDeals.isEmpty) {
      return _buildEmptyState();
    }

    // Show content with refresh indicator - EVERYTHING is scrollable
    return RefreshIndicator(
      color: primaryRed,
      onRefresh: () async {
        await flashDealsProvider.loadFlashDeals();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // All header content as scrollable slivers
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Task 16: Freemium Limit Display
                if (!userProvider.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userProvider.getRemainingLimitText('flashdeals'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showUpgradeDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Premium'),
                        ),
                      ],
                    ),
                  ),

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
              ],
            ),
          ),
          // Flash deals fill remaining space but minimum height to ensure scrolling
          SliverToBoxAdapter(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.all(8),
              child: _buildFlashDealsWidget(flashDeals),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDealsWidget(List<FlashDeal> flashDeals) {
    // If there are no deals, show empty state
    if (flashDeals.isEmpty) {
      return _buildEmptyState();
    }

    final width = MediaQuery.of(context).size.width;
    final bool isVerySmall = width < 400;

    // For mobile/small screens: Use Column with cards
    if (width < 600) {
      return Column(
        children: flashDeals.map((deal) {
          final index = flashDeals.indexOf(deal);
          return SizedBox(
            height: isVerySmall ? 130 : 150,
            child: _buildCompactDealCard(deal, index, isVerySmall),
          );
        }).toList(),
      );
    }

    // For larger screens: Use Wrap for flexible grid
    final cardWidth = width > 1200
        ? (width - 48) / 3  // 3 columns
        : width > 800
            ? (width - 32) / 2  // 2 columns
            : width - 16;  // 1 column

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flashDeals.map((deal) {
        final index = flashDeals.indexOf(deal);
        return SizedBox(
          width: cardWidth,
          height: 150,
          child: _buildCompactDealCard(deal, index, false),
        );
      }).toList(),
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

  Widget _buildCompactDealCard(FlashDeal deal, int index, bool isVerySmall) {
    final isExpired = deal.remainingSeconds <= 0;
    final wasExpired = _expiredDealIds.contains(deal.productName);

    if (isExpired && !wasExpired) {
      _expiredDealIds.add(deal.productName);
      Future.delayed(Duration.zero, () {
        if (mounted) setState(() {});
      });
    }

    // Wrap with dismissible for swipe
    return Dismissible(
      key: Key(deal.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
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
          _favoriteDeal(deal);
          context.read<FlashDealsProvider>().loadFlashDeals();
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.favorite, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.visibility_off, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isExpired ? Colors.grey : primaryRed, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isExpired ? null : () => _showLageplanModal(context, deal),
            child: Padding(
              padding: EdgeInsets.all(isVerySmall ? 8.0 : 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Timer and Discount
                  Row(
                    children: [
                      // Timer
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTimerColor(deal.remainingSeconds).withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatTimeShort(deal.remainingSeconds),
                            style: TextStyle(
                              fontSize: isVerySmall ? 11 : 12,
                              fontWeight: FontWeight.bold,
                              color: _getTimerColor(deal.remainingSeconds),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Discount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-${deal.discountPercentage}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isVerySmall ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Product Name
                  Expanded(
                    child: Center(
                      child: Text(
                        deal.productName,
                        style: TextStyle(
                          fontSize: isVerySmall ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${deal.originalPrice.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: isVerySmall ? 11 : 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${deal.flashPrice.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: isVerySmall ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),

                  // Store
                  Text(
                    '${deal.retailer} • ${deal.storeName}',
                    style: TextStyle(
                      fontSize: isVerySmall ? 10 : 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isSmallCard = MediaQuery.of(context).size.width < 400;
    final cardPadding = EdgeInsets.all(isMobile ? 12.0 : 16.0);
    final spacing = isMobile ? 8.0 : 12.0;
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
            // Timer & Discount - Responsive sizes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Countdown Timer
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallCard ? 4 : 8,
                      vertical: isSmallCard ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: timerColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: isSmallCard ? 12 : 14, color: timerColor),
                        const SizedBox(width: 2),
                        Text(
                          isSmallCard ? _formatTimeShort(deal.remainingSeconds) : _formatTime(deal.remainingSeconds),
                          style: TextStyle(
                            fontSize: isSmallCard ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: timerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Discount Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallCard ? 6 : 8,
                    vertical: isSmallCard ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '-${deal.discountPercentage}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallCard ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: spacing),

            // Product Name with Category Icon - Responsive text
            Row(
              children: [
                if (!isSmallCard) _getCategoryIcon(deal.productName),
                if (!isSmallCard) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deal.productName,
                    style: TextStyle(
                      fontSize: isSmallCard ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      decoration: isExpired ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            
            // Prices - Responsive sizes
            Row(
              children: [
                Text(
                  '${deal.originalPrice.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: isSmallCard ? 12 : 14,
                    color: textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${deal.flashPrice.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: isSmallCard ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Store Info - Simplified for small cards
            if (!isSmallCard)
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${deal.retailer} - ${deal.storeName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Distance display
                  if (locationProvider.hasLocation)
                    _buildDistanceChip(deal),
                ],
              ),

            // Quick Actions - Hide on very small cards
            if (!isSmallCard) ...[
              SizedBox(height: spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    color: textSecondary,
                    onPressed: () => _shareDeal(deal),
                    tooltip: 'Teilen',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 18),
                    color: textSecondary,
                    onPressed: () => _favoriteDeal(deal),
                    tooltip: 'Favorit',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.directions, size: 18),
                    color: textSecondary,
                    onPressed: () => _navigateToDeal(deal),
                    tooltip: 'Navigation',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],

            SizedBox(height: spacing),

            // Action Button - Responsive height
            SizedBox(
              height: isSmallCard ? 32 : 36,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : () => _showLageplanModal(context, deal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired ? Colors.grey : primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallCard ? 4 : 8),
                ),
                child: Text(
                  isExpired ? 'Abgelaufen' : 'Details',
                  style: TextStyle(fontSize: isSmallCard ? 12 : 14),
                ),
              ),
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

  String _formatTimeShort(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min';
    } else {
      return '${secs}s';
    }
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

  // Task 16: Upgrade Dialog
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade zu Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mit Premium erhalten Sie:'),
            const SizedBox(height: 8),
            const Text('• Flash Deals von ALLEN Händlern'),
            const Text('• Preisvergleich zwischen allen Händlern'),
            const Text('• Mehrere Händler gleichzeitig'),
            const Text('• Karten-Features mit allen Filialen'),
            const SizedBox(height: 16),
            Text(
              context.read<UserProvider>().getUpgradePrompt('flashdeals'),
              style: TextStyle(fontStyle: FontStyle.italic, color: textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Später'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserProvider>().enableDemoMode();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium aktiviert! Alle Flash Deals freigeschaltet.'),
                  backgroundColor: Color(0xFF2E8B57),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text('Premium aktivieren'),
          ),
        ],
      ),
    );
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
