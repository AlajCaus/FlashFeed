import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offers_provider.dart';
import '../providers/retailers_provider.dart';

/// OfferFilterBar - Erweiterte Filter-Komponenten
/// 
/// Features:
/// - Multi-Select Kategorie-Filter
/// - Preis-Range Slider
/// - Rabatt-Filter
/// - Verfügbarkeits-Filter
/// - Filter-Chips mit Clear-All
class OfferFilterBar extends StatefulWidget {
  final VoidCallback? onClose;
  
  const OfferFilterBar({
    super.key,
    this.onClose,
  });

  @override
  State<OfferFilterBar> createState() => _OfferFilterBarState();
}

class _OfferFilterBarState extends State<OfferFilterBar> {
  // Filter State
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedRetailers = {};
  RangeValues _priceRange = const RangeValues(0, 50);
  double _minDiscount = 0;
  bool _onlyAvailable = true;
  
  // UI State
  bool _categoriesExpanded = false;
  bool _retailersExpanded = false;
  bool _priceExpanded = false;
  bool _discountExpanded = false;
  
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color chipBg = Color(0xFFF0F0F0);
  
  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }
  
  void _loadCurrentFilters() {
    // final offersProvider = context.read<OffersProvider>(); // Currently unused
    // TODO: Load current filter state from provider
    // This would require extending OffersProvider with getter methods
  }
  
  void _applyFilters() {
    final offersProvider = context.read<OffersProvider>();
    
    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      offersProvider.filterByCategories(_selectedCategories.toList());
    }
    
    // Apply retailer filter
    if (_selectedRetailers.isNotEmpty) {
      offersProvider.filterByRetailers(_selectedRetailers.toList());
    }
    
    // Apply price filter
    offersProvider.filterByPriceRange(_priceRange.start, _priceRange.end);
    
    // Apply discount filter
    if (_minDiscount > 0) {
      offersProvider.filterByMinDiscount(_minDiscount);
    }
    
    // Apply availability filter
    offersProvider.setRegionalFilter(_onlyAvailable);
    
    widget.onClose?.call();
  }
  
  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedRetailers.clear();
      _priceRange = const RangeValues(0, 50);
      _minDiscount = 0;
      _onlyAvailable = true;
    });
    
    final offersProvider = context.read<OffersProvider>();
    offersProvider.clearFilters();
  }
  
  Widget _buildFilterSection({
    required String title,
    required Widget content,
    required bool isExpanded,
    required VoidCallback onToggle,
    int activeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$activeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: content,
            ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    final categories = [
      'Obst & Gemüse',
      'Milchprodukte',
      'Fleisch & Wurst',
      'Brot & Backwaren',
      'Getränke',
      'Süßwaren',
      'Tiefkühl',
      'Konserven',
      'Drogerie',
      'Haushalt',
      'Bio-Produkte',
      'Fertiggerichte',
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        
        return FilterChip(
          label: Text(
            category,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : textSecondary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
            });
          },
          selectedColor: primaryGreen,
          backgroundColor: chipBg,
          checkmarkColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }
  
  Widget _buildRetailerFilter() {
    final retailersProvider = context.watch<RetailersProvider>();
    final retailers = retailersProvider.availableRetailers;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: retailers.map((retailer) {
        final isSelected = _selectedRetailers.contains(retailer.name);
        
        return FilterChip(
          label: Text(
            retailer.name,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : textSecondary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedRetailers.add(retailer.name);
              } else {
                _selectedRetailers.remove(retailer.name);
              }
            });
          },
          selectedColor: primaryGreen,
          backgroundColor: chipBg,
          checkmarkColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }
  
  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€${_priceRange.start.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '€${_priceRange.end.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 50,
          divisions: 50,
          activeColor: primaryGreen,
          inactiveColor: borderColor,
          labels: RangeLabels(
            '€${_priceRange.start.toStringAsFixed(0)}',
            '€${_priceRange.end.toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildDiscountFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mindestrabatt',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '${_minDiscount.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _minDiscount,
          min: 0,
          max: 50,
          divisions: 10,
          activeColor: primaryRed,
          inactiveColor: borderColor,
          label: '${_minDiscount.toStringAsFixed(0)}%',
          onChanged: (value) {
            setState(() {
              _minDiscount = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [10, 20, 30, 40, 50].map((discount) {
            return ActionChip(
              label: Text(
                '>$discount%',
                style: TextStyle(
                  fontSize: 12,
                  color: _minDiscount == discount ? Colors.white : textSecondary,
                ),
              ),
              onPressed: () {
                setState(() {
                  _minDiscount = discount.toDouble();
                });
              },
              backgroundColor: _minDiscount == discount ? primaryRed : chipBg,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();
    final filterStats = {
      'filtered': offersProvider.filteredOffers.length,
      'total': offersProvider.totalOffers,
    };
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filterStats['filtered']} von ${filterStats['total']} Angeboten',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text(
                    'Alle löschen',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Categories
                _buildFilterSection(
                  title: 'Kategorien',
                  content: _buildCategoryFilter(),
                  isExpanded: _categoriesExpanded,
                  onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
                  activeCount: _selectedCategories.length,
                ),
                
                // Retailers
                _buildFilterSection(
                  title: 'Händler',
                  content: _buildRetailerFilter(),
                  isExpanded: _retailersExpanded,
                  onToggle: () => setState(() => _retailersExpanded = !_retailersExpanded),
                  activeCount: _selectedRetailers.length,
                ),
                
                // Price Range
                _buildFilterSection(
                  title: 'Preis',
                  content: _buildPriceFilter(),
                  isExpanded: _priceExpanded,
                  onToggle: () => setState(() => _priceExpanded = !_priceExpanded),
                  activeCount: _priceRange != const RangeValues(0, 50) ? 1 : 0,
                ),
                
                // Discount
                _buildFilterSection(
                  title: 'Rabatt',
                  content: _buildDiscountFilter(),
                  isExpanded: _discountExpanded,
                  onToggle: () => setState(() => _discountExpanded = !_discountExpanded),
                  activeCount: _minDiscount > 0 ? 1 : 0,
                ),
                
                // Availability Toggle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nur verfügbare Angebote',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Zeige nur Angebote von Händlern in deiner Region',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _onlyAvailable,
                        onChanged: (value) {
                          setState(() {
                            _onlyAvailable = value;
                          });
                        },
                        activeThumbColor: primaryGreen, // Updated deprecated property
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // Apply Button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Filter anwenden',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
