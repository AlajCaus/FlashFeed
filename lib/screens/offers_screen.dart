import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offers_provider.dart';
import '../providers/user_provider.dart';
// Removed unused imports - these are used in child widgets
import '../models/models.dart' show Offer, OfferSortType;
import '../utils/responsive_helper.dart';
import '../widgets/offer_search_bar.dart';
import '../widgets/offer_filter_bar.dart';
import '../widgets/offer_comparison_card.dart';
import '../widgets/offer_detail_modal.dart';
import '../widgets/regional_availability_banner.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/skeleton_loader.dart';

/// OffersScreen - Panel 1: Angebotsvergleich (Enhanced Version)
/// 
/// Task 10 Implementation:
/// - Enhanced Produktkarten mit Preisvergleich
/// - Erweiterte Filter-Komponenten
/// - Such- und Sortierungsfunktionen
/// - Detaillierte Produktansicht
/// - Regionale Verfügbarkeits-UI
/// - Performance & Polish
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // UI State
  final ScrollController _scrollController = ScrollController();
  
  // Pagination State (Task 10.6)
  bool _loadingMore = false;
  
  @override
  void initState() {
    super.initState();
    // Load offers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    
    // Setup scroll listener for infinite scroll (Task 10.6)
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    final offersProvider = context.read<OffersProvider>();
    await offersProvider.loadOffers();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreOffers();
    }
  }
  
  Future<void> _loadMoreOffers() async {
    if (_loadingMore) return;
    
    setState(() => _loadingMore = true);
    
    final offersProvider = context.read<OffersProvider>();
    await offersProvider.loadMoreOffers();
    
    if (mounted) {
      setState(() => _loadingMore = false);
    }
  }
  
  void _onSearchChanged(String query) {
    final offersProvider = context.read<OffersProvider>();
    offersProvider.searchOffers(query);
  }
  
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFilterBar(
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortOptions(),
    );
  }

  // Task 16: Upgrade Dialog for Premium Features
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
            const Text('• Angebote von ALLEN Händlern gleichzeitig'),
            const Text('• Preisvergleich zwischen allen Händlern'),
            const Text('• Mehrere Händler-Filter'),
            const Text('• Karten-Features mit allen Filialen'),
            const SizedBox(height: 16),
            Text(
              context.read<UserProvider>().getUpgradePrompt('offers'),
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
                  content: Text('Premium aktiviert! Alle Angebote freigeschaltet.'),
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
  
  Widget _buildSortOptions() {
    final offersProvider = context.watch<OffersProvider>();
    final sortOptions = offersProvider.getSortOptions();
    
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sortieren nach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...sortOptions.map<Widget>((option) {
            final isSelected = option['status'] as bool;
            
            return ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: isSelected ? primaryGreen : textSecondary,
              ),
              title: Text(
                option['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryGreen,
              onTap: () {
                final sortType = option['value'] as OfferSortType;
                offersProvider.setSortType(sortType);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
  
  /// Build content area with proper error handling and loading states
  Widget _buildContentArea(OffersProvider offersProvider, UserProvider userProvider) {
    // Check for error state first
    if (offersProvider.errorMessage != null && !offersProvider.isLoading) {
      ErrorType errorType = ErrorType.general;

      // Determine error type based on message
      if (offersProvider.errorMessage!.toLowerCase().contains('netzwerk') ||
          offersProvider.errorMessage!.toLowerCase().contains('internet')) {
        errorType = ErrorType.network;
      } else if (offersProvider.errorMessage!.toLowerCase().contains('region')) {
        errorType = ErrorType.region;
      } else if (offersProvider.errorMessage!.toLowerCase().contains('keine')) {
        errorType = ErrorType.noData;
      }

      return ErrorStateWidget(
        errorMessage: offersProvider.errorMessage,
        errorType: errorType,
        onRetry: () async {
          await offersProvider.loadOffers();
        },
      );
    }

    // Check for loading state
    if (offersProvider.isLoading && offersProvider.offers.isEmpty) {
      // Initial loading - show skeleton
      return const SingleChildScrollView(
        child: OffersGridSkeleton(itemCount: 8),
      );
    }

    // Check for empty state
    if (!offersProvider.isLoading && offersProvider.offers.isEmpty) {
      return ErrorStateWidget(
        errorType: ErrorType.noData,
        errorMessage: 'Keine Angebote verfügbar. Bitte wählen Sie einen anderen Händler oder erweitern Sie Ihre Suche.',
        onRetry: () async {
          await offersProvider.loadOffers();
        },
      );
    }

    // Show content with optional refresh indicator
    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: () async {
        await offersProvider.loadOffers();
      },
      child: _buildOffersGrid(offersProvider, userProvider),
    );
  }

  Widget _buildOffersGrid(OffersProvider offersProvider, UserProvider userProvider) {
    var offers = offersProvider.displayedOffers;

    // Task 16: No limits for free users - they see ALL offers from their selected retailer
    // Premium users see offers from ALL retailers

    if (offers.isEmpty) {
      return Center(
        child: RegionalAvailabilityBanner(
          showAlternatives: false,
        ),
      );
    }

    // Group offers by product for price comparison
    final Map<String, List<Offer>> offersByProduct = {};
    for (final offer in offers) {
      final key = '${offer.productName}_${offer.flashFeedCategory}';
      offersByProduct.putIfAbsent(key, () => []).add(offer);
    }
    
    // Dynamic responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final bool isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    return RefreshIndicator(
      onRefresh: () => offersProvider.loadOffers(forceRefresh: true),
      color: primaryGreen,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Regional availability banner at top
          SliverToBoxAdapter(
            child: RegionalAvailabilityBanner(
              showAlternatives: true,
            ),
          ),
          
          // Featured offers section
          if (offersProvider.getFeaturedOffers().isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFeaturedSection(offersProvider),
            ),
          
          // Main offers grid - Responsive with minimum card width
          SliverPadding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isMobile ? 200 : (isTablet ? 220 : 250),
                childAspectRatio: isMobile ? 0.65 : 0.68,
                crossAxisSpacing: isMobile ? 8 : 12,
                mainAxisSpacing: isMobile ? 8 : 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= offers.length) {
                    return null;
                  }
                  
                  final offer = offers[index];
                  final comparableOffers = offersByProduct[
                    '${offer.productName}_${offer.flashFeedCategory}'
                  ]?.where((o) => o.id != offer.id).toList() ?? [];
                  
                  // Check if offer is locked (Freemium logic)
                  final isLocked = userProvider.isFree && 
                                  offersProvider.isOfferLocked(index);
                  
                  return OfferComparisonCard(
                    primaryOffer: offer,
                    comparableOffers: comparableOffers,
                    isLocked: isLocked,
                    onTap: () {
                      if (isLocked) {
                        _showPremiumDialog(context);
                      } else {
                        OfferDetailModal.show(
                          context,
                          offer,
                          comparableOffers: comparableOffers,
                        );
                      }
                    },
                  );
                },
                childCount: offers.length,
              ),
            ),
          ),
          
          // Loading indicator for pagination
          if (_loadingMore || offersProvider.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedSection(OffersProvider offersProvider) {
    final featuredOffers = offersProvider.getFeaturedOffers().take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star, color: secondaryOrange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Top Angebote',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${featuredOffers.length} Deals',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featuredOffers.length,
            itemBuilder: (context, index) {
              final offer = featuredOffers[index];

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: OfferComparisonCard(
                  primaryOffer: offer,
                  isLocked: false,
                  onTap: () {
                    OfferDetailModal.show(context, offer);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Dieses Angebot ist nur für Premium-Nutzer verfügbar. '
          'Aktivieren Sie Premium, um alle Angebote und Preisvergleiche zu sehen!',
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
                  content: Text('Premium aktiviert! Alle Features freigeschaltet.'),
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
  
  @override
  Widget build(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();
    final userProvider = context.watch<UserProvider>();
    final filterStats = {
      'filtered': offersProvider.filteredOffers.length,
      'total': offersProvider.totalOffers,
    };
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Search Bar with Filter Button (Task 10.3)
          OfferSearchBar(
            onSearchChanged: _onSearchChanged,
            onFilterTap: _showFilterModal,
          ),
          
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
                      userProvider.getRemainingLimitText('offers'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showUpgradeDialog(context),
                    child: const Text('Premium'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Statistics Bar
          if (offersProvider.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    '${filterStats['filtered']} von ${filterStats['total']} Angeboten',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => offersProvider.clearFilters(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Filter löschen'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          
          // Sort Options Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Sortierung:',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showSortOptions,
                  icon: Icon(
                    offersProvider.getSortOptions()
                        .firstWhere((o) => o['status'] == true)['icon'] as IconData,
                    size: 16,
                  ),
                  label: Text(
                    offersProvider.getSortOptions()
                        .firstWhere((o) => o['status'] == true)['label'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                  ),
                ),
                const Spacer(),
                if (userProvider.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: secondaryOrange.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: secondaryOrange),
                        const SizedBox(width: 4),
                        Text(
                          'Freemium',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Area with enhanced error handling and loading states
          Expanded(
            child: _buildContentArea(offersProvider, userProvider),
          ),
        ],
      ),
    );
  }
}
