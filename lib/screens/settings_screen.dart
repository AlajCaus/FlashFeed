import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/qr_code_display.dart';
import '../services/demo_service.dart';

/// Einstellungen-Screen mit QR-Code für Demo-Zugriff
///
/// Features:
/// - QR-Code für Demo-URL
/// - Premium-Status-Verwaltung
/// - Standort-Einstellungen
/// - Theme-Auswahl
/// - Demo-Modus-Optionen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DemoService _demoService = DemoService();
  bool _showQrCode = false;
  bool _includePremium = true;
  bool _includeGuidedTour = false;
  bool _includeMetrics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final appProvider = context.watch<AppProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo-Zugriff Sektion
            _buildSectionHeader(context, '🔗 Demo-Zugriff'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.qr_code,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('QR-Code anzeigen'),
                    subtitle: const Text('Für schnellen Demo-Zugriff'),
                    trailing: Switch(
                      value: _showQrCode,
                      onChanged: (value) {
                        setState(() {
                          _showQrCode = value;
                        });
                      },
                    ),
                  ),
                  if (_showQrCode) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Demo-Optionen
                          Text(
                            'Demo-Optionen',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            title: const Text('Premium-Zugang'),
                            subtitle: const Text('Alle Features freischalten'),
                            value: _includePremium,
                            onChanged: (value) {
                              setState(() {
                                _includePremium = value ?? true;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text('Guided Tour'),
                            subtitle: const Text('Interaktive Feature-Tour'),
                            value: _includeGuidedTour,
                            onChanged: (value) {
                              setState(() {
                                _includeGuidedTour = value ?? false;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text('Performance-Metriken'),
                            subtitle: const Text('Zeige technische Details'),
                            value: _includeMetrics,
                            onChanged: (value) {
                              setState(() {
                                _includeMetrics = value ?? false;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                            dense: true,
                          ),
                          const SizedBox(height: 24),
                          // QR-Code Widget
                          QrCodeDisplay(
                            size: 250,
                            includePremium: _includePremium,
                            includeGuidedTour: _includeGuidedTour,
                            includeMetrics: _includeMetrics,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Benutzer-Account Sektion
            _buildSectionHeader(context, '👤 Account'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      userProvider.isPremium
                          ? Icons.workspace_premium
                          : Icons.person,
                      color: userProvider.isPremium
                          ? Colors.amber
                          : theme.colorScheme.secondary,
                    ),
                    title: Text(
                      userProvider.isPremium
                          ? 'Premium Account'
                          : 'Basis Account',
                    ),
                    subtitle: Text(
                      userProvider.isPremium
                          ? 'Alle Features freigeschaltet'
                          : '1 Händler verfügbar',
                    ),
                    trailing: userProvider.isPremium
                        ? null
                        : ElevatedButton(
                            onPressed: () {
                              userProvider.upgradeToPremium();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ Premium aktiviert!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Upgrade'),
                          ),
                  ),
                  if (!userProvider.isPremium) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.store, size: 20),
                      title: const Text('Ausgewählter Händler'),
                      subtitle: Text(
                        userProvider.selectedRetailer ?? 'Kein Händler ausgewählt',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Standort Sektion
            _buildSectionHeader(context, '📍 Standort'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: locationProvider.hasLocation
                          ? Colors.green
                          : theme.colorScheme.secondary,
                    ),
                    title: const Text('Standort-Dienste'),
                    subtitle: Text(
                      locationProvider.hasLocation
                          ? 'PLZ: ${locationProvider.postalCode ?? locationProvider.userPLZ ?? "Unbekannt"}'
                          : 'Nicht aktiviert',
                    ),
                    trailing: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              locationProvider.ensureLocationData();
                            },
                          ),
                  ),
                  if (locationProvider.hasLocation) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.map, size: 20),
                      title: const Text('Region'),
                      subtitle: Text(
                        locationProvider.userPLZ ?? 'Unbekannt',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // App-Einstellungen Sektion
            _buildSectionHeader(context, '⚙️ App-Einstellungen'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.color_lens),
                    title: const Text('Theme'),
                    subtitle: Text(
                      appProvider.isDarkMode ? 'Dunkel' : 'Hell',
                    ),
                    trailing: Switch(
                      value: appProvider.isDarkMode,
                      onChanged: (value) {
                        appProvider.setDarkMode(value);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Push-Benachrichtigungen'),
                    subtitle: const Text('Flash Deals & Angebote'),
                    trailing: Switch(
                      value: true, // TODO: Add notification setting to AppProvider
                      onChanged: (value) {
                        // TODO: Implement notification toggle
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Demo-Modus Status (wenn aktiv)
            if (_demoService.isDemoMode) ...[
              _buildSectionHeader(context, '🎬 Demo-Modus'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info,
                        color: Colors.orange,
                      ),
                      title: const Text('Demo-Modus aktiv'),
                      subtitle: Text(
                        'Session-Dauer: ${_demoService.getDemoSessionDuration()?.inMinutes ?? 0} Minuten',
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await _demoService.resetDemoData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Demo-Daten zurückgesetzt'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Daten zurücksetzen'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _demoService.deactivateDemoMode();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Demo-Modus beendet'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Demo beenden'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            // Info Sektion
            _buildSectionHeader(context, 'ℹ️ Info'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0 (Build 1)'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Datenschutz'),
                    onTap: () {
                      // Navigation zu Datenschutz
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('Nutzungsbedingungen'),
                    onTap: () {
                      // Navigation zu Nutzungsbedingungen
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}