import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

class AnimatedPopoverExample extends StatefulWidget {
  const AnimatedPopoverExample({super.key});

  @override
  State<AnimatedPopoverExample> createState() => _AnimatedPopoverExampleState();
}

class _AnimatedPopoverExampleState extends State<AnimatedPopoverExample>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );

  late final _scaleAnimation = Tween<double>(
    begin: 0.8,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutBack,
  ));

  late final _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  ));

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Popover Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Advanced Popover with Animation & Fallback Positions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Center popover
              Center(
                child: _buildPopover(
                  'Center Popover',
                  'This popover has fallback positions',
                  positioning: const OverlayPositionConfig(
                    alignment: Alignment.topCenter,
                    fallbackAlignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Row of popovers to test edge cases
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPopover(
                    'Left Edge',
                    'This popover is near the left edge',
                    positioning: const OverlayPositionConfig(
                      alignment: Alignment.centerLeft,
                      fallbackAlignment: Alignment.centerRight,
                    ),
                  ),
                  _buildPopover(
                    'Right Edge',
                    'This popover is near the right edge',
                    positioning: const OverlayPositionConfig(
                      alignment: Alignment.centerRight,
                      fallbackAlignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smart Positioning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try clicking the buttons near screen edges. The popovers will automatically choose the best position using fallback options.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopover(
    String buttonText,
    String popoverContent, {
    OverlayPositionConfig? positioning,
  }) {
    return NakedPopover(
      positioning: positioning ?? const OverlayPositionConfig(),
      onOpen: () => _animationController.forward(),
      onClose: () => _animationController.reverse(),
      popoverBuilder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    popoverContent,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
