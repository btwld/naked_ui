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
          child: AnimatedDialogExample(),
        ),
      ),
    );
  }
}

class AnimatedDialogExample extends StatefulWidget {
  const AnimatedDialogExample({super.key});

  @override
  State<AnimatedDialogExample> createState() => _AnimatedDialogExampleState();
}

class _AnimatedDialogExampleState extends State<AnimatedDialogExample> {
  String? _lastDialogResult;

  Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: const Interval(0.0, 0.7)),
        ),
        child: child,
      ),
    );
  }

  Widget _scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation.drive(
        Tween<double>(begin: 0.5, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
      ),
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: child,
      ),
    );
  }

  Widget _rotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: animation.drive(
        Tween<double>(begin: 0.25, end: 0.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
      ),
      child: ScaleTransition(
        scale: animation.drive(
          Tween<double>(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.easeOutBack),
          ),
        ),
        child: child,
      ),
    );
  }

  void _showSlideDialog() async {
    final result = await showNakedDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: _slideTransition,
      builder: (context) => _AnimatedDialogContent(
        title: 'Slide Transition',
        subtitle: 'This dialog slides up from the bottom',
        icon: Icons.arrow_upward,
        color: const Color(0xFF4CAF50),
        onConfirm: () => Navigator.of(context).pop('slide_confirm'),
        onCancel: () => Navigator.of(context).pop('slide_cancel'),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lastDialogResult = result;
      });
    }
  }

  void _showScaleDialog() async {
    final result = await showNakedDialog<String>(
      context: context,
      barrierColor: Colors.purple.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 800),
      transitionBuilder: _scaleTransition,
      builder: (context) => _AnimatedDialogContent(
        title: 'Scale Transition',
        subtitle: 'This dialog uses elastic scaling animation',
        icon: Icons.zoom_in,
        color: const Color(0xFF9C27B0),
        onConfirm: () => Navigator.of(context).pop('scale_confirm'),
        onCancel: () => Navigator.of(context).pop('scale_cancel'),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lastDialogResult = result;
      });
    }
  }

  void _showRotationDialog() async {
    final result = await showNakedDialog<String>(
      context: context,
      barrierColor: Colors.orange.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 700),
      transitionBuilder: _rotationTransition,
      barrierDismissible: false,
      builder: (context) => _AnimatedDialogContent(
        title: 'Rotation Transition',
        subtitle: 'This dialog rotates and scales with bounce',
        icon: Icons.rotate_right,
        color: const Color(0xFFFF9800),
        onConfirm: () => Navigator.of(context).pop('rotation_confirm'),
        onCancel: () => Navigator.of(context).pop('rotation_cancel'),
        showNonDismissibleNote: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lastDialogResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        _TriggerButton(
          onPressed: _showSlideDialog,
          text: 'Slide Animation',
          description: 'Bottom slide with fade',
          color: const Color(0xFF4CAF50),
        ),
        _TriggerButton(
          onPressed: _showScaleDialog,
          text: 'Scale Animation',
          description: 'Elastic bounce effect',
          color: const Color(0xFF9C27B0),
        ),
        _TriggerButton(
          onPressed: _showRotationDialog,
          text: 'Rotation Animation',
          description: 'Non-dismissible with rotation',
          color: const Color(0xFFFF9800),
        ),
        if (_lastDialogResult != null)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text(
                  'Last Dialog Result',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastDialogResult!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnimatedDialogContent extends StatelessWidget {
  const _AnimatedDialogContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onConfirm,
    required this.onCancel,
    this.showNonDismissibleNote = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showNonDismissibleNote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (showNonDismissibleNote) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap backdrop cannot dismiss',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _DialogButton(
                    onPressed: onCancel,
                    backgroundColor: Colors.grey.shade100,
                    textColor: Colors.grey.shade700,
                    text: 'Cancel',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DialogButton(
                    onPressed: onConfirm,
                    backgroundColor: color,
                    textColor: Colors.white,
                    text: 'Confirm',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TriggerButton extends StatefulWidget {
  const _TriggerButton({
    required this.onPressed,
    required this.text,
    required this.description,
    required this.color,
  });

  final VoidCallback onPressed;
  final String text;
  final String description;
  final Color color;

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color get backgroundColor {
    if (_isPressed) {
      return widget.color.withValues(alpha: 0.8);
    }
    if (_isHovered) {
      return widget.color.withValues(alpha: 0.9);
    }
    return widget.color;
  }

  double get scale => _isPressed ? 0.98 : 1.0;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.text,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String text;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color get backgroundColor {
    if (_isPressed) {
      return widget.backgroundColor.withValues(alpha: 0.8);
    }
    if (_isHovered) {
      return widget.backgroundColor.withValues(alpha: 0.9);
    }
    return widget.backgroundColor;
  }

  double get scale => _isPressed ? 0.95 : 1.0;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
