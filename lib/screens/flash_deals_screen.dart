import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/user_provider.dart';
import '../models/models.dart';
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
/// - Demo-Button prominent
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(0xFFFAFAFA),
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
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

                // Demo Button für neue Deals
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Task 14: Enhanced Demo with notification
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
                        Text('LADE NEUE DEALS'),
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
                      // Discount - styled like offer cards (red text on white)
                      Text(
                        '-${deal.discountPercentage}%',
                        style: TextStyle(
                          color: primaryRed,
                          fontSize: isVerySmall ? 13 : 14,
                          fontWeight: FontWeight.bold,
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
                          color: Colors.black,
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
                          color: Colors.grey[600],
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
                      color: Colors.grey[800],
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

  Color _getTimerColor(int seconds) {
    if (seconds > 3600) return primaryGreen; // > 1 hour
    if (seconds > 1800) return secondaryOrange; // 30-60 min
    return primaryRed; // < 30 min
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
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
