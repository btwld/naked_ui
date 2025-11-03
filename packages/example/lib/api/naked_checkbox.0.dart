import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

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
                'Simple Checkbox',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Interact with the checkbox to see its states',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              CheckboxExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckboxExample extends StatefulWidget {
  const CheckboxExample({super.key});

  @override
  State<CheckboxExample> createState() => _CheckboxExampleState();
}

class _CheckboxExampleState extends State<CheckboxExample> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF3D3D3D);

    return NakedCheckbox(
      value: _isChecked,
      onChanged: (value) {
        setState(() {
          _isChecked = value!;
        });
      },
      builder: (context, state, child) {
        final borderColor = state.when(
          focused: _isChecked ? baseColor : baseColor.withValues(alpha: 0.8),
          hovered: _isChecked ? baseColor : baseColor.withValues(alpha: 0.6),
          pressed: _isChecked ? baseColor : baseColor.withValues(alpha: 0.6),
          orElse: _isChecked ? baseColor : baseColor.withValues(alpha: 0.4),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
                color: state.isChecked == true ? baseColor : Colors.transparent,
              ),
              child: state.isChecked == true
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const Text(
              'Label',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: baseColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
