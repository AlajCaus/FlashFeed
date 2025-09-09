// FlashFeed No Offers Empty State Widget
// Task 5c.4: Regional unavailability UI fallback logic

import 'package:flutter/material.dart';

class NoOffersEmptyState extends StatelessWidget {
  final String userPLZ;
  final String? selectedCategory;
  final VoidCallback? onResetFilters;
  final VoidCallback? onExpandSearchRadius;
  final VoidCallback? onChangePLZ;
  final int? totalOffersCount;
  final int? nearbyOffersCount;
  
  const NoOffersEmptyState({
    super.key,
    required this.userPLZ,
    this.selectedCategory,
    this.onResetFilters,
    this.onExpandSearchRadius,
    this.onChangePLZ,
    this.totalOffersCount,
    this.nearbyOffersCount,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = selectedCategory != null;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters 
                    ? Icons.filter_alt_off 
                    : Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.orange.shade300,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              hasFilters 
                  ? 'Keine passenden Angebote'
                  : 'Keine Angebote in Ihrer Region',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              hasFilters
                  ? 'Für die Kategorie "$selectedCategory" gibt es in PLZ $userPLZ keine Angebote.'
                  : 'In PLZ $userPLZ sind aktuell keine Angebote verfügbar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Statistics
            if (totalOffersCount != null || nearbyOffersCount != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (totalOffersCount != null) ...[
                    _buildStatCard(
                      context,
                      icon: Icons.local_offer,
                      label: 'Gesamt',
                      value: totalOffersCount.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (nearbyOffersCount != null && nearbyOffersCount! > 0) ...[
                    _buildStatCard(
                      context,
                      icon: Icons.near_me,
                      label: 'In der Nähe',
                      value: nearbyOffersCount.toString(),
                      color: Colors.green,
                    ),
                  ],
                ],
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (hasFilters && onResetFilters != null) ...[
                  ElevatedButton.icon(
                    onPressed: onResetFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Filter zurücksetzen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
                if (onExpandSearchRadius != null) ...[
                  OutlinedButton.icon(
                    onPressed: onExpandSearchRadius,
                    icon: const Icon(Icons.expand),
                    label: const Text('Umkreis erweitern'),
                  ),
                ],
                if (onChangePLZ != null) ...[
                  OutlinedButton.icon(
                    onPressed: onChangePLZ,
                    icon: const Icon(Icons.edit_location),
                    label: const Text('PLZ ändern'),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Suggestions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vorschläge',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionItem(
                    'Versuchen Sie benachbarte Postleitzahlen',
                    Icons.location_searching,
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestionItem(
                    'Prüfen Sie andere Produktkategorien',
                    Icons.category,
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestionItem(
                    'Nutzen Sie bundesweite Online-Angebote',
                    Icons.language,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
