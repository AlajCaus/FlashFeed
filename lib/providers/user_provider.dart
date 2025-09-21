// FlashFeed User Provider - Freemium Logic & Settings
// Verwaltet User-Einstellungen und Premium-Features
// Task 16: Cross-Provider Communication für Freemium-Limits

import 'package:flutter/material.dart';
import 'offers_provider.dart';
import 'flash_deals_provider.dart';
import 'retailers_provider.dart';

enum UserTier {
  free,       // Kostenloser User
  premium,    // Premium User
}

class UserProvider extends ChangeNotifier {
  // User State
  UserTier _userTier = UserTier.free;
  String? _userId;
  String? _userName;
  bool _isLoggedIn = false;

  // Freemium Limits & Usage
  static const int freeRetailersLimit = 1;      // Free User: 1 Händler
  static const int freeSearchesLimit = 999;     // Unbegrenzte Suchen
  static const int freeFlashDealsLimit = 999;   // Alle Flash Deals sichtbar
  
  int _offersViewed = 0;
  int _searchesToday = 0;
  int _flashDealsViewed = 0;
  DateTime? _lastResetDate;
  
  // Settings
  bool _pushNotificationsEnabled = true;
  bool _locationTrackingEnabled = false;
  bool _darkModeEnabled = false;
  double _maxDistanceKm = 10.0;  // Max. Entfernung für Filialen
  final List<String> _favoriteRetailers = [];
  
  // Premium Features Access
  bool _hasUnlimitedOffers = false;
  bool _hasAdvancedFilters = false;
  bool _hasFlashDealsAccess = false;
  bool _hasMapFeatures = false;

  // Selected retailer for free users
  String? _selectedRetailer;

  // Task 16: Provider References for Freemium Enforcement
  OffersProvider? _offersProvider;
  FlashDealsProvider? _flashDealsProvider;
  RetailersProvider? _retailersProvider;

  // Constructor
  UserProvider() {
    _initializeUser();
  }
  
  void _initializeUser() {
    _lastResetDate = DateTime.now();
    _updatePremiumFeatures();
  }
  
  // Getters - User State
  UserTier get userTier => _userTier;
  String? get userId => _userId;
  String? get userName => _userName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPremium => _userTier == UserTier.premium;
  bool get isFree => _userTier == UserTier.free;
  
  // Getters - Usage & Limits
  int get offersViewed => _offersViewed;
  int get searchesToday => _searchesToday;
  int get flashDealsViewed => _flashDealsViewed;
  int get availableRetailers => isPremium ? -1 : freeRetailersLimit;
  int get remainingSearches => isPremium ? -1 : (freeSearchesLimit - _searchesToday).clamp(0, freeSearchesLimit);
  int get remainingFlashDeals => isPremium ? -1 : (freeFlashDealsLimit - _flashDealsViewed).clamp(0, freeFlashDealsLimit);
  
  // Getters - Settings
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get locationTrackingEnabled => _locationTrackingEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  double get maxDistanceKm => _maxDistanceKm;
  List<String> get favoriteRetailers => List.unmodifiable(_favoriteRetailers);
  String? get selectedRetailer => _selectedRetailer;
  
  // Getters - Premium Features
  bool get hasUnlimitedOffers => _hasUnlimitedOffers;
  bool get hasAdvancedFilters => _hasAdvancedFilters;
  bool get hasFlashDealsAccess => _hasFlashDealsAccess;
  bool get hasMapFeatures => _hasMapFeatures;
  
  // User Management
  void loginUser(String userId, String userName, {UserTier tier = UserTier.free}) {
    _userId = userId;
    _userName = userName;
    _userTier = tier;
    _isLoggedIn = true;
    _updatePremiumFeatures();
    notifyListeners();
  }
  
  void logoutUser() {
    _userId = null;
    _userName = null;
    _userTier = UserTier.free;
    _isLoggedIn = false;
    _resetUsage();
    _updatePremiumFeatures();
    notifyListeners();
  }
  
  void upgradeToPremium() {
    _userTier = UserTier.premium;
    _updatePremiumFeatures();
    notifyListeners();
  }
  
  void downgradeTo(UserTier tier) {
    _userTier = tier;
    _updatePremiumFeatures();
    notifyListeners();
  }
  
  // Usage Tracking & Limits
  bool canViewOffers() {
    // Free users can see ALL offers from their selected retailer
    return true;
  }

  bool canPerformSearch() {
    // Free users can search as much as they want
    return true;
  }

  bool canViewFlashDeals() {
    // Free users can see ALL flash deals from their selected retailer
    return true;
  }

  bool canSelectRetailer(String retailerId, List<String> currentSelectedRetailers) {
    // Free users can only select 1 retailer
    if (isPremium) return true;

    // If trying to select more than 1 retailer
    if (!currentSelectedRetailers.contains(retailerId) &&
        currentSelectedRetailers.length >= freeRetailersLimit) {
      return false;
    }
    return true;
  }
  
  void incrementOffersViewed() {
    if (!isPremium) {
      _offersViewed++;
      notifyListeners();
    }
  }
  
  void incrementSearches() {
    if (!isPremium) {
      _searchesToday++;
      notifyListeners();
    }
  }
  
  void incrementFlashDealsViewed() {
    if (!isPremium) {
      _flashDealsViewed++;
      notifyListeners();
    }
  }
  
  // Settings Management
  void setPushNotifications(bool enabled) {
    _pushNotificationsEnabled = enabled;
    notifyListeners();
    // TODO: Actual push notification setup
  }
  
  void setLocationTracking(bool enabled) {
    _locationTrackingEnabled = enabled;
    notifyListeners();
    // TODO: Actual location permission handling
  }
  
  void setDarkMode(bool enabled) {
    _darkModeEnabled = enabled;
    notifyListeners();
  }

  void setMaxDistance(double distanceKm) {
    _maxDistanceKm = distanceKm.clamp(1.0, 50.0);
    notifyListeners();
  }

  void setSelectedRetailer(String? retailer) {
    _selectedRetailer = retailer;
    notifyListeners();
  }
  
  void addFavoriteRetailer(String retailer) {
    if (!_favoriteRetailers.contains(retailer)) {
      _favoriteRetailers.add(retailer);
      notifyListeners();
    }
  }
  
  void removeFavoriteRetailer(String retailer) {
    if (_favoriteRetailers.remove(retailer)) {
      notifyListeners();
    }
  }
  
  void toggleFavoriteRetailer(String retailer) {
    if (_favoriteRetailers.contains(retailer)) {
      removeFavoriteRetailer(retailer);
    } else {
      addFavoriteRetailer(retailer);
    }
  }
  
  bool isFavoriteRetailer(String retailer) {
    return _favoriteRetailers.contains(retailer);
  }
  
  // Premium Features Check
  bool canUseAdvancedFilters() {
    return isPremium || hasAdvancedFilters;
  }
  
  bool canUseMapFeatures() {
    return isPremium || hasMapFeatures;
  }
  
  bool canAccessFlashDeals() {
    return isPremium || hasFlashDealsAccess;
  }
  
  // Premium Upgrade Prompts
  String getUpgradePrompt(String feature) {
    switch (feature.toLowerCase()) {
      case 'retailers':
        return 'Als Free User können Sie nur einen Händler auswählen. Upgraden Sie zu Premium für alle Händler!';
      case 'offers':
        return 'Mit Premium sehen Sie Angebote von ALLEN Händlern gleichzeitig!';
      case 'flashdeals':
        return 'Mit Premium sehen Sie Flash Deals von ALLEN Händlern!';
      case 'map':
        return 'Karten-Features sind nur für Premium User verfügbar.';
      case 'filters':
        return 'Mit Premium können Sie mehrere Händler gleichzeitig filtern.';
      default:
        return 'Dieses Feature ist nur für Premium User verfügbar.';
    }
  }
  
  // Usage Statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'tier': _userTier.toString(),
      'offersViewed': _offersViewed,
      'searchesToday': _searchesToday,
      'flashDealsViewed': _flashDealsViewed,
      'favoriteRetailers': _favoriteRetailers.length,
      'availableRetailers': availableRetailers,
      'isPremium': isPremium,
    };
  }
  
  // Daily Reset Logic
  void _checkDailyReset() {
    if (_lastResetDate == null || !_isSameDay(_lastResetDate!, DateTime.now())) {
      _resetUsage();
      _lastResetDate = DateTime.now();
    }
  }
  
  void _resetUsage() {
    _offersViewed = 0;
    _searchesToday = 0;
    _flashDealsViewed = 0;
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  void _updatePremiumFeatures() {
    _hasUnlimitedOffers = isPremium;
    _hasAdvancedFilters = isPremium;
    _hasFlashDealsAccess = isPremium || _flashDealsViewed < freeFlashDealsLimit;
    _hasMapFeatures = isPremium;
  }
  
  // Professor Demo Methods
  void enableDemoMode() {
    _userTier = UserTier.premium;
    _updatePremiumFeatures();
    _resetUsage();
    notifyListeners();
  }

  // Task 7: Alias for Professor Demo activation
  void activatePremiumDemo() {
    enableDemoMode();
  }

  void resetToFreeMode() {
    _userTier = UserTier.free;
    _updatePremiumFeatures();
    _resetUsage();
    notifyListeners();
  }

  // Task 16: Cross-Provider Communication Methods
  void registerWithProviders({
    required OffersProvider offersProvider,
    required FlashDealsProvider flashDealsProvider,
    required RetailersProvider retailersProvider,
  }) {
    _offersProvider = offersProvider;
    _flashDealsProvider = flashDealsProvider;
    _retailersProvider = retailersProvider;

    debugPrint('UserProvider: Registered with all providers for freemium enforcement');
  }

  void unregisterFromProviders() {
    _offersProvider = null;
    _flashDealsProvider = null;
    _retailersProvider = null;
    debugPrint('UserProvider: Unregistered from all providers');
  }

  // Task 16: Apply Freemium Limits
  List<dynamic> applyFreemiumLimits(List<dynamic> items, String type) {
    // Premium users see everything
    if (isPremium) return items;

    // Free users see ALL offers/deals from their selected retailer
    // No limits on content, only on retailer selection
    return items;
  }

  // Filter retailers for free users
  List<String> filterAvailableRetailers(List<String> retailers) {
    if (isPremium) return retailers;

    // Free users can only see/select 1 retailer at a time
    if (retailers.isEmpty) return retailers;

    // Return only the first retailer for free users
    return retailers.take(freeRetailersLimit).toList();
  }

  // Task 16: Check if user can perform action
  bool canPerformAction(String action) {
    _checkDailyReset();

    switch (action) {
      case 'viewOffers':
        return canViewOffers();
      case 'search':
        return canPerformSearch();
      case 'viewFlashDeals':
        return canViewFlashDeals();
      case 'useMap':
        return canUseMapFeatures();
      case 'advancedFilters':
        return canUseAdvancedFilters();
      default:
        return true;
    }
  }

  // Task 16: Get remaining limit for UI display
  String getRemainingLimitText(String type) {
    if (isPremium) return 'Premium: Alle Händler verfügbar';

    switch (type) {
      case 'offers':
        return 'Free: 1 Händler - Alle Angebote sichtbar';
      case 'retailers':
        return 'Free: 1 Händler wählbar';
      case 'flashdeals':
        return 'Free: 1 Händler - Alle Flash Deals sichtbar';
      default:
        return 'Free: 1 Händler verfügbar';
    }
  }

  @override
  void dispose() {
    // Clean up provider references
    unregisterFromProviders();
    super.dispose();
  }
}
