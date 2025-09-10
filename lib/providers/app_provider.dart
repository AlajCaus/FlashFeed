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
  int _selectedPanelIndex = 0;  // Task 7: For TabController integration
  final List<int> _navigationHistory = [];  // Task 7: For back navigation
  bool _isLoading = false;
  String? _errorMessage;
  
  // App Global State
  bool _isDarkMode = false;
  bool _isFirstLaunch = true;
  String? _userPLZ;
  
  // Getters
  AppPanel get currentPanel => _currentPanel;
  int get selectedPanelIndex => _selectedPanelIndex;  // Task 7
  List<int> get navigationHistory => List.unmodifiable(_navigationHistory);  // Task 7
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
  
  // Task 7: Navigation with index (for TabController)
  void navigateToPanel(int index) {
    if (index < 0 || index > 2) return;
    
    // Save to history
    if (_selectedPanelIndex != index) {
      _navigationHistory.add(_selectedPanelIndex);
      if (_navigationHistory.length > 10) {
        _navigationHistory.removeAt(0);  // Keep max 10 history items
      }
    }
    
    _selectedPanelIndex = index;
    _currentPanel = AppPanel.values[index];
    clearError();
    notifyListeners();
  }
  
  // Task 7: Check if user can navigate to panel (Premium check)
  bool canNavigateToPanel(int index, bool isPremium) {
    // Panel 1 (Map) requires Premium
    if (index == 1 && !isPremium) {
      return false;
    }
    return true;
  }
  
  // Task 7: Navigate back
  void navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      final previousIndex = _navigationHistory.removeLast();
      _selectedPanelIndex = previousIndex;
      _currentPanel = AppPanel.values[previousIndex];
      clearError();
      notifyListeners();
    }
  }
  
  // Task 7: Reset navigation
  void resetNavigation() {
    _selectedPanelIndex = 0;
    _currentPanel = AppPanel.offers;
    _navigationHistory.clear();
    clearError();
    notifyListeners();
  }
  
  void switchToOffers() => navigateToPanel(0);
  void switchToMap() => navigateToPanel(1);
  void switchToFlashDeals() => navigateToPanel(2);
  
  // Dark Mode
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }
  
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
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
