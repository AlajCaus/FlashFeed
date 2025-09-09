import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/retailers_provider.dart';
import '../providers/location_provider.dart';
import '../models/models.dart';

/// MapScreen - Panel 2: Karten-Ansicht
/// 
/// UI-Spezifikationen:
/// - Map-Container: calc(100vh - 120px)
/// - Store-Pins: 40x40px Teardrops
/// - Radius-Filter: 1-20km Slider
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryBlue = Color(0xFF1E90FF);
  static const Color textSecondary = Color(0xFF666666);
  
  // Händler-Farben
  static const Map<String, Color> retailerColors = {
    'EDEKA': Color(0xFF005CA9),
    'REWE': Color(0xFFCC071E),
    'ALDI': Color(0xFF00549F),
    'LIDL': Color(0xFF0050AA),
    'Netto': Color(0xFFFFD100),
  };
  
  double _radiusKm = 10.0;
  Store? _selectedStore;
  
  @override
  Widget build(BuildContext context) {
    final retailersProvider = context.watch<RetailersProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Stack(
      children: [
        // Map Placeholder
        Container(
          height: screenHeight - 120,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/map_placeholder.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 100, color: primaryBlue.withAlpha(102)),
                const SizedBox(height: 16),
                const Text(
                  'Google Maps Integration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'MVP: Karten-Platzhalter',
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          ),
        ),
        
        // Radius Filter (Top-Left)
        Positioned(
          top: 16,
          left: 16,
          child: _buildRadiusFilter(),
        ),
        
        // GPS Button (Bottom-Right)
        Positioned(
          bottom: 100,
          right: 16,
          child: _buildGPSButton(locationProvider),
        ),
        
        // Store Pins Overlay
        ..._buildStorePins(retailersProvider),
        
        // Selected Store Details
        if (_selectedStore != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStoreDetails(_selectedStore!),
          ),
      ],
    );
  }
  
  Widget _buildRadiusFilter() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Umkreis: ${_radiusKm.toStringAsFixed(0)} km',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: primaryGreen,
            inactiveColor: textSecondary.withAlpha(51),
            onChanged: (value) {
              setState(() {
                _radiusKm = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1km', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('20km', style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGPSButton(LocationProvider locationProvider) {
    return FloatingActionButton(
      backgroundColor: primaryBlue,
      onPressed: () async {
        // Use ensureLocationData instead
        await locationProvider.ensureLocationData();
      },
      child: const Icon(Icons.my_location, color: Colors.white),
    );
  }
  
  List<Widget> _buildStorePins(RetailersProvider retailersProvider) {
    final stores = <Widget>[];
    
    // Mock store positions for demonstration
    final mockStores = [
      Store(
        id: '1',
        chainId: 'edeka',
        retailerName: 'EDEKA',
        name: 'EDEKA Neukauf',
        street: 'Hauptstraße 1',
        city: 'Berlin',
        zipCode: '10115',
        latitude: 52.5200,
        longitude: 13.4050,
        phoneNumber: '030-1234567',
        openingHours: {
          'Montag': OpeningHours.standard(8, 0, 20, 0),
          'Dienstag': OpeningHours.standard(8, 0, 20, 0),
          'Mittwoch': OpeningHours.standard(8, 0, 20, 0),
          'Donnerstag': OpeningHours.standard(8, 0, 20, 0),
          'Freitag': OpeningHours.standard(8, 0, 20, 0),
          'Samstag': OpeningHours.standard(8, 0, 18, 0),
          'Sonntag': OpeningHours.closed(),
        },
      ),
      Store(
        id: '2',
        chainId: 'rewe',
        retailerName: 'REWE',
        name: 'REWE City',
        street: 'Marktplatz 5',
        city: 'Berlin',
        zipCode: '10178',
        latitude: 52.5170,
        longitude: 13.4100,
        phoneNumber: '030-2345678',
        openingHours: {
          'Montag': OpeningHours.standard(7, 0, 22, 0),
          'Dienstag': OpeningHours.standard(7, 0, 22, 0),
          'Mittwoch': OpeningHours.standard(7, 0, 22, 0),
          'Donnerstag': OpeningHours.standard(7, 0, 22, 0),
          'Freitag': OpeningHours.standard(7, 0, 22, 0),
          'Samstag': OpeningHours.standard(7, 0, 22, 0),
          'Sonntag': OpeningHours.standard(8, 0, 20, 0),
        },
      ),
      Store(
        id: '3',
        chainId: 'aldi',
        retailerName: 'ALDI',
        name: 'ALDI SÜD',
        street: 'Berliner Str. 10',
        city: 'Berlin',
        zipCode: '10243',
        latitude: 52.5150,
        longitude: 13.4200,
        phoneNumber: '030-3456789',
        openingHours: {
          'Montag': OpeningHours.standard(8, 0, 20, 0),
          'Dienstag': OpeningHours.standard(8, 0, 20, 0),
          'Mittwoch': OpeningHours.standard(8, 0, 20, 0),
          'Donnerstag': OpeningHours.standard(8, 0, 20, 0),
          'Freitag': OpeningHours.standard(8, 0, 20, 0),
          'Samstag': OpeningHours.standard(8, 0, 20, 0),
          'Sonntag': OpeningHours.closed(),
        },
      ),
    ];
    
    for (final store in mockStores) {
      stores.add(
        Positioned(
          // Mock positions on screen
          top: 200 + (mockStores.indexOf(store) * 80.0),
          left: 100 + (mockStores.indexOf(store) * 60.0),
          child: _buildStorePin(store),
        ),
      );
    }
    
    return stores;
  }
  
  Widget _buildStorePin(Store store) {
    final isSelected = _selectedStore?.id == store.id;
    final color = retailerColors[store.retailerName] ?? primaryGreen;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStore = isSelected ? null : store;
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(0),
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              store.retailerName.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStoreDetails(Store store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: retailerColors[store.retailerName] ?? primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    store.retailerName.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.retailerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      store.street,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedStore = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation wird in Phase 2 implementiert'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigation starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
