import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

/// Main function
void main() {
  runApp(const MyApp());
}

/// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Toggle Button Example',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Interact with the toggle button to see its states',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              ToggleButtonExample(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle Button Example
class ToggleButtonExample extends StatefulWidget {
  const ToggleButtonExample({super.key});

  @override
  State<ToggleButtonExample> createState() => _ToggleButtonExampleState();
}

/// Toggle Button Example State
class _ToggleButtonExampleState extends State<ToggleButtonExample> {
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
    required String tooltip,
  }) {
    return NakedToggle(
      value: isSelected,
      asSwitch: false, // Toggle button semantics
      onChanged: onChanged,
      semanticLabel: tooltip,
      builder: (context, toggleState, child) {
        final isSelected = toggleState.isToggled;
        final isHovered = toggleState.isHovered;
        final isFocused = toggleState.isFocused;
        final isPressed = toggleState.isPressed;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.grey.shade800
                : isHovered
                ? Colors.grey.shade200
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: isFocused
                ? Border.all(color: Colors.grey.shade400, width: 2)
                : Border.all(color: Colors.grey.shade300),
            boxShadow: isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            size: 18,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.format_bold,
            isSelected: _isBold,
            onChanged: (value) => setState(() => _isBold = value),
            tooltip: 'Bold',
          ),
          const SizedBox(width: 8),
          _buildToggleButton(
            icon: Icons.format_italic,
            isSelected: _isItalic,
            onChanged: (value) => setState(() => _isItalic = value),
            tooltip: 'Italic',
          ),
          const SizedBox(width: 8),
          _buildToggleButton(
            icon: Icons.format_underlined,
            isSelected: _isUnderlined,
            onChanged: (value) => setState(() => _isUnderlined = value),
            tooltip: 'Underline',
          ),
        ],
      ),
    );
  }
}
