import 'package:flutter/material.dart';

/// Centralized Error Widget for consistent error display across the app
///
/// Error Handling & Loading States
/// Provides user-friendly error messages with retry functionality
class ErrorStateWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ErrorType errorType;

  const ErrorStateWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.errorType = ErrorType.general,
  });

  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color errorRed = Color(0xFFDC3545);
  static const Color warningOrange = Color(0xFFFF6347);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            _buildErrorIcon(),

            const SizedBox(height: 24),

            // Error Title
            Text(
              _getErrorTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error Message
            Text(
              errorMessage ?? _getDefaultErrorMessage(),
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),

              // Retry Button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],

            // Additional Help Text for specific errors
            if (_hasAdditionalHelp()) ...[
              const SizedBox(height: 16),
              _buildHelpText(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor;
    double iconSize = 64;

    switch (errorType) {
      case ErrorType.network:
        iconData = Icons.wifi_off;
        iconColor = errorRed;
        break;
      case ErrorType.noData:
        iconData = Icons.inbox;
        iconColor = textSecondary;
        break;
      case ErrorType.permission:
        iconData = Icons.lock;
        iconColor = warningOrange;
        break;
      case ErrorType.region:
        iconData = Icons.location_off;
        iconColor = warningOrange;
        break;
      case ErrorType.general:
        iconData = Icons.error_outline;
        iconColor = errorRed;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  String _getErrorTitle() {
    switch (errorType) {
      case ErrorType.network:
        return 'Keine Internetverbindung';
      case ErrorType.noData:
        return 'Keine Daten verfügbar';
      case ErrorType.permission:
        return 'Berechtigung erforderlich';
      case ErrorType.region:
        return 'Nicht in Ihrer Region verfügbar';
      case ErrorType.general:
        return 'Ein Fehler ist aufgetreten';
    }
  }

  String _getDefaultErrorMessage() {
    switch (errorType) {
      case ErrorType.network:
        return 'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';
      case ErrorType.noData:
        return 'Aktuell sind keine Angebote oder Daten verfügbar. Bitte versuchen Sie es später erneut.';
      case ErrorType.permission:
        return 'Diese Funktion benötigt zusätzliche Berechtigungen. Bitte überprüfen Sie Ihre Einstellungen.';
      case ErrorType.region:
        return 'In Ihrer Region sind aktuell keine Händler oder Angebote verfügbar.';
      case ErrorType.general:
        return 'Es ist ein unerwarteter Fehler aufgetreten. Bitte versuchen Sie es erneut.';
    }
  }

  bool _hasAdditionalHelp() {
    return errorType == ErrorType.permission ||
           errorType == ErrorType.region;
  }

  Widget _buildHelpText() {
    String helpText;
    IconData helpIcon;

    switch (errorType) {
      case ErrorType.permission:
        helpText = 'Gehen Sie zu Einstellungen → Standort und erlauben Sie den Zugriff';
        helpIcon = Icons.settings;
        break;
      case ErrorType.region:
        helpText = 'Versuchen Sie eine andere PLZ oder erweitern Sie Ihren Suchradius';
        helpIcon = Icons.search;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            helpIcon,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              helpText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error types for different error scenarios
enum ErrorType {
  network,     // Network connectivity issues
  noData,      // No data available
  permission,  // Permission denied (GPS, etc.)
  region,      // Regional availability issues
  general,     // General/unknown errors
}