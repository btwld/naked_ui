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
          child: DisabledButtonExample(),
        ),
      ),
    );
  }
}

class DisabledButtonExample extends StatefulWidget {
  const DisabledButtonExample({super.key});

  @override
  State<DisabledButtonExample> createState() => _DisabledButtonExampleState();
}

class _DisabledButtonExampleState extends State<DisabledButtonExample> {
  bool _isEnabled = true;
  bool _enableFeedback = true;
  String _lastAction = 'None';

  void _toggleEnabled() {
    setState(() {
      _isEnabled = !_isEnabled;
      if (!_isEnabled) {
        _lastAction = 'Button disabled';
      }
    });
  }

  void _toggleFeedback() {
    setState(() {
      _enableFeedback = !_enableFeedback;
    });
  }

  void _onButtonPressed() {
    setState(() {
      _lastAction =
          'Button pressed${_enableFeedback ? ' (with feedback)' : ''}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Disabled States & Accessibility',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Main interactive button
          Center(
            child: _SemanticButton(
              enabled: _isEnabled,
              enableFeedback: _enableFeedback,
              onPressed: _onButtonPressed,
              lastAction: _lastAction,
            ),
          ),

          const SizedBox(height: 32),

          // Control panel
          _ControlPanel(
            isEnabled: _isEnabled,
            enableFeedback: _enableFeedback,
            onToggleEnabled: _toggleEnabled,
            onToggleFeedback: _toggleFeedback,
          ),

          const SizedBox(height: 32),

          // Examples of different disabled states
          const _DisabledStatesShowcase(),

          const SizedBox(height: 32),

          // Accessibility features showcase
          const _AccessibilityShowcase(),
        ],
      ),
    );
  }
}

class _SemanticButton extends StatefulWidget {
  const _SemanticButton({
    required this.enabled,
    required this.enableFeedback,
    required this.onPressed,
    required this.lastAction,
  });

  final bool enabled;
  final bool enableFeedback;
  final VoidCallback onPressed;
  final String lastAction;

  @override
  State<_SemanticButton> createState() => _SemanticButtonState();
}

class _SemanticButtonState extends State<_SemanticButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color get backgroundColor {
    const enabledColor = Color(0xFF3D3D3D);
    const disabledColor = Color(0xFFBDBDBD);

    if (!widget.enabled) {
      return disabledColor;
    }

    if (_isPressed) {
      return enabledColor.withValues(alpha: 0.8);
    }
    if (_isHovered) {
      return enabledColor.withValues(alpha: 0.9);
    }
    return enabledColor;
  }

  Color get borderColor {
    if (!widget.enabled) return Colors.transparent;
    if (_isFocused) return const Color(0xFF2196F3);
    return Colors.transparent;
  }

  Color get textColor {
    return widget.enabled ? Colors.white : Colors.grey.shade600;
  }

  String get buttonText {
    if (!widget.enabled) return 'Disabled Button';
    if (_isPressed) return 'Pressed!';
    if (_isHovered) return 'Hovered';
    return 'Interactive Button';
  }

  IconData get buttonIcon {
    if (!widget.enabled) return Icons.block;
    if (_isPressed) return Icons.touch_app;
    return Icons.touch_app_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      enabled: widget.enabled,
      enableFeedback: widget.enableFeedback,
      onPressed: widget.enabled ? widget.onPressed : null,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                buttonIcon,
                color: textColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                buttonText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.lastAction != 'None')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Last: ${widget.lastAction}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.isEnabled,
    required this.enableFeedback,
    required this.onToggleEnabled,
    required this.onToggleFeedback,
  });

  final bool isEnabled;
  final bool enableFeedback;
  final VoidCallback onToggleEnabled;
  final VoidCallback onToggleFeedback;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _ControlToggle(
            label: 'Button Enabled',
            description: 'Toggle the enabled/disabled state',
            value: isEnabled,
            onChanged: onToggleEnabled,
          ),
          _ControlToggle(
            label: 'Haptic Feedback',
            description: 'Enable/disable platform feedback on tap',
            value: enableFeedback,
            onChanged: onToggleFeedback,
          ),
        ],
      ),
    );
  }
}

class _ControlToggle extends StatelessWidget {
  const _ControlToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Toggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatefulWidget {
  const _Toggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final VoidCallback onChanged;

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onChanged,
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 28,
          decoration: BoxDecoration(
            color:
                widget.value ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment:
                widget.value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisabledStatesShowcase extends StatelessWidget {
  const _DisabledStatesShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disabled States Examples',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DisabledButtonExample(
                  label: 'Primary Disabled',
                  backgroundColor: Colors.grey.shade300,
                  textColor: Colors.grey.shade600,
                  icon: Icons.block,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DisabledButtonExample(
                  label: 'Secondary Disabled',
                  backgroundColor: Colors.transparent,
                  textColor: Colors.grey.shade400,
                  borderColor: Colors.grey.shade300,
                  icon: Icons.do_not_disturb_alt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisabledButtonExample extends StatelessWidget {
  const _DisabledButtonExample({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      enabled: false,
      onPressed: null,
      mouseCursor: SystemMouseCursors.forbidden,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilityShowcase extends StatelessWidget {
  const _AccessibilityShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Accessibility Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AccessibilityFeature(
            icon: Icons.label,
            title: 'Semantic Labels',
            description: 'Screen readers announce button purpose and state',
          ),
          const _AccessibilityFeature(
            icon: Icons.help_outline,
            title: 'Semantic Hints',
            description: 'Additional context for screen reader users',
          ),
          const _AccessibilityFeature(
            icon: Icons.mouse,
            title: 'Mouse Cursors',
            description: 'Visual feedback with appropriate cursor states',
          ),
          const _AccessibilityFeature(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            description: 'Platform-appropriate tactile feedback on interaction',
          ),
          const _AccessibilityFeature(
            icon: Icons.keyboard,
            title: 'Keyboard Navigation',
            description: 'Full keyboard accessibility with focus management',
          ),
        ],
      ),
    );
  }
}

class _AccessibilityFeature extends StatelessWidget {
  const _AccessibilityFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
