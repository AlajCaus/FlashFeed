// FlashFeed App Provider - Navigation & Global State
// Zentrale State-Verwaltung für die gesamte App

import 'package:flutter/material.dart';

enum AppPanel {
  offers,      // Panel 1: Angebotsvergleich
  map,         // Panel 2: Kartenansicht  
  flashDeals,  // Panel 3: Flash Deals
}

class AppProvider extends ChangeNotifier {
  // Navigation State
  AppPanel _currentPanel = AppPanel.offers;
  bool _isLoading = false;
  String? _errorMessage;
  
  // App Global State
  bool _isDarkMode = false;
  bool _isFirstLaunch = true;
  String? _userPLZ;
  
  // Getters
  AppPanel get currentPanel => _currentPanel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;
  String? get userPLZ => _userPLZ;
  
  // Panel Navigation
  void switchToPanel(AppPanel panel) {
    if (_currentPanel != panel) {
      _currentPanel = panel;
      clearError(); // Clear errors when switching panels
      notifyListeners();
    }
  }
  
  void switchToOffers() => switchToPanel(AppPanel.offers);
  void switchToMap() => switchToPanel(AppPanel.map);
  void switchToFlashDeals() => switchToPanel(AppPanel.flashDeals);
  
  // Loading State
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  // Error Handling
  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  // Theme Management
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    // TODO: Save to SharedPreferences in real app
  }
  
  void setTheme(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }
  
  // First Launch & Onboarding
  void completeFirstLaunch() {
    _isFirstLaunch = false;
    notifyListeners();
    // TODO: Save to SharedPreferences in real app
  }
  
  // User Location (PLZ)
  void setUserPLZ(String plz) {
    if (_userPLZ != plz) {
      _userPLZ = plz;
      notifyListeners();
      // Trigger regional filtering in other providers
    }
  }
  
  void clearUserPLZ() {
    if (_userPLZ != null) {
      _userPLZ = null;
      notifyListeners();
    }
  }
  
  // Utility Methods
  String get currentPanelName {
    switch (_currentPanel) {
      case AppPanel.offers:
        return 'Angebote';
      case AppPanel.map:
        return 'Karte';
      case AppPanel.flashDeals:
        return 'Flash Deals';
    }
  }
  
  bool get hasUserLocation => _userPLZ != null && _userPLZ!.isNotEmpty;
  
  // Professor Demo Helper
  void triggerProfessorDemo() {
    setLoading(true);
    // Simulate demo delay
    Future.delayed(Duration(milliseconds: 800), () {
      setLoading(false);
      switchToFlashDeals(); // Switch to Flash Deals after demo
    });
  }
  
  // Regional Support (ready for Task 5c integration)
  bool get hasRegionalSupport => hasUserLocation;
  
  void refreshRegionalData() {
    if (hasUserLocation) {
      // Will trigger regional refresh in other providers
      setLoading(true);
      Future.delayed(Duration(milliseconds: 500), () {
        setLoading(false);
      });
    }
  }
  
  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}
