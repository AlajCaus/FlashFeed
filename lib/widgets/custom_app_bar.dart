import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/user_provider.dart';
import '../providers/location_provider.dart';
import '../utils/responsive_helper.dart';
import '../screens/settings_screen.dart';

/// CustomAppBar - Gemeinsame Top-Navigation
/// 
/// UI-Spezifikationen:
/// - Height: 64px
/// - Background: #2E8B57 (SeaGreen)
/// - Logo: 32x32px, Text: 20px bold
/// - Hamburger: 44x44px Touch-Area
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const Color primaryGreen = Color(0xFF2E8B57);
  
  const CustomAppBar({super.key});
  
  @override
  Size get preferredSize => const Size.fromHeight(64);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
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
                SizedBox(
                  width: ResponsiveHelper.isMobile(context) ? 40 : 48,
                  height: ResponsiveHelper.isMobile(context) ? 40 : 48,
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.space3),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FlashFeed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getHeadlineSize(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'made by Janina Böhmer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: ResponsiveHelper.getHeadlineSize(context) * 0.5,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Roboto',
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Hamburger Menu (44x44 touch area)
            InkWell(
              onTap: () => _showSettingsOverlay(context),
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
  
  void _showSettingsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SettingsOverlay(),
    );
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
