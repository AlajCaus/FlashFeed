import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// FlashFeed Theme
import 'theme/app_theme.dart';

// FlashFeed Providers
import 'providers/app_provider.dart';
import 'providers/offers_provider.dart';
import 'providers/user_provider.dart';
import 'providers/location_provider.dart';
import 'providers/flash_deals_provider.dart';
import 'providers/retailers_provider.dart';

// FlashFeed Services
import 'services/mock_data_service.dart';
import 'services/demo_service.dart';

// FlashFeed Repositories
import 'repositories/mock_retailers_repository.dart';

// FlashFeed Screens
import 'screens/main_layout_screen.dart';

// FlashFeed Widgets
import 'widgets/provider_initializer.dart';

/*
 * FlashFeed Main App Entry Point
 * 
 * ARCHITEKTUR-ENTSCHEIDUNG: Provider Pattern (nicht BLoC)
 * 
 * BEGRÜNDUNG:
 * - Schnellere MVP-Entwicklung (3-Wochen-Timeline)
 * - Einfachere Lernkurve für Prototyp
 * - Repository Pattern bleibt migration-ready
 * 
 * GEPLANTE MIGRATION:
 * - Post-MVP: Provider → BLoC Migration
 * - Repository Interfaces bleiben unverändert
 * - Service Layer wird architektur-agnostisch designed
 */

// Global MockDataService instance for MVP
late final MockDataService mockDataService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MockDataService for all providers
  mockDataService = MockDataService();
  await mockDataService.initializeMockData();

  // Handle URL parameters for demo mode (Web only)
  _handleDemoMode();

  runApp(const FlashFeedApp());
}

// Parse URL parameters and activate demo mode if needed
void _handleDemoMode() {
  if (kIsWeb) {
    // Get URL parameters from browser
    final uri = Uri.base;
    final params = uri.queryParameters;

    if (params.isNotEmpty) {
      final demoService = DemoService();
      demoService.handleUrlParameters(params);

      if (kDebugMode) {
        debugPrint('URL Parameters: $params');
        debugPrint('Demo Mode: ${demoService.isDemoMode}');
      }
    }
  }
}

class FlashFeedApp extends StatelessWidget {
  const FlashFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core App Provider - Navigation & Global State
        ChangeNotifierProvider<AppProvider>(
          create: (context) => AppProvider(),
        ),
        
        // Offers Provider - Angebote & Preisvergleich
        ChangeNotifierProvider<OffersProvider>(
          create: (context) => OffersProvider.mock(testService: mockDataService), // Use global mockDataService
        ),
        
        // Flash Deals Provider - Echtzeit Rabatte
        ChangeNotifierProvider<FlashDealsProvider>(
          create: (context) => FlashDealsProvider(),
        ),
        
        // User Provider - Freemium Logic & Settings
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
        
        // Location Provider - GPS & Regional Filtering
        ChangeNotifierProvider<LocationProvider>(
          create: (context) => LocationProvider(),
        ),
        
        // Retailers Provider - Händler-Verfügbarkeit & PLZ-Filterung
        ChangeNotifierProvider<RetailersProvider>(
          create: (context) => RetailersProvider(
            repository: MockRetailersRepository(testService: mockDataService),
            mockDataService: mockDataService,
          ),
        ),
      ],
      child: ProviderInitializer(
        child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'FlashFeed Prototype',
            debugShowCheckedModeBanner: false,
            
            // Use FlashFeed custom themes
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Main app screen
            home: const MainLayoutScreen(),
            
            // Error handling for provider errors
            builder: (context, widget) {
              if (appProvider.errorMessage != null) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Ein Fehler ist aufgetreten:',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appProvider.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => appProvider.clearError(),
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return widget ?? const SizedBox();
            },
          );
        },
        ),
      ),
    );
  }

}
