// FlashFeed Unavailable Retailer Card Widget
// Regional unavailability UI fallback logic

import 'package:flutter/material.dart';
import '../../models/models.dart';

class UnavailableRetailerCard extends StatelessWidget {
  final Retailer retailer;
  final String userPLZ;
  final List<Retailer> alternativeRetailers;
  final VoidCallback? onExpandSearchRadius;
  
  const UnavailableRetailerCard({
    super.key,
    required this.retailer,
    required this.userPLZ,
    this.alternativeRetailers = const [],
    this.onExpandSearchRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Opacity(
        opacity: 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with retailer logo and unavailable badge
              Row(
                children: [
                  // Retailer Logo (grayed out)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: retailer.iconUrl != null
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Image.network(
                              retailer.iconUrl!,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.store, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  
                  // Retailer name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          retailer.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 14,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Nicht verfügbar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Info button
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: Colors.grey,
                    onPressed: () {
                      _showInfoDialog(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Unavailability message
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${retailer.displayName} ist in PLZ $userPLZ nicht verfügbar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Available regions info
              if (retailer.availableRegions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Verfügbar in: ${retailer.availableRegions.join(", ")}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              // Alternative retailers section
              if (alternativeRetailers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Alternative Händler in Ihrer Nähe:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: alternativeRetailers.take(3).map((alternative) {
                    return Chip(
                      label: Text(
                        alternative.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              
              // Action button
              if (onExpandSearchRadius != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onExpandSearchRadius,
                    icon: const Icon(Icons.expand, size: 18),
                    label: const Text('Suchradius erweitern'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text('${retailer.displayName} Verfügbarkeit'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${retailer.displayName} ist leider nicht in Ihrer Region (PLZ $userPLZ) verfügbar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (retailer.availableRegions.isNotEmpty) ...[
                Text(
                  'Verfügbare Regionen:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...retailer.availableRegions.map((region) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, 
                        size: 16, 
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(region),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 16),
              const Text(
                'Tipp: Nutzen Sie die Filteroptionen, um nur verfügbare Händler anzuzeigen.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Verstanden'),
            ),
          ],
        );
      },
    );
  }
}
