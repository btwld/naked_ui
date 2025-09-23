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
          child: ButtonExample(),
        ),
      ),
    );
  }
}

class ButtonExample extends StatelessWidget {
  const ButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () {
        debugPrint('Button pressed!');
      },
      builder: (context, buttonState, child) {
        const baseColor = Color(0xFF3D3D3D);

        final backgroundColor = buttonState.when(
          pressed: baseColor.withValues(alpha: 0.8),
          hovered: baseColor.withValues(alpha: 0.9),
          orElse: baseColor,
        );

        final scale = buttonState.isPressed ? 0.95 : 1.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: buttonState.isFocused ? Colors.black : Colors.transparent,
              width: 1,
            ),
          ),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Button',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
