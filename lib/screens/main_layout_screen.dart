import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_app_bar.dart';

import 'offers_screen.dart';
import 'map_screen.dart';
import 'flash_deals_screen.dart';

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
      appBar: const CustomAppBar(),
      body: isDesktop 
          ? _buildDesktopLayout()
          : _buildMobileTabletLayout(),
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
    return const MapScreen();
  }
  
  Widget _buildFlashDealsPanel() {
    return const FlashDealsScreen();
  }

}
