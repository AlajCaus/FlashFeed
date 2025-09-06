import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// FlashFeed Providers
import 'providers/app_provider.dart';
import 'providers/offers_provider.dart';
import 'providers/user_provider.dart';
import 'providers/location_provider.dart';
import 'providers/flash_deals_provider.dart';

// FlashFeed Services
import 'services/mock_data_service.dart';

// FlashFeed Screens
import 'screens/main_layout_screen.dart';

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
  
  runApp(const FlashFeedApp());
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
          create: (context) => OffersProvider.mock(), // Mock repository for MVP
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
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'FlashFeed Prototype',
            debugShowCheckedModeBanner: false,
            
            // Theme based on app provider dark mode setting
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
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
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E8B57), // FlashFeed Primary Green
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF333333),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E8B57), // FlashFeed Primary Green
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
