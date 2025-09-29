import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

import 'offers_screen.dart';
import 'map_screen.dart';
import 'flash_deals_screen.dart';
import 'settings_screen.dart';

import '../providers/location_provider.dart';
import '../providers/app_provider.dart';
import '../providers/user_provider.dart';


/// MainLayoutScreen - Haupt-Navigation für FlashFeed
/// 
/// UI-Spezifikationen:
/// - Header: 64px, #2E8B57 (SeaGreen)
/// - Tab-Navigation: 56px mit 3 Icons
/// - Responsive: Mobile (<768), Tablet (768-1024), Desktop (1024+)
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);  // Always start with Angebote
    
    // Task 7: Sync TabController with AppProvider
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (!_isInitialized) return;  // Prevent during init
      
      final appProvider = context.read<AppProvider>();
      final userProvider = context.read<UserProvider>();
      
      // Check Premium for Map Panel (index 1)
      if (!appProvider.canNavigateToPanel(_tabController.index, userProvider.isPremium)) {
        _tabController.index = appProvider.selectedPanelIndex;  // Revert
        _showPremiumDialog();
      } else {
        appProvider.navigateToPanel(_tabController.index);
      }
    });
    
    // LocationProvider initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
      _syncWithAppProvider();
    });
  }
  
  void _initializeProviders() async {
    final locationProvider = context.read<LocationProvider>();
    
    // Register LocationProvider callbacks
    locationProvider.registerLocationChangeCallback(() {
      // Retailers already registered via ProviderInitializer
      debugPrint('Location updated');
    });
    
    // Ensure location data is available
    await locationProvider.ensureLocationData();
  }
  
  // Task 7: Sync TabController with AppProvider
  void _syncWithAppProvider() {
    final appProvider = context.read<AppProvider>();
    _tabController.index = appProvider.selectedPanelIndex;
    _isInitialized = true;
  }
  
  // Task 7: Show Premium dialog for locked panels
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text('Die Kartenansicht ist nur für Premium-Nutzer verfügbar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Activate Premium via Demo
              context.read<UserProvider>().activatePremiumDemo();
              // Navigate to Map after activation
              context.read<AppProvider>().navigateToPanel(1);
              _tabController.index = 1;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Demo'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;  // Desktop mode for screens >= 1200px

    // Task 7: Listen to AppProvider for external navigation
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Sync TabController if AppProvider changed externally
        if (_isInitialized && _tabController.index != appProvider.selectedPanelIndex) {
          _tabController.index = appProvider.selectedPanelIndex;
        }
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: const CustomAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileTabletLayout(),
        );
      },
    );
  }

  
  Widget _buildMobileTabletLayout() {
    return Column(
      children: [
        // Tab Bar (56px)
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[600]!.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryRed,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey[600],
            tabs: [
              _buildTab(Icons.shopping_cart, 'Angebote'),
              _buildTab(Icons.map, 'Karte'),
              _buildTab(Icons.flash_on, 'Flash'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOffersPanel(),
              _buildMapPanel(),
              _buildFlashDealsPanel(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopLayout() {
    // Desktop: 3-column layout
    return Row(
      children: [
        // Panel 1: Angebote
        Expanded(
          flex: 3,
          child: _buildPanelContainer(_buildOffersPanel(), 'Angebote'),
        ),

        // Panel 2: Karte (larger in center)
        Expanded(
          flex: 4,
          child: _buildPanelContainer(_buildMapPanel(), 'Karte'),
        ),

        // Panel 3: Flash Deals
        Expanded(
          flex: 3,
          child: _buildPanelContainer(_buildFlashDealsPanel(), 'Flash Deals'),
        ),
      ],
    );
  }
  
  Widget _buildPanelContainer(Widget child, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                ? AppTheme.primaryGreen.withAlpha(40)
                : AppTheme.primaryGreen.withAlpha(25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),

          // Panel Content
          Expanded(child: child),
        ],
      ),
    );
  }
  
  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  // Placeholder Panels - will be replaced with actual screens
  Widget _buildOffersPanel() {
    return const OffersScreen();
  }
  
  Widget _buildMapPanel() {
    return const MapScreen();
  }
  
  Widget _buildFlashDealsPanel() {
    return const FlashDealsScreen();
  }

}

class _SettingsOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final userProvider = context.watch<UserProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dark Mode Toggle
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: appProvider.isDarkMode,
              onChanged: (value) {
                appProvider.setDarkMode(value);
                Navigator.pop(context);
              },
            ),
          ),

          // PLZ Input mit sichtbaren Buttons
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('PLZ-Filter'),
            subtitle: Text(
              locationProvider.postalCode ??
              locationProvider.userPLZ ??
              'Nicht gesetzt'
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PLZ ändern Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPLZDialog(context);
                  },
                  child: const Text('Ändern'),
                ),
                // PLZ löschen Button (nur wenn PLZ gesetzt)
                if (locationProvider.postalCode != null || locationProvider.userPLZ != null)
                  TextButton(
                    onPressed: () {
                      locationProvider.clearLocation();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PLZ-Filter entfernt'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Löschen'),
                  ),
              ],
            ),
          ),

          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Einstellungen'),
            subtitle: const Text('App-Konfiguration & Demo-Zugriff'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),

          // Premium Toggle
          if (!userProvider.isPremium)
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Premium aktivieren'),
              subtitle: const Text('Alle Features freischalten'),
              onTap: () {
                userProvider.enableDemoMode();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium aktiviert!'),
                    backgroundColor: Color(0xFF2E8B57),
                  ),
                );
              },
            ),

          const Divider(),

          // Info Section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('FlashFeed MVP'),
            subtitle: const Text('Version 1.0.0 - Prototype'),
          ),
        ],
      ),
    );
  }

  void _showPLZDialog(BuildContext context) {
    final controller = TextEditingController();
    final locationProvider = context.read<LocationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PLZ eingeben'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 5,
          decoration: const InputDecoration(
            hintText: 'z.B. 10115',
            labelText: 'Postleitzahl',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 5) {
                locationProvider.setUserPLZ(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
