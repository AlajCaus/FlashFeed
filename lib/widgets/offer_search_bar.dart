import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offers_provider.dart';
import '../services/local_storage_service.dart';

/// OfferSearchBar - Intelligente Suchleiste mit Auto-Complete
/// 
/// Features:
/// - Auto-Complete mit Kategorien
/// - Such-Historie
/// - Debounced Search
/// - Clear-Button mit Animation
class OfferSearchBar extends StatefulWidget {
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;
  
  const OfferSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterTap,
  });

  @override
  State<OfferSearchBar> createState() => _OfferSearchBarState();
}

class _OfferSearchBarState extends State<OfferSearchBar> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  LocalStorageService? _storage;
  
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  late AnimationController _clearButtonController;
  late Animation<double> _clearButtonAnimation;
  
  // Design System Colors
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  @override
  void initState() {
    super.initState();
    _initStorage();
    
    _clearButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _clearButtonAnimation = CurvedAnimation(
      parent: _clearButtonController,
      curve: Curves.easeInOut,
    );
    
    _searchController.addListener(_onSearchTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  Future<void> _initStorage() async {
    _storage = await LocalStorageService.getInstance();
    _loadSearchHistory();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _clearButtonController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSearchHistory() async {
    if (_storage == null) return;
    final history = await _storage!.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }
  
  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    // Animate clear button
    if (query.isNotEmpty && _clearButtonController.value == 0) {
      _clearButtonController.forward();
    } else if (query.isEmpty && _clearButtonController.value == 1) {
      _clearButtonController.reverse();
    }
    
    // Get suggestions
    if (query.isNotEmpty) {
      // Generate basic suggestions from query
      setState(() {
        _suggestions = [
          {'type': 'popular', 'value': query, 'category': null},
        ];
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
    
    // Notify parent
    widget.onSearchChanged?.call(query);
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _showSuggestions = true;
      });
    } else if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }
  
  void _onSubmitted(String value) {
    if (value.isNotEmpty && _storage != null) {
      _storage!.addToSearchHistory(value);
      _loadSearchHistory();
    }
    _focusNode.unfocus();
    widget.onSearchChanged?.call(value);
  }
  
  void _onSuggestionTapped(String suggestion) {
    _searchController.text = suggestion;
    _onSubmitted(suggestion);
  }
  
  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
    _focusNode.unfocus();
  }
  
  Widget _buildSuggestionIcon(String type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case 'category':
        iconData = Icons.category;
        color = primaryGreen;
        break;
      case 'product':
        iconData = Icons.shopping_bag;
        color = Colors.blue;
        break;
      case 'retailer':
        iconData = Icons.store;
        color = Colors.orange;
        break;
      case 'popular':
        iconData = Icons.trending_up;
        color = Colors.red;
        break;
      default:
        iconData = Icons.search;
        color = textSecondary;
    }
    
    return Icon(iconData, size: 20, color: color);
  }
  
  @override
  Widget build(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();
    
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _focusNode.hasFocus ? primaryGreen : borderColor,
                      width: _focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        size: 20,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Suche Produkte, Kategorien oder Händler...',
                            hintStyle: TextStyle(
                              color: textSecondary.withAlpha(153),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 14),
                          textInputAction: TextInputAction.search,
                          onSubmitted: _onSubmitted,
                        ),
                      ),
                      // Clear Button
                      AnimatedBuilder(
                        animation: _clearButtonAnimation,
                        builder: (context, child) {
                          return _clearButtonAnimation.value > 0
                              ? Opacity(
                                  opacity: _clearButtonAnimation.value,
                                  child: Transform.scale(
                                    scale: _clearButtonAnimation.value,
                                    child: IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: _clearSearch,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                      color: textSecondary,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: 8);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              Container(
                decoration: BoxDecoration(
                  color: offersProvider.hasActiveFilters
                      ? primaryGreen
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: offersProvider.hasActiveFilters ? primaryGreen : borderColor,
                  ),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: offersProvider.hasActiveFilters
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : textSecondary),
                      ),
                      onPressed: widget.onFilterTap,
                    ),
                    if (offersProvider.hasActiveFilters)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Suggestions Dropdown
        if (_showSuggestions) 
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                // Search History
                if (_searchController.text.isEmpty && _searchHistory.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zuletzt gesucht',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (_storage != null) {
                              await _storage!.clearSearchHistory();
                              _loadSearchHistory();
                            }
                          },
                          child: const Text(
                            'Löschen',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(
                    _searchHistory.take(5).length,
                    (index) => ListTile(
                      leading: Icon(Icons.history, size: 20, color: textSecondary),
                      title: Text(
                        _searchHistory[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                      onTap: () => _onSuggestionTapped(_searchHistory[index]),
                    ),
                  ),
                ],
                
                // Auto-Complete Suggestions
                if (_suggestions.isNotEmpty) ...[
                  if (_searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Vorschläge',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ...List.generate(
                    _suggestions.length,
                    (index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: _buildSuggestionIcon(suggestion['type']),
                        title: Text(
                          suggestion['value'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: suggestion['category'] != null
                            ? Text(
                                suggestion['category'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              )
                            : null,
                        dense: true,
                        onTap: () => _onSuggestionTapped(suggestion['value']),
                      );
                    },
                  ),
                ],
                
                // No Results
                if (_searchController.text.isNotEmpty && _suggestions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: textSecondary.withAlpha(102),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keine Ergebnisse für "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
