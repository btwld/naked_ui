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
          child: TextFieldExample(),
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
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        builder: (context, editableText) {
          return Builder(
            builder: (context) {
              final state = NakedTextFieldState.of(context);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        color: Colors.grey.shade100,
                        spreadRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: editableText,
              );
            },
          );
        },
      ),
    );
  }
}
