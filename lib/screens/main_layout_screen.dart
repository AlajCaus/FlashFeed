import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/offers_provider.dart';
import '../providers/user_provider.dart';
import '../providers/location_provider.dart';

/*
 * FlashFeed Main Layout Screen
 * 
 * ARCHITEKTUR: Provider Pattern (statt BLoC)
 * 
 * AUFBAU:
 * - Drei-Panel Navigation: Angebote | Karte | Flash Deals
 * - Provider-basierte State-Verwaltung
 * - Consumer-Widgets für reaktive UI-Updates
 * 
 * MIGRATION-READY: 
 * - UI-Logic ist Provider-agnostisch
 * - Einfache Umstellung auf BLoC später möglich
 */

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() async {
    final appProvider = context.read<AppProvider>();
    final offersProvider = context.read<OffersProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    try {
      // Set loading state
      appProvider.setLoading(true);
      
      // Initialize location (with permission request)
      await locationProvider.requestLocationPermission();
      
      // Load initial offers data
      await offersProvider.loadOffers();
      
      // Mark first launch as complete
      if (appProvider.isFirstLaunch) {
        appProvider.completeFirstLaunch();
      }
      
    } catch (e) {
      appProvider.setError('Fehler beim Laden der App: ${e.toString()}');
    } finally {
      appProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Header
          _buildAppHeader(),
          
          // Main Content Area
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                if (appProvider.isLoading) {
                  return _buildLoadingScreen();
                }
                
                return _buildMainContent();
              },
            ),
          ),
          
          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // App Logo/Title
              const Text(
                '⚡ FlashFeed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B57), // FlashFeed Green
                ),
              ),
              
              const Spacer(),
              
              // User Status & Settings
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return Row(
                    children: [
                      // Premium Status
                      if (userProvider.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Settings Button
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _showSettingsDialog(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        switch (appProvider.currentPanel) {
          case AppPanel.offers:
            return _buildOffersPanel();
          case AppPanel.map:
            return _buildMapPanel();
          case AppPanel.flashDeals:
            return _buildFlashDealsPanel();
        }
      },
    );
  }

  Widget _buildOffersPanel() {
    return Consumer<OffersProvider>(
      builder: (context, offersProvider, child) {
        if (offersProvider.isLoading) {
          return _buildLoadingWidget('Lade Angebote...');
        }
        
        if (offersProvider.errorMessage != null) {
          return _buildErrorWidget(
            offersProvider.errorMessage!,
            () => offersProvider.refresh(),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Aktuelle Angebote',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              const SizedBox(height: 8),
              
              // Stats
              Text(
                '${offersProvider.filteredOffersCount} von ${offersProvider.totalOffersCount} Angeboten',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => offersProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aktualisieren'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showFilterDialog(),
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Offers List
              Expanded(
                child: offersProvider.offers.isEmpty
                    ? _buildEmptyState('Keine Angebote gefunden')
                    : ListView.builder(
                        itemCount: offersProvider.offers.length,
                        itemBuilder: (context, index) {
                          final offer = offersProvider.offers[index];
                          return _buildOfferCard(offer);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Karten-Ansicht',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Karte wird in Task 6-8 implementiert',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDealsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Flash Deals',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              // Professor Demo Button
              ElevatedButton.icon(
                onPressed: () => _triggerProfessorDemo(),
                icon: const Icon(Icons.flash_on),
                label: const Text('Professor Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Flash Deals werden in Task 5 + Task 14-15 implementiert',
                      style: TextStyle(color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return BottomNavigationBar(
          currentIndex: appProvider.currentPanel.index,
          onTap: (index) {
            final panel = AppPanel.values[index];
            appProvider.switchToPanel(panel);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer),
              label: 'Angebote',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Karte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on),
              label: 'Flash Deals',
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('FlashFeed wird geladen...'),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(dynamic offer) {
    // Placeholder for actual offer card
    // Will be implemented when Offer model is available
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.local_offer, color: Colors.green),
        title: Text('Produkt-Name'), // offer.productName
        subtitle: Text('Händler • Adresse'), // offer.retailer + offer.storeAddress
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '€0.00', // offer.price
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Ersparnis: €0.00', // offer.savings
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einstellungen'),
        content: const Text('Einstellungen werden in Task 7-8 implementiert'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: const Text('Filter werden in Task 9-10 implementiert'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _triggerProfessorDemo() {
    final appProvider = context.read<AppProvider>();
    final userProvider = context.read<UserProvider>();
    
    // Enable demo mode
    userProvider.enableDemoMode();
    appProvider.triggerProfessorDemo();
    
    // Show demo message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎓 Professor Demo aktiviert! Premium-Features freigeschaltet.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
