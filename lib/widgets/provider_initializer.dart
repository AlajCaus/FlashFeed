import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/offers_provider.dart';
import '../providers/flash_deals_provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/user_provider.dart';

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

    // Register cross-provider callbacks for location-based updates
    // This sets up the communication channels between providers
    offersProvider.registerWithLocationProvider(locationProvider);
    flashDealsProvider.registerWithLocationProvider(locationProvider);
    retailersProvider.registerWithLocationProvider(locationProvider);

    // Task 16: Register UserProvider with all providers for freemium enforcement
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
