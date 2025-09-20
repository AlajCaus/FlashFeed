// RetailerSelector Widget  
// Händler-Auswahl mit Logos und Verfügbarkeit

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/retailers_provider.dart';
import '../models/models.dart';
import 'retailer_logo.dart';

enum RetailerDisplayMode { grid, list }

class RetailerSelector extends StatefulWidget {
  final Function(List<String>) onSelectionChanged;
  final List<String>? initialSelection;
  final bool multiSelect;
  final bool showOnlyAvailable;
  final RetailerDisplayMode displayMode;
  final String? emptyMessage;
  
  const RetailerSelector({
    super.key,
    required this.onSelectionChanged,
    this.initialSelection,
    this.multiSelect = true,
    this.showOnlyAvailable = false,
    this.displayMode = RetailerDisplayMode.grid,
    this.emptyMessage,
  });
  
  @override
  State<RetailerSelector> createState() => _RetailerSelectorState();
}

class _RetailerSelectorState extends State<RetailerSelector> {
  late Set<String> _selectedRetailers;
  bool _showOnlyAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _selectedRetailers = Set.from(widget.initialSelection ?? []);
    _showOnlyAvailable = widget.showOnlyAvailable;
  }
  
  void _toggleRetailer(String retailerName) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedRetailers.contains(retailerName)) {
          _selectedRetailers.remove(retailerName);
        } else {
          _selectedRetailers.add(retailerName);
        }
      } else {
        // Single select mode
        _selectedRetailers.clear();
        _selectedRetailers.add(retailerName);
      }
    });
    
    widget.onSelectionChanged(_selectedRetailers.toList());
  }
  
  @override
  Widget build(BuildContext context) {
    // Task 18.1: Optimized with Selector - only rebuilds when retailers list changes
    return Selector<RetailersProvider, List<Retailer>>(
      selector: (context, provider) => _showOnlyAvailable
          ? provider.availableRetailers
          : provider.allRetailers,
      builder: (context, retailers, child) {
        final retailersProvider = Provider.of<RetailersProvider>(context, listen: false);

        if (retailers.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            _buildFilterBar(context, retailersProvider),
            const SizedBox(height: 8),
            Expanded(
              child: widget.displayMode == RetailerDisplayMode.grid
                  ? _buildGridView(retailers, retailersProvider)
                  : _buildListView(retailers, retailersProvider),
            ),
            if (widget.multiSelect)
              _buildSelectionSummary(context),
          ],
        );
      },
    );
  }
  
  Widget _buildFilterBar(BuildContext context, RetailersProvider retailersProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: Text('Nur verfügbare'),
            selected: _showOnlyAvailable,
            onSelected: (selected) {
              setState(() {
                _showOnlyAvailable = selected;
              });
            },
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            checkmarkColor: Theme.of(context).primaryColor,
          ),
          const Spacer(),
          if (retailersProvider.currentPLZ?.isNotEmpty == true)
            Chip(
              label: Text('PLZ: ${retailersProvider.currentPLZ}'),
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }
  
  Widget _buildGridView(List<Retailer> retailers, RetailersProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: retailers.length,
      itemBuilder: (context, index) {
        final retailer = retailers[index];
        final isSelected = _selectedRetailers.contains(retailer.name);
        final isAvailable = provider.isRetailerAvailable(retailer.name);
        
        return _RetailerGridItem(
          retailer: retailer,
          isSelected: isSelected,
          isAvailable: isAvailable,
          onTap: () => _toggleRetailer(retailer.name),
        );
      },
    );
  }
  
  Widget _buildListView(List<Retailer> retailers, RetailersProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: retailers.length,
      itemBuilder: (context, index) {
        final retailer = retailers[index];
        final isSelected = _selectedRetailers.contains(retailer.name);
        final isAvailable = provider.isRetailerAvailable(retailer.name);
        
        return _RetailerListItem(
          retailer: retailer,
          isSelected: isSelected,
          isAvailable: isAvailable,
          onTap: () => _toggleRetailer(retailer.name),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage ?? 'Keine Händler verfügbar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          if (_showOnlyAvailable)
            TextButton(
              onPressed: () {
                setState(() {
                  _showOnlyAvailable = false;
                });
              },
              child: const Text('Alle Händler anzeigen'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSelectionSummary(BuildContext context) {
    if (_selectedRetailers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedRetailers.length} ausgewählt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRetailers.clear();
              });
              widget.onSelectionChanged([]);
            },
            child: const Text('Auswahl löschen'),
          ),
        ],
      ),
    );
  }
}

// Grid Item Widget
class _RetailerGridItem extends StatelessWidget {
  final Retailer retailer;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;
  
  const _RetailerGridItem({
    required this.retailer,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RetailerLogo(
                  retailerName: retailer.name,
                  size: LogoSize.medium,
                  shape: LogoShape.rounded,
                ),
                const SizedBox(height: 8),
                Text(
                  retailer.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (!isAvailable)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// List Item Widget
class _RetailerListItem extends StatelessWidget {
  final Retailer retailer;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;
  
  const _RetailerListItem({
    required this.retailer,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: RetailerLogo(
        retailerName: retailer.name,
        size: LogoSize.small,
        shape: LogoShape.circle,
      ),
      title: Text(
        retailer.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        isAvailable ? 'Verfügbar' : 'Nicht verfügbar',
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAvailable)
            Icon(
              Icons.block,
              size: 16,
              color: Colors.grey.shade600,
            ),
          const SizedBox(width: 8),
          Checkbox(
            value: isSelected,
            onChanged: (_) => onTap(),
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
