// FlashFeed User Provider - Freemium Logic & Settings
// Verwaltet User-Einstellungen und Premium-Features

import 'package:flutter/material.dart';

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
  static const int freeOffersLimit = 10;        // Max. 10 Angebote für Free User
  static const int freeSearchesLimit = 5;       // Max. 5 Suchen pro Tag
  static const int freeFlashDealsLimit = 3;    // Max. 3 Flash Deals
  
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
  int get remainingOffers => isPremium ? -1 : (freeOffersLimit - _offersViewed).clamp(0, freeOffersLimit);
  int get remainingSearches => isPremium ? -1 : (freeSearchesLimit - _searchesToday).clamp(0, freeSearchesLimit);
  int get remainingFlashDeals => isPremium ? -1 : (freeFlashDealsLimit - _flashDealsViewed).clamp(0, freeFlashDealsLimit);
  
  // Getters - Settings
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get locationTrackingEnabled => _locationTrackingEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  double get maxDistanceKm => _maxDistanceKm;
  List<String> get favoriteRetailers => List.unmodifiable(_favoriteRetailers);
  
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
    _checkDailyReset();
    return isPremium || _offersViewed < freeOffersLimit;
  }
  
  bool canPerformSearch() {
    _checkDailyReset();
    return isPremium || _searchesToday < freeSearchesLimit;
  }
  
  bool canViewFlashDeals() {
    _checkDailyReset();
    return isPremium || _flashDealsViewed < freeFlashDealsLimit;
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
      case 'offers':
        return 'Sie haben Ihr Angebote-Limit erreicht. Upgraden Sie zu Premium für unbegrenzte Angebote!';
      case 'search':
        return 'Tägliches Such-Limit erreicht. Mit Premium können Sie unbegrenzt suchen!';
      case 'flashdeals':
        return 'Flash Deal Limit erreicht. Premium User sehen alle Flash Deals!';
      case 'map':
        return 'Karten-Features sind nur für Premium User verfügbar.';
      case 'filters':
        return 'Erweiterte Filter sind ein Premium-Feature.';
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
      'remainingOffers': remainingOffers,
      'remainingSearches': remainingSearches,
      'remainingFlashDeals': remainingFlashDeals,
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
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
