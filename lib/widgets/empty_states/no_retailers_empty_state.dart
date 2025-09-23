// FlashFeed No Retailers Empty State Widget
// Regional unavailability UI fallback logic

import 'package:flutter/material.dart';

class NoRetailersEmptyState extends StatelessWidget {
  final String userPLZ;
  final VoidCallback? onExpandSearchRadius;
  final VoidCallback? onChangePLZ;
  final int? availableRetailersInExpandedRadius;
  
  const NoRetailersEmptyState({
    super.key,
    required this.userPLZ,
    this.onExpandSearchRadius,
    this.onChangePLZ,
    this.availableRetailersInExpandedRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Keine Händler verfügbar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'In Ihrer Region (PLZ $userPLZ) sind aktuell keine Händler verfügbar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Expanded radius info
            if (availableRetailersInExpandedRadius != null && 
                availableRetailersInExpandedRadius! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$availableRetailersInExpandedRadius Händler im erweiterten Umkreis verfügbar',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              children: [
                if (onExpandSearchRadius != null) ...[
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: onExpandSearchRadius,
                      icon: const Icon(Icons.expand),
                      label: const Text('Suchradius erweitern'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (onChangePLZ != null) ...[
                  SizedBox(
                    width: 200,
                    child: OutlinedButton.icon(
                      onPressed: onChangePLZ,
                      icon: const Icon(Icons.edit_location),
                      label: const Text('PLZ ändern'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Probieren Sie eine größere Stadt in Ihrer Nähe oder nutzen Sie die bundesweiten Online-Angebote.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
