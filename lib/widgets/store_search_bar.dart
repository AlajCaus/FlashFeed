// StoreSearchBar Widget
// Filial-Suche mit Auto-Complete und Filtern

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/retailers_provider.dart';
import '../models/models.dart';
import 'retailer_logo.dart';

class StoreSearchBar extends StatefulWidget {
  final Function(Store) onStoreSelected;
  final double? searchRadius;
  final List<String>? requiredServices;
  final bool openOnly;
  final String? placeholder;
  
  const StoreSearchBar({
    super.key,
    required this.onStoreSelected,
    this.searchRadius = 5.0,
    this.requiredServices,
    this.openOnly = false,
    this.placeholder,
  });
  
  @override
  State<StoreSearchBar> createState() => _StoreSearchBarState();
}

class _StoreSearchBarState extends State<StoreSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<Store> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  
  // Filter states
  double _currentRadius = 5.0;
  bool _openOnly = false;
  List<String> _selectedServices = [];
  
  @override
  void initState() {
    super.initState();
    _currentRadius = widget.searchRadius ?? 5.0;
    _openOnly = widget.openOnly;
    _selectedServices = List.from(widget.requiredServices ?? []);
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Hide results when focus is lost
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_focusNode.hasFocus) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    final retailersProvider = Provider.of<RetailersProvider>(
      context,
      listen: false,
    );
    
    try {
      final results = await retailersProvider.searchStores(
        query,
        radiusKm: _currentRadius,
        requiredServices: _selectedServices.isEmpty ? null : _selectedServices,
        openOnly: _openOnly,
        sortBy: StoreSearchSort.distance,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results.take(10).toList(); // Limit to 10 results
          _isSearching = false;
          _showResults = results.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }
  
  void _selectStore(Store store) {
    widget.onStoreSelected(store);
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
    _focusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(context),
        const SizedBox(height: 8),
        _buildFilterChips(context),
        if (_showResults)
          _buildSearchResults(context),
      ],
    );
  }
  
  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.placeholder ?? 'Filiale suchen...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              if (_searchController.text.isNotEmpty && !_isSearching)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _showResults = false;
                    });
                  },
                ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onChanged: _onSearchChanged,
        onTap: () {
          if (_searchResults.isNotEmpty) {
            setState(() {
              _showResults = true;
            });
          }
        },
      ),
    );
  }
  
  Widget _buildFilterChips(BuildContext context) {
    final availableServices = ['Payback', 'DHL Station', 'Metzgerei', 'Bäckerei', 'Apotheke'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Radius filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('${_currentRadius.toInt()}km'),
              selected: true,
              onSelected: (_) => _showRadiusDialog(context),
              avatar: const Icon(Icons.location_on, size: 16),
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
          ),
          
          // Open only filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('Nur geöffnet'),
              selected: _openOnly,
              onSelected: (selected) {
                setState(() {
                  _openOnly = selected;
                });
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              selectedColor: Colors.green.withValues(alpha: 0.2),
              checkmarkColor: Colors.green,
            ),
          ),
          
          // Service filters
          ...availableServices.map((service) {
            final isSelected = _selectedServices.contains(service);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _searchResults.isEmpty
          ? _buildNoResults(context)
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final store = _searchResults[index];
                return _StoreSearchResult(
                  store: store,
                  onTap: () => _selectStore(store),
                );
              },
            ),
    );
  }
  
  Widget _buildNoResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Keine Filialen gefunden',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Versuchen Sie eine andere Suche oder ändern Sie die Filter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _showRadiusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double tempRadius = _currentRadius;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Suchradius'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${tempRadius.toInt()} km'),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${tempRadius.toInt()} km',
                    onChanged: (value) {
                      setState(() {
                        tempRadius = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      _currentRadius = tempRadius;
                    });
                    Navigator.pop(context);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Search result item widget
class _StoreSearchResult extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;
  
  const _StoreSearchResult({
    super.key,
    required this.store,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isOpen = store.isOpenAt(DateTime.now());
    
    return ListTile(
      onTap: onTap,
      leading: RetailerLogo(
        retailerName: store.retailerName,
        size: LogoSize.small,
        shape: LogoShape.circle,
      ),
      title: Text(
        store.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${store.street}, ${store.zipCode} ${store.city}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isOpen ? Icons.access_time : Icons.block,
                size: 12,
                color: isOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isOpen ? 'Geöffnet' : 'Geschlossen',
                style: TextStyle(
                  fontSize: 11,
                  color: isOpen ? Colors.green : Colors.red,
                ),
              ),
              if (store.services.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.local_offer, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${store.services.length} Services',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
