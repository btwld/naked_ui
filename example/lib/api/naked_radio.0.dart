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
  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF3D3D3D);

    return NakedRadio<RadioOption>(
      value: widget.value,
      builder: (context, state, child) {
        final borderColor = state.when(
          selected: baseColor,
          pressed: baseColor.withValues(alpha: 0.6),
          focused: baseColor.withValues(alpha: 0.6),
          hovered: baseColor.withValues(alpha: 0.3),
          orElse: baseColor.withValues(alpha: 0.2),
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: state.isSelected ? 6 : 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}
