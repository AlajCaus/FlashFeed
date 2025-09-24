import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_deals_provider.dart';

/// Filter-Bar für Flash Deals Panel
/// Ermöglicht Filterung nach Urgency, Händler und verbleibender Zeit
class FlashDealsFilterBar extends StatefulWidget {
  const FlashDealsFilterBar({super.key});

  @override
  State<FlashDealsFilterBar> createState() => _FlashDealsFilterBarState();
}

class _FlashDealsFilterBarState extends State<FlashDealsFilterBar> {
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color secondaryOrange = Color(0xFFFF6347);
  static const Color textSecondary = Color(0xFF666666);

  // Filter state
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashDealsProvider>();
    final hasActiveFilters = provider.selectedUrgencyLevel != null ||
        provider.selectedRetailer != null ||
        provider.maxRemainingMinutes != null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Filter Toggle Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Filter Button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: hasActiveFilters ? primaryGreen : textSecondary,
                  ),
                  label: Text(
                    'Filter ${hasActiveFilters ? '(${_countActiveFilters(provider)})' : ''}',
                    style: TextStyle(
                      color: hasActiveFilters ? primaryGreen : textSecondary,
                      fontWeight: hasActiveFilters ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Active Filter Chips
                if (hasActiveFilters) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (provider.selectedUrgencyLevel != null)
                            _buildFilterChip(
                              label: _getUrgencyLabel(provider.selectedUrgencyLevel!),
                              color: _getUrgencyColor(provider.selectedUrgencyLevel!),
                              onDelete: () => provider.clearUrgencyFilter(),
                            ),
                          if (provider.selectedRetailer != null)
                            _buildFilterChip(
                              label: provider.selectedRetailer!,
                              color: primaryGreen,
                              onDelete: () => provider.clearRetailerFilter(),
                            ),
                          if (provider.maxRemainingMinutes != null)
                            _buildFilterChip(
                              label: '< ${provider.maxRemainingMinutes} Min',
                              color: secondaryOrange,
                              onDelete: () => provider.clearTimeFilter(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),

                // Clear All Button
                if (hasActiveFilters)
                  TextButton(
                    onPressed: () => provider.clearAllFilters(),
                    child: Text(
                      'Alle löschen',
                      style: TextStyle(color: primaryRed),
                    ),
                  ),
              ],
            ),
          ),

          // Expandable Filter Panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Urgency Level Filter
                    _buildUrgencyFilter(provider),

                    const SizedBox(height: 16),

                    // Retailer Filter
                    _buildRetailerFilter(provider),

                    const SizedBox(height: 16),

                    // Time Range Filter
                    _buildTimeFilter(provider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
        onDeleted: onDelete,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildUrgencyFilter(FlashDealsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dringlichkeit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildUrgencyChip('high', 'Kritisch', provider),
            _buildUrgencyChip('medium', 'Mittel', provider),
            _buildUrgencyChip('low', 'Niedrig', provider),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencyChip(String level, String label, FlashDealsProvider provider) {
    final isSelected = provider.selectedUrgencyLevel == level;
    final color = _getUrgencyColor(level);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          provider.filterByUrgencyLevel(level);
        } else {
          provider.clearUrgencyFilter();
        }
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildRetailerFilter(FlashDealsProvider provider) {
    final retailers = provider.currentDealRetailers;

    if (retailers.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Händler',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String?>(
            isExpanded: true,
            value: provider.selectedRetailer,
            hint: const Text('Alle Händler'),
            underline: const SizedBox(),
            onChanged: (value) {
              provider.filterByRetailer(value);
            },
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Alle Händler'),
              ),
              ...retailers.map((retailer) => DropdownMenuItem(
                value: retailer,
                child: Text(retailer),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(FlashDealsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verbleibende Zeit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              provider.maxRemainingMinutes != null
                ? '< ${provider.maxRemainingMinutes} Min'
                : 'Unbegrenzt',
              style: TextStyle(color: secondaryOrange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: secondaryOrange,
            inactiveTrackColor: secondaryOrange.withOpacity(0.3),
            thumbColor: secondaryOrange,
            overlayColor: secondaryOrange.withOpacity(0.2),
          ),
          child: Slider(
            value: provider.maxRemainingMinutes?.toDouble() ?? 120,
            min: 5,
            max: 120,
            divisions: 23,
            label: '${provider.maxRemainingMinutes ?? 120} Min',
            onChanged: (value) {
              provider.setMaxRemainingMinutes(value.toInt());
            },
            onChangeEnd: (value) {
              if (value >= 120) {
                provider.clearTimeFilter();
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 Min', style: TextStyle(fontSize: 12, color: textSecondary)),
            Text('120 Min+', style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
        ),
      ],
    );
  }

  String _getUrgencyLabel(String level) {
    switch (level) {
      case 'high':
        return 'Kritisch';
      case 'medium':
        return 'Mittel';
      case 'low':
        return 'Niedrig';
      default:
        return level;
    }
  }

  Color _getUrgencyColor(String level) {
    switch (level) {
      case 'high':
        return primaryRed;
      case 'medium':
        return secondaryOrange;
      case 'low':
        return primaryGreen;
      default:
        return textSecondary;
    }
  }

  int _countActiveFilters(FlashDealsProvider provider) {
    int count = 0;
    if (provider.selectedUrgencyLevel != null) count++;
    if (provider.selectedRetailer != null) count++;
    if (provider.maxRemainingMinutes != null) count++;
    return count;
  }
}