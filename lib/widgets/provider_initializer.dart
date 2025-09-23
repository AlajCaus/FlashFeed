import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/offers_provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/user_provider.dart';
import '../services/demo_service.dart';

/// Task 5c.5 & Task 16: Provider Initializer Widget
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

    // Task 21: Check for Demo Mode and auto-login as Premium
    final demoService = DemoService();
    if (demoService.isDemoMode) {
      // Auto-login as Premium user for demo
      userProvider.loginUser(
        'demo-user',
        'Demo User',
        tier: UserTier.premium,
      );
      userProvider.upgradeToPremium();
    } else {
      // Default Demo setup: Free user with only EDEKA
      userProvider.loginUser(
        'demo-user',
        'Demo User',
        tier: UserTier.free,
      );
      // selectedRetailers is already set to ['EDEKA'] by default
    }

    // Register cross-provider callbacks for location-based updates
    // This sets up the communication channels between providers
    offersProvider.registerWithLocationProvider(locationProvider);
    flashDealsProvider.registerWithLocationProvider(locationProvider);
    retailersProvider.registerWithLocationProvider(locationProvider);

    // Register OffersProvider with UserProvider for demo retailer filtering
    offersProvider.registerWithUserProvider(userProvider);

    // Task 16: Register UserProvider with all providers for freemium enforcement
    userProvider.registerWithProviders(
      offersProvider: offersProvider,
      flashDealsProvider: flashDealsProvider,
      retailersProvider: retailersProvider,
    );


    // Trigger initial location detection
    // This will cascade updates to all registered providers
    locationProvider.ensureLocationData().then((success) {
      if (success) {
      } else {
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
