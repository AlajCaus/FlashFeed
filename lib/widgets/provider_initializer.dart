import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/offers_provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/user_provider.dart';
import '../services/demo_service.dart';

/// Provider Initializer Widget
/// Sets up cross-provider communication after all providers are created
/// Including UserProvider freemium enforcement
class ProviderInitializer extends StatefulWidget {
  final Widget child;

  const ProviderInitializer({
    super.key,
    required this.child,
  });

  @override
  State<ProviderInitializer> createState() => _ProviderInitializerState();
}

class _ProviderInitializerState extends State<ProviderInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize cross-provider communication only once
    if (!_initialized) {
      _initializeCrossProviderCommunication();
      _initialized = true;
    }
  }

  void _initializeCrossProviderCommunication() {
    // Get provider instances
    final locationProvider = context.read<LocationProvider>();
    final offersProvider = context.read<OffersProvider>();
    final flashDealsProvider = context.read<FlashDealsProvider>();
    final retailersProvider = context.read<RetailersProvider>();
    final userProvider = context.read<UserProvider>();

    // Check for Demo Mode and auto-login - defer to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final demoService = DemoService();
      if (demoService.isDemoMode) {
        debugPrint('🎬 Demo Mode detected - activating Premium features');
        // Auto-login as Premium user for demo
        userProvider.loginUser(
          'demo-user',
          'Demo User',
          tier: UserTier.premium,
        );
        userProvider.upgradeToPremium();
      } else {
        // Default Demo setup: Free user with only EDEKA
        debugPrint('🛒 Demo Mode: Starting as Free user with EDEKA');
        userProvider.loginUser(
          'demo-user',
          'Demo User',
          tier: UserTier.free,
        );
        // selectedRetailers is already set to ['EDEKA'] by default
      }
    });

    // Register cross-provider callbacks for location-based updates
    // This sets up the communication channels between providers
    offersProvider.registerWithLocationProvider(locationProvider);
    flashDealsProvider.registerWithLocationProvider(locationProvider);
    retailersProvider.registerWithLocationProvider(locationProvider);

    // Register OffersProvider with UserProvider for demo retailer filtering
    offersProvider.registerWithUserProvider(userProvider);

    // Register UserProvider with all providers for freemium enforcement
    userProvider.registerWithProviders(
      offersProvider: offersProvider,
      flashDealsProvider: flashDealsProvider,
      retailersProvider: retailersProvider,
    );

    debugPrint('✅ ProviderInitializer: Cross-provider communication established');
    debugPrint('✅ ProviderInitializer: UserProvider freemium enforcement registered');

    // Trigger initial location detection
    // This will cascade updates to all registered providers
    locationProvider.ensureLocationData().then((success) {
      if (success) {
        debugPrint('✅ ProviderInitializer: Initial location data loaded');
      } else {
        debugPrint('⚠️ ProviderInitializer: No location data available');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
