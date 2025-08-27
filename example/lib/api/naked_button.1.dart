import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AdvancedButtonExample(),
        ),
      ),
    );
  }
}

class AdvancedButtonExample extends StatefulWidget {
  const AdvancedButtonExample({super.key});

  @override
  State<AdvancedButtonExample> createState() => _AdvancedButtonExampleState();
}

class _AdvancedButtonExampleState extends State<AdvancedButtonExample> {
  String _lastAction = 'None';
  int _tapCount = 0;
  int _longPressCount = 0;
  int _doubleTapCount = 0;

  void _onTap() {
    setState(() {
      _lastAction = 'Single Tap';
      _tapCount++;
    });
  }

  void _onLongPress() {
    setState(() {
      _lastAction = 'Long Press';
      _longPressCount++;
    });
  }

  void _onDoubleTap() {
    setState(() {
      _lastAction = 'Double Tap';
      _doubleTapCount++;
    });
  }

  void _resetCounters() {
    setState(() {
      _lastAction = 'None';
      _tapCount = 0;
      _longPressCount = 0;
      _doubleTapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 32,
      children: [
        const Text(
          'Advanced Button Interactions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        _InteractiveButton(
          onPressed: _onTap,
          onLongPress: _onLongPress,
          onDoubleTap: _onDoubleTap,
        ),
        _ActionFeedback(
          lastAction: _lastAction,
          tapCount: _tapCount,
          longPressCount: _longPressCount,
          doubleTapCount: _doubleTapCount,
          onReset: _resetCounters,
        ),
        const _InstructionCard(),
      ],
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  const _InteractiveButton({
    required this.onPressed,
    required this.onLongPress,
    required this.onDoubleTap,
  });

  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  bool _isLongPressing = false;

  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color get backgroundColor {
    const baseColor = Color(0xFF3D3D3D);
    if (_isLongPressing) {
      return const Color(0xFFFF6B35); // Orange for long press
    }
    if (_isPressed) {
      return baseColor.withValues(alpha: 0.8);
    }
    if (_isHovered) {
      return baseColor.withValues(alpha: 0.9);
    }
    return baseColor;
  }

  Color get borderColor {
    if (_isFocused) return const Color(0xFF2196F3);
    if (_isLongPressing) return const Color(0xFFFF6B35);
    return Colors.transparent;
  }

  void _handleLongPressStart() {
    setState(() {
      _isLongPressing = true;
    });
    _pulseController.repeat(reverse: true);
  }

  void _handleLongPressEnd() {
    setState(() {
      _isLongPressing = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    widget.onLongPress();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _handleLongPressStart(),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      child: NakedButton(
        onPressed: widget.onPressed,
        onDoubleTap: widget.onDoubleTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHoverChange: (hovered) => setState(() => _isHovered = hovered),
        onPressChange: (pressed) {
          setState(() => _isPressed = pressed);
          if (pressed) {
            _scaleController.forward();
          } else {
            _scaleController.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
          builder: (context, child) {
            final scale = _scaleAnimation.value * 
                (_isLongPressing ? _pulseAnimation.value : 1.0);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      if (_isLongPressing)
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLongPressing 
                          ? Icons.touch_app 
                          : Icons.touch_app_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLongPressing 
                          ? 'Long Pressing...' 
                          : 'Interactive Button',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isLongPressing)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Release to trigger',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionFeedback extends StatelessWidget {
  const _ActionFeedback({
    required this.lastAction,
    required this.tapCount,
    required this.longPressCount,
    required this.doubleTapCount,
    required this.onReset,
  });

  final String lastAction;
  final int tapCount;
  final int longPressCount;
  final int doubleTapCount;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Action Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              _ResetButton(onPressed: onReset),
            ],
          ),
          const SizedBox(height: 16),
          _FeedbackRow(
            label: 'Last Action:',
            value: lastAction,
            isHighlighted: lastAction != 'None',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CounterTile(
                  label: 'Taps',
                  count: tapCount,
                  icon: Icons.touch_app,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CounterTile(
                  label: 'Long Press',
                  count: longPressCount,
                  icon: Icons.timer,
                  color: const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CounterTile(
                  label: 'Double Tap',
                  count: doubleTapCount,
                  icon: Icons.touch_app_sharp,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted 
              ? const Color(0xFF3D3D3D).withValues(alpha: 0.1)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted 
                ? FontWeight.w600 
                : FontWeight.normal,
              color: isHighlighted 
                ? const Color(0xFF3D3D3D) 
                : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatefulWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<_ResetButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.refresh,
            size: 16,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'How to use:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _InstructionItem(
            icon: Icons.touch_app,
            text: 'Single tap: Quick press and release',
          ),
          const _InstructionItem(
            icon: Icons.timer,
            text: 'Long press: Hold until button changes color',
          ),
          const _InstructionItem(
            icon: Icons.touch_app_sharp,
            text: 'Double tap: Two quick taps in succession',
          ),
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}