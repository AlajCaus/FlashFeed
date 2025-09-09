import 'package:flutter/material.dart';

/// ResponsiveHelper - Utility class for responsive design
/// 
/// Breakpoints:
/// - Mobile: 320-768px
/// - Tablet: 768-1024px  
/// - Desktop: 1024px+
class ResponsiveHelper {
  // Private constructor to prevent instantiation
  ResponsiveHelper._();
  
  // Breakpoint constants
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double minMobileWidth = 320.0;
  
  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  // Get current device type as enum
  static DeviceType getDeviceType(BuildContext context) {
    if (isMobile(context)) return DeviceType.mobile;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.desktop;
  }
  
  // Grid column calculator
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4; // Desktop: 4+ columns
  }
  
  // Advanced grid columns with custom breakpoints
  static int getAdaptiveGridColumns(BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    if (isMobile(context)) return mobileColumns;
    if (isTablet(context)) return tabletColumns;
    return desktopColumns;
  }
  
  // Font scaling based on screen size
  static double getScaledFontSize(double baseFontSize, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Scale factor based on device width
    double scaleFactor = 1.0;
    if (width < 375) {
      scaleFactor = 0.9; // Small mobile
    } else if (width < mobileBreakpoint) {
      scaleFactor = 1.0; // Standard mobile
    } else if (width < tabletBreakpoint) {
      scaleFactor = 1.1; // Tablet
    } else {
      scaleFactor = 1.2; // Desktop
    }
    
    return baseFontSize * scaleFactor;
  }
  
  // Typography scaling helpers
  static double getHeadlineSize(BuildContext context) {
    return getScaledFontSize(24.0, context);
  }
  
  static double getTitleSize(BuildContext context) {
    return getScaledFontSize(20.0, context);
  }
  
  static double getBodySize(BuildContext context) {
    return getScaledFontSize(16.0, context);
  }
  
  static double getCaptionSize(BuildContext context) {
    return getScaledFontSize(12.0, context);
  }
  
  // Spacing system (4px base unit)
  static const double space1 = 4.0;   // 4px
  static const double space2 = 8.0;   // 8px
  static const double space3 = 12.0;  // 12px
  static const double space4 = 16.0;  // 16px
  static const double space5 = 20.0;  // 20px
  static const double space6 = 24.0;  // 24px
  static const double space8 = 32.0;  // 32px
  static const double space10 = 40.0; // 40px
  static const double space12 = 48.0; // 48px
  static const double space16 = 64.0; // 64px
  
  // Responsive spacing based on device
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isMobile(context)) return baseSpacing * 0.8;
    if (isTablet(context)) return baseSpacing;
    return baseSpacing * 1.2; // Desktop gets more spacing
  }
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Get animation duration based on device performance
  static Duration getAnimationDuration(BuildContext context, AnimationSpeed speed) {
    // Could check for device performance, but keeping simple for MVP
    switch (speed) {
      case AnimationSpeed.fast:
        return animationFast;
      case AnimationSpeed.normal:
        return animationNormal;
      case AnimationSpeed.slow:
        return animationSlow;
    }
  }
  
  // Container constraints helpers
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 720.0;
    return 1140.0; // Desktop max content width
  }
  
  // Card width calculator for grid layouts
  static double getCardWidth(BuildContext context, {double spacing = 16.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = getGridColumns(context);
    final totalSpacing = spacing * (columns + 1);
    return (screenWidth - totalSpacing) / columns;
  }
  
  // Responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(space4); // 16px
    }
    if (isTablet(context)) {
      return const EdgeInsets.all(space6); // 24px
    }
    return const EdgeInsets.all(space8); // 32px
  }
  
  // Card padding based on device
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(space3); // 12px
    }
    return const EdgeInsets.all(space4); // 16px
  }
  
  // Navigation layout helper
  static bool shouldUseBottomNav(BuildContext context) {
    return isMobile(context);
  }
  
  static bool shouldUseSideNav(BuildContext context) {
    return isDesktop(context);
  }
  
  static bool shouldUseTabBar(BuildContext context) {
    return isTablet(context);
  }
  
  // Modal/Dialog sizing
  static double getDialogWidth(BuildContext context) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width * 0.9;
    }
    if (isTablet(context)) {
      return 600.0;
    }
    return 720.0; // Desktop
  }
  
  // Responsive image sizing
  static double getImageHeight(BuildContext context, {
    double mobileHeight = 200.0,
    double tabletHeight = 300.0,
    double desktopHeight = 400.0,
  }) {
    if (isMobile(context)) return mobileHeight;
    if (isTablet(context)) return tabletHeight;
    return desktopHeight;
  }
  
  // Touch target sizing (Accessibility)
  static const double minTouchTarget = 44.0; // iOS/Android guideline
  
  static double getTouchTargetSize(BuildContext context) {
    // Larger touch targets on mobile
    if (isMobile(context)) return 48.0;
    return minTouchTarget;
  }
  
  // Helper to check if we should show mobile-specific UI
  static bool shouldShowMobileUI(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }
  
  // Helper to check if we should show desktop-specific UI
  static bool shouldShowDesktopUI(BuildContext context) {
    return isDesktop(context);
  }
  
  // Responsive text alignment
  static TextAlign getTextAlign(BuildContext context, {
    TextAlign mobileAlign = TextAlign.center,
    TextAlign desktopAlign = TextAlign.left,
  }) {
    return shouldShowMobileUI(context) ? mobileAlign : desktopAlign;
  }
  
  // Responsive flex values for Row/Column
  static int getFlexValue(BuildContext context, {
    int mobileFlex = 1,
    int tabletFlex = 2,
    int desktopFlex = 3,
  }) {
    if (isMobile(context)) return mobileFlex;
    if (isTablet(context)) return tabletFlex;
    return desktopFlex;
  }
}

// Enums for type safety
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

enum AnimationSpeed {
  fast,
  normal,
  slow,
}

// Extension methods for easier usage
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  int get gridColumns => ResponsiveHelper.getGridColumns(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  EdgeInsets get screenPadding => ResponsiveHelper.getScreenPadding(this);
}
