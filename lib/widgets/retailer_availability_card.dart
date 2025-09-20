// RetailerAvailabilityCard Widget
// Zeigt Verfügbarkeits-Information für einen Händler mit Alternativen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/retailers_provider.dart';
import '../models/models.dart';
import 'retailer_logo.dart';

class RetailerAvailabilityCard extends StatefulWidget {
  final String retailerName;
  final String userPLZ;
  final VoidCallback? onChangePLZ;
  final Function(String)? onAlternativeSelected;
  
  const RetailerAvailabilityCard({
    super.key,
    required this.retailerName,
    required this.userPLZ,
    this.onChangePLZ,
    this.onAlternativeSelected,
  });
  
  @override
  State<RetailerAvailabilityCard> createState() => _RetailerAvailabilityCardState();
}

class _RetailerAvailabilityCardState extends State<RetailerAvailabilityCard> {
  bool _isExpanded = false;
  Map<String, dynamic>? _coverage;
  List<Retailer>? _alternatives;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(RetailerAvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retailerName != widget.retailerName ||
        oldWidget.userPLZ != widget.userPLZ) {
      _loadData();
    }
  }
  
  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<RetailersProvider>(context, listen: false);
    
    // Get coverage statistics
    final coverage = provider.getRetailerCoverage(widget.retailerName);
    
    // Check if available and get alternatives if not
    final isAvailable = provider.getAvailableRetailers(widget.userPLZ)
        .any((r) => r.name == widget.retailerName);
    
    List<Retailer>? alternatives;
    if (!isAvailable) {
      alternatives = provider.findAlternativeRetailers(
        widget.userPLZ,
        widget.retailerName,
      );
    }
    
    setState(() {
      _coverage = coverage;
      _alternatives = alternatives;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<RetailersProvider>(
      builder: (context, retailersProvider, child) {
        final isAvailable = retailersProvider.getAvailableRetailers(widget.userPLZ)
            .any((r) => r.name == widget.retailerName);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAvailable ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, isAvailable, retailersProvider),
              if (!isAvailable && _alternatives != null && _alternatives!.isNotEmpty)
                _buildAlternatives(context),
              if (_isExpanded)
                _buildExpandedContent(context, retailersProvider),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context, bool isAvailable, RetailersProvider provider) {
    final retailer = provider.getRetailerDetails(widget.retailerName);
    
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            RetailerLogo(
              retailerName: widget.retailerName,
              size: LogoSize.medium,
              shape: LogoShape.rounded,
              showBorder: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    retailer?.displayName ?? widget.retailerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.info_outline,
                              size: 14,
                              color: isAvailable ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailable 
                                  ? 'Verfügbar in PLZ ${widget.userPLZ}'
                                  : 'Nicht verfügbar',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAvailable ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlternatives(BuildContext context) {
    if (_alternatives == null || _alternatives!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Alternative Händler in Ihrer Nähe:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _alternatives!.length.clamp(0, 5),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final alternative = _alternatives![index];
                return _AlternativeRetailerChip(
                  retailer: alternative,
                  onTap: widget.onAlternativeSelected != null
                      ? () => widget.onAlternativeSelected!(alternative.name)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandedContent(BuildContext context, RetailersProvider provider) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_coverage == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticRow(
            context,
            'Filialen gesamt',
            _coverage!['totalStores']?.toString() ?? '0',
            Icons.store,
          ),
          const SizedBox(height: 12),
          _buildStatisticRow(
            context,
            'Abdeckung',
            '${_coverage!['coveragePercentage'] ?? '0'}%',
            Icons.map,
          ),
          const SizedBox(height: 12),
          if (_coverage!['coveredRegions'] != null && 
              (_coverage!['coveredRegions'] as List).isNotEmpty) ...[
            Text(
              'Verfügbare Regionen:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_coverage!['coveredRegions'] as List).map((region) {
                return Chip(
                  label: Text(
                    region.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (_coverage!['servicesOffered'] != null && 
              (_coverage!['servicesOffered'] as List).isNotEmpty) ...[
            Text(
              'Verfügbare Services:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_coverage!['servicesOffered'] as List).take(5).map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getServiceIcon(service.toString()),
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (widget.onChangePLZ != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: widget.onChangePLZ,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('PLZ ändern'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatisticRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
  
  IconData _getServiceIcon(String service) {
    final serviceLower = service.toLowerCase();
    if (serviceLower.contains('dhl') || serviceLower.contains('post')) {
      return Icons.local_shipping;
    } else if (serviceLower.contains('apotheke') || serviceLower.contains('pharmacy')) {
      return Icons.medical_services;
    } else if (serviceLower.contains('bäcker') || serviceLower.contains('bakery')) {
      return Icons.bakery_dining;
    } else if (serviceLower.contains('metz') || serviceLower.contains('fleisch')) {
      return Icons.restaurant;
    } else if (serviceLower.contains('payback') || serviceLower.contains('karte')) {
      return Icons.card_membership;
    } else {
      return Icons.local_offer;
    }
  }
}

// Alternative retailer chip widget
class _AlternativeRetailerChip extends StatelessWidget {
  final Retailer retailer;
  final VoidCallback? onTap;
  
  const _AlternativeRetailerChip({
    required this.retailer,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RetailerLogo(
              retailerName: retailer.name,
              size: LogoSize.small,
              shape: LogoShape.circle,
            ),
            const SizedBox(height: 4),
            Text(
              retailer.displayName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
