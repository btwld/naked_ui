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
          child: PasswordAndMultiLineExample(),
        ),
      ),
    );
  }
}

class PasswordAndMultiLineExample extends StatefulWidget {
  const PasswordAndMultiLineExample({super.key});

  @override
  State<PasswordAndMultiLineExample> createState() => _PasswordAndMultiLineExampleState();
}

class _PasswordAndMultiLineExampleState extends State<PasswordAndMultiLineExample> {
  final _passwordController = TextEditingController();
  final _multiLineController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _multiLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Password & Multi-line Fields',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Password field
          _PasswordField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          
          const SizedBox(height: 24),
          
          // Multi-line field
          _MultiLineField(
            controller: _multiLineController,
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isFocused ? Colors.blue : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: editableText,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onToggleVisibility,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          widget.obscureText ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MultiLineField extends StatefulWidget {
  const _MultiLineField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_MultiLineField> createState() => _MultiLineFieldState();
}

class _MultiLineFieldState extends State<_MultiLineField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Multi-line Text',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          builder: (context, editableText) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isFocused ? Colors.blue : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: editableText,
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Expandable text area (3-6 lines)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}