import 'package:flutter/material.dart';

/// Skeleton Loading Widgets for improved loading UX
///
/// Task 17: Error Handling & Loading States
/// Provides shimmer effect placeholders while data loads
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + _animation.value, 0),
                end: Alignment(1.0 + _animation.value, 0),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton for Offer Cards
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(8),
          ),

          const SizedBox(height: 12),

          // Title skeleton
          const SkeletonLoader(
            width: double.infinity,
            height: 16,
          ),

          const SizedBox(height: 8),

          // Subtitle skeleton
          const SkeletonLoader(
            width: 120,
            height: 12,
          ),

          const SizedBox(height: 12),

          // Price skeleton
          Row(
            children: const [
              SkeletonLoader(
                width: 60,
                height: 20,
              ),
              SizedBox(width: 8),
              SkeletonLoader(
                width: 40,
                height: 14,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Retailer skeleton
          const SkeletonLoader(
            width: 80,
            height: 24,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Flash Deal Cards
class FlashDealCardSkeleton extends StatelessWidget {
  const FlashDealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image skeleton
          SkeletonLoader(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Title skeleton
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                ),

                SizedBox(height: 8),

                // Price skeleton
                SkeletonLoader(
                  width: 100,
                  height: 20,
                ),

                SizedBox(height: 8),

                // Timer skeleton
                SkeletonLoader(
                  width: 80,
                  height: 14,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Badge skeleton
          const SkeletonLoader(
            width: 60,
            height: 24,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Store/Retailer Cards
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              // Logo skeleton
              SkeletonLoader(
                width: 48,
                height: 48,
              ),
              SizedBox(width: 12),
              // Store info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 120,
                      height: 16,
                    ),
                    SizedBox(height: 4),
                    SkeletonLoader(
                      width: 80,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Address skeleton
          const SkeletonLoader(
            width: double.infinity,
            height: 14,
          ),

          const SizedBox(height: 8),

          // Distance skeleton
          const SkeletonLoader(
            width: 60,
            height: 14,
          ),
        ],
      ),
    );
  }
}

/// Grid skeleton for offers
class OffersGridSkeleton extends StatelessWidget {
  final int itemCount;

  const OffersGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const OfferCardSkeleton(),
    );
  }
}

/// List skeleton for flash deals
class FlashDealsListSkeleton extends StatelessWidget {
  final int itemCount;

  const FlashDealsListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const FlashDealCardSkeleton(),
    );
  }
}