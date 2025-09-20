// RetailerLogo Widget
// Zeigt Händler-Logo mit Fallback-Unterstützung

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/retailers_provider.dart';

enum LogoSize { small, medium, large }

enum LogoShape { circle, square, rounded }

class RetailerLogo extends StatelessWidget {
  final String retailerName;
  final LogoSize size;
  final LogoShape shape;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showBorder;
  
  const RetailerLogo({
    super.key,
    required this.retailerName,
    this.size = LogoSize.medium,
    this.shape = LogoShape.rounded,
    this.onTap,
    this.backgroundColor,
    this.showBorder = false,
  });
  
  double get _logoSize {
    switch (size) {
      case LogoSize.small:
        return 40.0;
      case LogoSize.medium:
        return 60.0;
      case LogoSize.large:
        return 100.0;
    }
  }
  
  BorderRadius? get _borderRadius {
    switch (shape) {
      case LogoShape.circle:
        return BorderRadius.circular(_logoSize / 2);
      case LogoShape.square:
        return BorderRadius.zero;
      case LogoShape.rounded:
        return BorderRadius.circular(8.0);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<RetailersProvider>(
      builder: (context, retailersProvider, child) {
        final logoUrl = retailersProvider.getRetailerLogo(retailerName);
        final brandColors = retailersProvider.getRetailerBrandColors(retailerName);
        final displayName = retailersProvider.getRetailerDisplayName(retailerName);
        
        Widget logoWidget = Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            color: backgroundColor ?? brandColors['accent'],
            borderRadius: _borderRadius,
            border: showBorder
                ? Border.all(
                    color: brandColors['primary'] ?? Theme.of(context).primaryColor,
                    width: 2.0,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: _borderRadius ?? BorderRadius.zero,
            child: _buildLogoContent(logoUrl, displayName, brandColors['primary']),
          ),
        );
        
        if (onTap != null) {
          logoWidget = InkWell(
            onTap: onTap,
            borderRadius: _borderRadius,
            child: logoWidget,
          );
        }
        
        return logoWidget;
      },
    );
  }
  
  Widget _buildLogoContent(String logoUrl, String displayName, Color? primaryColor) {
    // Check if it's a local asset or network image
    if (logoUrl.startsWith('http')) {
      // Network image with fallback
      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(displayName, primaryColor);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.0,
              color: primaryColor,
            ),
          );
        },
      );
    } else if (logoUrl.startsWith('/assets/')) {
      // Local asset
      return Image.asset(
        logoUrl.substring(1), // Remove leading /
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(displayName, primaryColor);
        },
      );
    } else {
      // Fallback for generic or invalid URLs
      return _buildFallbackLogo(displayName, primaryColor);
    }
  }
  
  Widget _buildFallbackLogo(String displayName, Color? primaryColor) {
    // Create initials from retailer name
    final initials = displayName
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    
    return Container(
      color: primaryColor?.withValues(alpha: 0.1) ?? Colors.grey.shade200,
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: TextStyle(
            fontSize: _logoSize * 0.4,
            fontWeight: FontWeight.bold,
            color: primaryColor ?? Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// Convenience widget for a row of retailer logos
class RetailerLogoRow extends StatelessWidget {
  final List<String> retailerNames;
  final LogoSize size;
  final LogoShape shape;
  final double spacing;
  final Function(String)? onRetailerTap;
  
  const RetailerLogoRow({
    super.key,
    required this.retailerNames,
    this.size = LogoSize.small,
    this.shape = LogoShape.circle,
    this.spacing = 8.0,
    this.onRetailerTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: retailerNames.map((name) {
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: RetailerLogo(
              retailerName: name,
              size: size,
              shape: shape,
              onTap: onRetailerTap != null
                  ? () => onRetailerTap!(name)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
