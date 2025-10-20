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
                'Simple TextField',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Interact with the textfield to see its states',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              TextFieldExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class TextFieldExample extends StatefulWidget {
  const TextFieldExample({super.key});

  @override
  State<TextFieldExample> createState() => _TextFieldExampleState();
}

class _TextFieldExampleState extends State<TextFieldExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: NakedTextField(
        cursorColor: Colors.grey.shade700,
        textStyle: WidgetStateProperty.fromMap({
          WidgetState.focused: const TextStyle(color: Colors.red),
          WidgetState.any: TextStyle(color: Colors.grey.shade400),
        }),
        builder: (context, state, editableText) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: state.when(
                pressed: Colors.white,
                focused: Colors.white,
                hovered: Colors.grey.shade200,
                orElse: Colors.white,
              ),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                if (state.isFocused)
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 3,
                    blurStyle: BlurStyle.outer,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: editableText,
          );
        },
      ),
    );
  }
}
