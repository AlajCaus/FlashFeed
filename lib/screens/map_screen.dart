import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/retailers_provider.dart';
import '../providers/location_provider.dart';
import '../models/models.dart';
import '../utils/responsive_helper.dart';

/// MapScreen - Panel 2: Karten-Ansicht mit OpenStreetMap
///
/// UI-Spezifikationen:
/// - Map-Container: calc(100vh - 120px)
/// - Store-Pins: 40x40px Custom Markers
/// - Radius-Filter: 1-20km Slider
/// - GPS-Integration für Standort
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
  static const Color userLocationColor = Color(0xFF4285F4);

  // Händler-Farben
  static const Map<String, Color> retailerColors = {
    'EDEKA': Color(0xFF005CA9),
    'REWE': Color(0xFFCC071E),
    'ALDI': Color(0xFF00549F),
    'LIDL': Color(0xFF0050AA),
    'Netto': Color(0xFFFFD100),
    'Penny': Color(0xFFD91F26),
    'Kaufland': Color(0xFFE10915),
    'Real': Color(0xFF004B93),
    'Metro': Color(0xFF003D7D),
    'Norma': Color(0xFFE30613),
    'dm': Color(0xFF1A4C8B),
    'Rossmann': Color(0xFFE30613),
    'Müller': Color(0xFFFF6900),
  };

  double _radiusKm = 10.0;
  Store? _selectedStore;
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Default center (Berlin Mitte)
  static const LatLng _defaultCenter = LatLng(52.520008, 13.404954);

  @override
  void initState() {
    super.initState();
    // Ensure location data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().ensureLocationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final retailersProvider = context.watch<RetailersProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    // Get current location or use default
    final hasLocation = locationProvider.hasLocation;
    final mapCenter = hasLocation
        ? LatLng(locationProvider.latitude!, locationProvider.longitude!)
        : _defaultCenter;

    return Stack(
      children: [
        // OpenStreetMap
        Container(
          height: screenHeight - 120,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onTap: (_, __) {
                // Deselect store when tapping on map
                setState(() {
                  _selectedStore = null;
                });
              },
            ),
            children: [
              // Map Tiles from OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flashfeed.app',
                maxZoom: 18,
              ),

              // Radius Circle around user location
              if (hasLocation)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(locationProvider.latitude!, locationProvider.longitude!),
                      radius: _radiusKm * 1000, // Convert km to meters
                      useRadiusInMeter: true,
                      color: primaryBlue.withOpacity(0.1),
                      borderColor: primaryBlue.withOpacity(0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Store Markers
              MarkerLayer(
                markers: _buildStoreMarkers(retailersProvider, locationProvider),
              ),

              // User Location Marker
              if (hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(locationProvider.latitude!, locationProvider.longitude!),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: userLocationColor.withOpacity(0.2),
                          border: Border.all(
                            color: userLocationColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: userLocationColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
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

  List<Marker> _buildStoreMarkers(
    RetailersProvider retailersProvider,
    LocationProvider locationProvider,
  ) {
    final markers = <Marker>[];
    final hasLocation = locationProvider.hasLocation;

    // Get stores near location if available, otherwise use all stores
    List<Store> stores;
    if (hasLocation) {
      // Use searchStores with location filter
      stores = retailersProvider.allStores.where((store) {
        if (store.latitude == null || store.longitude == null) return false;
        final distance = _calculateDistance(
          locationProvider.latitude!,
          locationProvider.longitude!,
          store.latitude!,
          store.longitude!,
        );
        return distance <= _radiusKm;
      }).toList();
    } else {
      // Use default stores for Berlin area
      stores = retailersProvider.allStores
          .where((store) => store.city.toLowerCase().contains('berlin'))
          .take(20) // Limit to 20 stores for performance
          .toList();
    }

    // Create markers for each store
    for (final store in stores) {
      if (store.latitude != null && store.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(store.latitude!, store.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStore = store;
                });
              },
              child: _buildStorePin(store),
            ),
          ),
        );
      }
    }

    return markers;
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
        // Request location and center map
        await locationProvider.ensureLocationData();

        if (locationProvider.hasLocation && _isMapReady) {
          _mapController.move(
            LatLng(locationProvider.latitude!, locationProvider.longitude!),
            14.0,
          );
        }
      },
      child: const Icon(Icons.my_location, color: Colors.white),
    );
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Widget _buildStorePin(Store store) {
    final isSelected = _selectedStore?.id == store.id;
    final color = retailerColors[store.retailerName] ?? primaryGreen;

    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
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
    );
  }

  Widget _buildStoreDetails(Store store) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getCardPadding(context);

    // Mobile: Full-screen bottom sheet, Desktop: Compact modal
    if (isMobile) {
      // Show full-screen modal for mobile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) => _buildStoreDetailsContent(store, padding),
          ),
        ).then((_) {
          setState(() {
            _selectedStore = null;
          });
        });
      });
      return const SizedBox.shrink();
    }

    // Desktop: Compact bottom panel
    return Container(
      width: ResponsiveHelper.getDialogWidth(context),
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.space4),
      padding: padding,
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
                      store.name ?? store.retailerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${store.street}, ${store.zipCode} ${store.city}',
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
                  onPressed: () => _openNavigation(store),
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

  Widget _buildStoreDetailsContent(Store store, EdgeInsets padding) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              SizedBox(width: ResponsiveHelper.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name ?? store.retailerName,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getTitleSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${store.street}, ${store.zipCode} ${store.city}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getBodySize(context),
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
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.space4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openNavigation(store),
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
          if (store.phoneNumber != null) ...[
            SizedBox(height: ResponsiveHelper.space3),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  store.phoneNumber!,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getBodySize(context),
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openNavigation(Store store) async {
    if (store.latitude == null || store.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Koordinaten für diese Filiale verfügbar'),
        ),
      );
      return;
    }

    final lat = store.latitude!;
    final lng = store.longitude!;
    final address = Uri.encodeComponent('${store.street}, ${store.zipCode} ${store.city}');

    // Different URLs for web and mobile
    String url;
    if (kIsWeb) {
      // For web, use Google Maps URL
      url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$address';
    } else {
      // For mobile, use geo: protocol
      url = 'geo:$lat,$lng?q=$lat,$lng($address)';
    }

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps web URL
      final fallbackUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
      );
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation konnte nicht gestartet werden'),
          ),
        );
      }
    }
  }
}