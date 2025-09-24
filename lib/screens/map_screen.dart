import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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

  // Händler-Farben (Fallback wenn kein Logo vorhanden)
  static const Map<String, Color> retailerColors = {
    'EDEKA': Color(0xFF005CA9),
    'REWE': Color(0xFFCC071E),
    'ALDI': Color(0xFF00549F),
    'ALDI SÜD': Color(0xFF00549F),
    'LIDL': Color(0xFF0050AA),
    'NETTO': Color(0xFFFFD100),
    'netto scottie': Color(0xFFFFD100),
    'Penny': Color(0xFFD91F26),
    'Kaufland': Color(0xFFE10915),
    'KAUFLAND': Color(0xFFE10915),
    'nahkauf': Color(0xFF004B93),
    'Metro': Color(0xFF003D7D),
    'Norma': Color(0xFFE30613),
    'dm': Color(0xFF1A4C8B),
    'Rossmann': Color(0xFFE30613),
    'Müller': Color(0xFFFF6900),
  };

  // Händler-Logos Mapping
  static const Map<String, String> retailerLogos = {
    'EDEKA': 'assets/images/retailers/edeka.jpg',
    'Edeka': 'assets/images/retailers/edeka.jpg',
    'edeka': 'assets/images/retailers/edeka.jpg',
    'REWE': 'assets/images/retailers/rewe.png',
    'ALDI': 'assets/images/retailers/Aldi.png',
    'ALDI SÜD': 'assets/images/retailers/Aldi_Sued.jpg',
    'LIDL': 'assets/images/retailers/lidl.png',
    'NETTO': 'assets/images/retailers/netto.png',
    'netto scottie': 'assets/images/retailers/Scottie.png',
    'Penny': 'assets/images/retailers/penny.png',
    'PENNY': 'assets/images/retailers/penny.png',
    'Kaufland': 'assets/images/retailers/kaufland.png',
    'KAUFLAND': 'assets/images/retailers/kaufland.png',
    'nahkauf': 'assets/images/retailers/nahkauf.png',
    'Norma': 'assets/images/retailers/norma.png',
    'NORMA': 'assets/images/retailers/norma.png',
    'Globus': 'assets/images/retailers/globus.png',
    'BioCompany': 'assets/images/retailers/biocompany.png',
    'Marktkauf': 'assets/images/retailers/marktkauf.png',
    'real': 'assets/images/retailers/real.png',
  };

  double _radiusKm = 10.0;
  Store? _selectedStore;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  double _currentZoom = 13.0;

  // Default center (Berlin Mitte)
  static const LatLng _defaultCenter = LatLng(52.520008, 13.404954);

  @override
  void initState() {
    super.initState();
    // Ensure location data is loaded and initialize stores
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final locationProvider = context.read<LocationProvider>();
      final retailersProvider = context.read<RetailersProvider>();

      // Ensure location data is loaded
      await locationProvider.ensureLocationData();

      if (!mounted) return;

      // Initialize all stores for the map with a small delay to avoid build conflicts
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Initialize all stores for the map
      await retailersProvider.initializeStores();
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
        SizedBox(
          height: screenHeight - 120,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: _currentZoom,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                scrollWheelVelocity: 0.005,
              ),
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onPositionChanged: (position, hasGesture) {
                setState(() {
                  _currentZoom = position.zoom;
                });
                            },
              onTap: (_, _) {
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

              // Radius Circle around center point
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: hasLocation
                        ? LatLng(locationProvider.latitude!, locationProvider.longitude!)
                        : _defaultCenter,
                    radius: _radiusKm * 1000, // Convert km to meters
                    useRadiusInMeter: true,
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderColor: primaryBlue.withValues(alpha: 0.3),
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
                          color: userLocationColor.withValues(alpha: 0.2),
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

        // Zoom Controls (Right side, above GPS button)
        if (kIsWeb || !ResponsiveHelper.isMobile(context))
          Positioned(
            right: 16,
            bottom: 160,
            child: _buildZoomControls(),
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

    // Debug output
    debugPrint('🗺️ Building store markers:');
    debugPrint('  - Has location: $hasLocation');
    debugPrint('  - Radius: $_radiusKm km');
    debugPrint('  - Total stores available: ${retailersProvider.allStores.length}');

    // Get stores near location if available, otherwise use all stores
    List<Store> stores;
    if (hasLocation) {
      // Filter stores by radius from user location
      stores = retailersProvider.allStores.where((store) {
        final distance = _calculateDistance(
          locationProvider.latitude!,
          locationProvider.longitude!,
          store.latitude,
          store.longitude,
        );
        return distance <= _radiusKm;
      }).toList();
      debugPrint('  - Stores in radius: ${stores.length}');
    } else {
      // No location available - show stores around default center (Berlin)
      stores = retailersProvider.allStores.where((store) {
        final distance = _calculateDistance(
          _defaultCenter.latitude,
          _defaultCenter.longitude,
          store.latitude,
          store.longitude,
        );
        return distance <= _radiusKm;
      }).toList();
      debugPrint('  - Stores in radius (from Berlin center): ${stores.length}');
    }

    // Create markers for each store
    for (final store in stores) {
      markers.add(
        Marker(
          point: LatLng(store.latitude, store.longitude),
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

  Widget _buildZoomControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Zoom In Button
              Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  onTap: _isMapReady
                      ? () {
                          final newZoom = (_currentZoom + 1).clamp(10.0, 18.0);
                          _mapController.move(
                            _mapController.camera.center,
                            newZoom,
                          );
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      color: _currentZoom < 18.0 ? Colors.black87 : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
              // Zoom Out Button
              Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  onTap: _isMapReady
                      ? () {
                          final newZoom = (_currentZoom - 1).clamp(10.0, 18.0);
                          _mapController.move(
                            _mapController.camera.center,
                            newZoom,
                          );
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove,
                      color: _currentZoom > 10.0 ? Colors.black87 : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Optional: Zoom level indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            '${_currentZoom.toStringAsFixed(1)}x',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGPSButton(LocationProvider locationProvider) {
    final isGPSLocation = locationProvider.currentLocationSource == LocationSource.gps;

    return FloatingActionButton(
      backgroundColor: isGPSLocation ? primaryGreen : primaryBlue,
      onPressed: () async {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('GPS-Standort wird ermittelt...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        try {
          // Force GPS location request
          final success = await locationProvider.getCurrentLocation();

          if (success && locationProvider.hasLocation && _isMapReady) {
            // Move map to GPS location
            _mapController.move(
              LatLng(locationProvider.latitude!, locationProvider.longitude!),
              15.0,
            );

            // Reload stores for new location
            await context.read<RetailersProvider>().initializeStores();

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 GPS-Standort gefunden'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Try fallback location methods
            final fallbackSuccess = await locationProvider.ensureLocationData(forceRefresh: true);

            if (fallbackSuccess && locationProvider.hasLocation && _isMapReady) {
              _mapController.move(
                LatLng(locationProvider.latitude!, locationProvider.longitude!),
                14.0,
              );

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📍 Standort verwendet: ${locationProvider.userPLZ ?? "Berlin"}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ GPS nicht verfügbar. Bitte Standort-Berechtigung prüfen.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Icon(
        isGPSLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
        color: Colors.white,
      ),
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
    final logoPath = retailerLogos[store.retailerName];
    final color = retailerColors[store.retailerName] ?? primaryGreen;

    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: logoPath != null
              ? Image.asset(
                  logoPath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback wenn Logo nicht geladen werden kann
                    return Container(
                      color: color,
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
                    );
                  },
                )
              : Container(
                  color: color,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: retailerLogos[store.retailerName] != null
                      ? Image.asset(
                          retailerLogos[store.retailerName]!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: retailerColors[store.retailerName] ?? primaryGreen,
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
                            );
                          },
                        )
                      : Container(
                          color: retailerColors[store.retailerName] ?? primaryGreen,
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: retailerLogos[store.retailerName] != null
                      ? Image.asset(
                          retailerLogos[store.retailerName]!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: retailerColors[store.retailerName] ?? primaryGreen,
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
                            );
                          },
                        )
                      : Container(
                          color: retailerColors[store.retailerName] ?? primaryGreen,
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
                ),
              ),
              SizedBox(width: ResponsiveHelper.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          ...[
          SizedBox(height: ResponsiveHelper.space3),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                store.phoneNumber,
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
    final lat = store.latitude;
    final lng = store.longitude;
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