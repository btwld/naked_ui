import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

class ToggleButtonExample extends StatefulWidget {
  const ToggleButtonExample({super.key});

  @override
  State<ToggleButtonExample> createState() => _ToggleButtonExampleState();
}

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
                ? Colors.blue.shade600
                : isHovered
                    ? Colors.grey.shade200
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isFocused
                ? Border.all(color: Colors.blue, width: 2)
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toggle Button Example'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Text Formatting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Sample Text',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                    decoration: _isUnderlined ? TextDecoration.underline : null,
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
