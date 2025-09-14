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
          child: RadioExample(),
        ),
      ),
    );
  }
}

enum RadioOption {
  banana,
  apple,
}

class RadioExample extends StatefulWidget {
  const RadioExample({super.key});

  @override
  State<RadioExample> createState() => _RadioExampleState();
}

class _RadioExampleState extends State<RadioExample> {
  RadioOption _selectedValue = RadioOption.banana;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<RadioOption>(
      groupValue: _selectedValue,
      onChanged: (value) {
        setState(() => _selectedValue = value!);
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          RadioButton(value: RadioOption.banana),
          RadioButton(value: RadioOption.apple),
        ],
      ),
    );
  }
}

class RadioButton extends StatefulWidget {
  const RadioButton({
    super.key,
    required this.value,
  });

  final RadioOption value;

  @override
  State<RadioButton> createState() => _RadioButtonState();
}

class _RadioButtonState extends State<RadioButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color borderColor(bool isSelected) {
    const baseColor = Color(0xFF3D3D3D);
    if (isSelected) {
      return baseColor;
    }
    if (_isPressed || _isFocused) {
      return baseColor.withValues(alpha: 0.6);
    }
    if (_isHovered) {
      return baseColor.withValues(alpha: 0.3);
    }
    return baseColor.withValues(alpha: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return NakedRadio<RadioOption>(
      value: widget.value,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      builder: (context, states, child) {
        final isSelected = states.isSelected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor(isSelected),
              width: isSelected ? 6 : 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}
