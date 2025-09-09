import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'offers_screen.dart';

import '../providers/location_provider.dart';
import '../providers/app_provider.dart';
import '../providers/user_provider.dart';

import '../providers/flash_deals_provider.dart';
import '../providers/retailers_provider.dart';

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
  
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);

  static const Color textSecondary = Color(0xFF666666);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // LocationProvider initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // Header Panel (64px)
          _buildHeader(context),
          
          // Content Area with Tab Navigation
          Expanded(
            child: isDesktop 
                ? _buildDesktopLayout()
                : _buildMobileTabletLayout(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo + App Name
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Color(0xFF2E8B57),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'FlashFeed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            
            // Hamburger Menu (44x44 touch area for A11y)
            InkWell(
              onTap: () => _showSettingsMenu(context),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
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
                color: textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: primaryRed,
            indicatorWeight: 3,
            labelColor: primaryGreen,
            unselectedLabelColor: textSecondary,
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
          flex: 1,
          child: _buildPanelContainer(_buildOffersPanel(), 'Angebote'),
        ),
        
        // Panel 2: Karte (larger in center)
        Expanded(
          flex: 2,
          child: _buildPanelContainer(_buildMapPanel(), 'Karte'),
        ),
        
        // Panel 3: Flash Deals
        Expanded(
          flex: 1,
          child: _buildPanelContainer(_buildFlashDealsPanel(), 'Flash Deals'),
        ),
      ],
    );
  }
  
  Widget _buildPanelContainer(Widget child, String title) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: primaryGreen.withAlpha(25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E8B57),
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
    final retailersProvider = context.watch<RetailersProvider>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.map,
            size: 64,
            color: Color(0xFF1E90FF),
          ),
          const SizedBox(height: 16),
          Text(
            'Karte Panel',
            style: TextStyle(
              fontSize: 18,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${retailersProvider.availableRetailers.length} Händler in der Nähe',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlashDealsPanel() {
    final flashDealsProvider = context.watch<FlashDealsProvider>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flash_on,
            size: 64,
            color: Color(0xFFDC143C),
          ),
          const SizedBox(height: 16),
          Text(
            'Flash Deals Panel',
            style: TextStyle(
              fontSize: 18,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${flashDealsProvider.flashDeals.length} aktive Deals',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Professor Demo Button (prominent!)
          ElevatedButton(
            onPressed: () {
              // Generate demo deals for professor
              flashDealsProvider.loadFlashDeals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flash Deals generiert!'),
                  backgroundColor: Color(0xFF2E8B57),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('PROFESSOR DEMO'),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsMenu(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: context.read<AppProvider>().isDarkMode,
                onChanged: (value) {
                  context.read<AppProvider>().setDarkMode(value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('PLZ ändern'),
              subtitle: Text(locationProvider.postalCode ?? locationProvider.userPLZ ?? 'Nicht gesetzt'),
              onTap: () {
                Navigator.pop(context);
                _showPLZDialog(context);
              },
            ),
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
          ],
        ),
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
              backgroundColor: primaryGreen,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
