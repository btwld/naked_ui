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
        body: Center(child: SimpleBuilderExample()),
      ),
    );
  }
}

class SimpleBuilderExample extends StatelessWidget {
  const SimpleBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: () => debugPrint('Pressed'),
      builder: (context, state, child) {
        debugPrint('is pressed: ${state.isPressed}');
        final color = state.when(
          pressed: Colors.red,
          hovered: Colors.yellow,
          orElse: Colors.green,
        );
        return Container(color: color, child: const Text('Custom Button'));
      },
    );
  }
}
