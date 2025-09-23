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
          child: DialogExample(),
        ),
      ),
    );
  }
}

class DialogExample extends StatefulWidget {
  const DialogExample({super.key});

  @override
  State<DialogExample> createState() => _DialogExampleState();
}

class _DialogExampleState extends State<DialogExample> {
  String? _lastDialogResult;

  void _showBasicDialog() async {
    final result = await showNakedDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm Action',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to proceed with this action? This operation cannot be undone.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    backgroundColor: Colors.grey.shade100,
                    textColor: Colors.grey.shade700,
                    text: 'Cancel',
                  ),
                  const SizedBox(width: 12),
                  _DialogButton(
                    onPressed: () => Navigator.of(context).pop('confirm'),
                    backgroundColor: const Color(0xFF3D3D3D),
                    textColor: Colors.white,
                    text: 'Confirm',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lastDialogResult = result;
      });
    }
  }

  void _showCustomDialog() async {
    final result = await showNakedDialog<String>(
      context: context,
      barrierColor: const Color(0x80E3F2FD),
      barrierDismissible: true,
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 100),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your action was completed successfully.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _DialogButton(
                onPressed: () => Navigator.of(context).pop('success'),
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1976D2),
                text: 'Great!',
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lastDialogResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        _TriggerButton(
          onPressed: _showBasicDialog,
          text: 'Show Basic Dialog',
          description: 'Centered dialog with custom styling',
        ),
        _TriggerButton(
          onPressed: _showCustomDialog,
          text: 'Show Custom Dialog',
          description: 'Top-aligned dialog with gradient background',
        ),
        if (_lastDialogResult != null)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Last dialog result: $_lastDialogResult',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _TriggerButton extends StatefulWidget {
  const _TriggerButton({
    required this.onPressed,
    required this.text,
    required this.description,
  });

  final VoidCallback onPressed;
  final String text;
  final String description;

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      builder: (context, state, child) {
        const baseColor = Color(0xFF3D3D3D);
        final backgroundColor = state.when(
          pressed: baseColor.withValues(alpha: 0.8),
          hovered: baseColor.withValues(alpha: 0.9),
          orElse: baseColor,
        );

        final scale = state.isPressed ? 0.98 : 1.0;

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.text,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String text;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      builder: (context, state, child) {
        final backgroundColor = state.when(
          pressed: widget.backgroundColor.withValues(alpha: 0.8),
          hovered: widget.backgroundColor.withValues(alpha: 0.9),
          orElse: widget.backgroundColor,
        );

        final scale = state.isPressed ? 0.95 : 1.0;

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
