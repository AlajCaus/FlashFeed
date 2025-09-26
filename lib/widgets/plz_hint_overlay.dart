import 'package:flutter/material.dart';
import 'dart:async';

class PLZHintOverlay extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback? onUserInteraction;

  const PLZHintOverlay({
    super.key,
    required this.onOpenSettings,
    this.onUserInteraction,
  });

  @override
  State<PLZHintOverlay> createState() => _PLZHintOverlayState();
}

class _PLZHintOverlayState extends State<PLZHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _autoHideTimer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Delay showing the hint until after PLZ panel is visible
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        // Start animation
        _animationController.forward();
        _setupInteractionListeners();
      }
    });

    // Auto-hide after 20 seconds (keep at 20 seconds as requested)
    _autoHideTimer = Timer(const Duration(seconds: 20, milliseconds: 400), () {
      if (mounted && _isVisible) {
        _hideOverlay();
      }
    });
  }

  void _setupInteractionListeners() {
    // Add scroll listener to detect any scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find any Scrollable widget in the tree
      final scrollableContext = context.findAncestorStateOfType<ScrollableState>();
      if (scrollableContext != null) {
        scrollableContext.position.addListener(_onUserScroll);
      }
    });
  }

  void _onUserScroll() {
    // Hide overlay immediately on scroll
    if (mounted && _isVisible) {
      _hideOverlay();
      widget.onUserInteraction?.call();
    }
  }

  void _hideOverlay() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animationController.dispose();
    // Remove scroll listener if it exists
    final scrollableContext = context.findAncestorStateOfType<ScrollableState>();
    if (scrollableContext != null) {
      scrollableContext.position.removeListener(_onUserScroll);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                // Positioned hint box with arrow pointing to PLZ button
                Positioned(
                  top: 255, // Positioniert beim blauen PLZ-Panel
                  left: 140, // Links vom PLZ-Button positioniert
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Arrow pointing left to PLZ button
                        CustomPaint(
                          size: const Size(20, 30),
                          painter: ArrowPainter(),
                        ),
                        const SizedBox(width: 8),
                        // Hint box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF2E8B57),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text
                              const Text(
                                'Hier können Sie Ihre PLZ eingeben',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Close button
                              InkWell(
                                onTap: _hideOverlay,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
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
      },
    );
  }
}

// Custom painter for arrow pointing left
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Arrow pointing left
    path.moveTo(size.width, size.height / 2 - 8); // Right top
    path.lineTo(size.width, size.height / 2 + 8); // Right bottom
    path.lineTo(0, size.height / 2); // Left point
    path.close();

    // Draw white background
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, whitePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for arrow pointing right
class ArrowPainterRight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Arrow pointing right
    path.moveTo(0, size.height / 2 - 8); // Left top
    path.lineTo(0, size.height / 2 + 8); // Left bottom
    path.lineTo(size.width, size.height / 2); // Right point
    path.close();

    // Draw white background
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, whitePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}