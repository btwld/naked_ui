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
        backgroundColor: Colors.white,
        body: Center(
          child: MyCustomButton(
            text: 'Click me',
            onPressed: () {
              // ignore: avoid_print
              print('Button pressed!');
            },
          ),
        ),
      ),
    );
  }
}

class MyCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MyCustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, state, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: state.when(
            pressed: Colors.blue.shade800, // Darker when pressed
            hovered: Colors.blue.shade600, // Slightly darker when hovered
            orElse: Colors.blue.shade500, // Default color
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: state.isFocused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
