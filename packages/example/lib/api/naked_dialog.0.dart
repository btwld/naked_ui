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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simple Dialog',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Click the buttons to present a dialog',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              DialogExample(),
            ],
          ),
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
  void _showBasicDialog() async {
    await showNakedDialog<String>(
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
                    key: const ValueKey('dialog.basic.cancel'),
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    backgroundColor: Colors.grey.shade100,
                    textColor: Colors.grey.shade700,
                    text: 'Cancel',
                  ),
                  const SizedBox(width: 12),
                  _DialogButton(
                    key: const ValueKey('dialog.basic.confirm'),
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
  }

  void _showCustomDialog() async {
    await showNakedDialog<String>(
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
              const Icon(Icons.star, size: 48, color: Colors.white),
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
                style: TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _DialogButton(
                key: const ValueKey('dialog.custom.close'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        _TriggerButton(
          key: const ValueKey('dialog.open.basic'),
          onPressed: _showBasicDialog,
          text: 'Show Basic Dialog',
          description: 'Centered dialog with custom styling',
        ),
        _TriggerButton(
          key: const ValueKey('dialog.open.custom'),
          onPressed: _showCustomDialog,
          text: 'Show Custom Dialog',
          description: 'Top-aligned dialog with gradient background',
        ),
      ],
    );
  }
}

class AlertDialogExample extends StatefulWidget {
  const AlertDialogExample({
    super.key,
    this.longMessage = false,
    this.transitionDuration = Duration.zero,
  });

  final bool longMessage;
  final Duration transitionDuration;

  @override
  State<AlertDialogExample> createState() => _AlertDialogExampleState();
}

class _AlertDialogExampleState extends State<AlertDialogExample> {
  final _openFocusNode = FocusNode(debugLabel: 'alert dialog open');
  final _removeInvokerFocusNode = FocusNode(
    debugLabel: 'alert dialog removable invoker',
  );
  final _cancelFocusNode = FocusNode(debugLabel: 'alert dialog cancel');
  final _confirmFocusNode = FocusNode(debugLabel: 'alert dialog confirm');
  final _messageFocusNode = FocusNode(debugLabel: 'alert dialog message');

  String _result = 'none';
  int _confirmations = 0;
  bool _showRemoveInvoker = true;

  static const _shortMessage =
      'Deleting this project removes its local configuration and cannot be undone.';
  static const _longMessage =
      'Deleting this project permanently removes its local configuration, saved views, '
      'automation rules, and collaborator preferences. Review the affected resources '
      'before continuing. This operation cannot be undone after confirmation.';

  @override
  void dispose() {
    _openFocusNode.dispose();
    _removeInvokerFocusNode.dispose();
    _cancelFocusNode.dispose();
    _confirmFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showAlert({bool removeInvoker = false}) async {
    final result = showNakedAlertDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      semanticLabel: 'Delete project',
      transitionDuration: widget.transitionDuration,
      initialFocusNode: widget.longMessage
          ? _messageFocusNode
          : _cancelFocusNode,
      builder: (context) => Center(
        child: Container(
          key: const ValueKey('alert-dialog.surface'),
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete project',
                key: ValueKey('alert-dialog.title'),
                style: TextStyle(
                  color: Color(0xFF18181B),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: _buildMessage())),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AlertDialogButton(
                    key: const ValueKey('alert-dialog.cancel'),
                    focusNode: _cancelFocusNode,
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    backgroundColor: const Color(0xFFF4F4F5),
                    textColor: const Color(0xFF27272A),
                    text: 'Cancel',
                  ),
                  _AlertDialogButton(
                    key: const ValueKey('alert-dialog.confirm'),
                    focusNode: _confirmFocusNode,
                    onPressed: () {
                      setState(() => _confirmations += 1);
                      Navigator.of(context).pop('confirm');
                    },
                    backgroundColor: const Color(0xFFB42318),
                    textColor: Colors.white,
                    text: 'Delete project',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (removeInvoker && mounted) {
      setState(() => _showRemoveInvoker = false);
    }
    final resolvedResult = await result;
    if (!mounted) return;
    setState(() => _result = resolvedResult ?? 'dismissed');
  }

  Widget _buildMessage() {
    final message = Semantics(
      key: const ValueKey('alert-dialog.message'),
      container: true,
      child: Text(
        widget.longMessage ? _longMessage : _shortMessage,
        style: const TextStyle(
          color: Color(0xFF3F3F46),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
    if (!widget.longMessage) return message;

    return Focus(
      key: const ValueKey('alert-dialog.message-focus'),
      focusNode: _messageFocusNode,
      child: Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            border: Focus.of(context).hasFocus
                ? Border.all(color: const Color(0xFF2563EB), width: 3)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(padding: const EdgeInsets.all(4), child: message),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _result = 'none';
      _confirmations = 0;
      _showRemoveInvoker = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _TriggerButton(
          key: const ValueKey('alert-dialog.open'),
          focusNode: _openFocusNode,
          onPressed: _showAlert,
          text: 'Delete project',
          description: 'Safe focus starts on Cancel',
        ),
        if (_showRemoveInvoker)
          _TriggerButton(
            key: const ValueKey('alert-dialog.remove-invoker'),
            focusNode: _removeInvokerFocusNode,
            onPressed: () => _showAlert(removeInvoker: true),
            text: 'Open and remove trigger',
            description: 'Exercises safe focus restoration',
          ),
        Text(
          'Result: $_result; confirmations: $_confirmations',
          key: const ValueKey('alert-dialog.result'),
          style: const TextStyle(color: Color(0xFF27272A)),
        ),
        _TriggerButton(
          key: const ValueKey('alert-dialog.reset'),
          onPressed: _reset,
          text: 'Reset alert fixture',
          description: 'Restores deterministic state',
        ),
      ],
    );
  }
}

class _TriggerButton extends StatefulWidget {
  const _TriggerButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.description,
    this.focusNode,
  });

  final VoidCallback onPressed;
  final String text;
  final String description;
  final FocusNode? focusNode;

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  @override
  Widget build(BuildContext context) {
    return NakedButton(
      focusNode: widget.focusNode,
      onPressed: widget.onPressed,
      builder: (context, state, child) {
        const baseColor = Color(0xFF3D3D3D);
        final backgroundColor = state.when(
          pressed: baseColor.withValues(alpha: 0.8),
          hovered: baseColor.withValues(alpha: 0.9),
          orElse: baseColor,
        );

        final scale = state.isPressed ? 0.98 : 1.0;

        final scaleDuration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150);
        final colorDuration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200);

        return AnimatedScale(
          scale: scale,
          duration: scaleDuration,
          child: AnimatedContainer(
            duration: colorDuration,
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
    super.key,
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

class _AlertDialogButton extends StatelessWidget {
  const _AlertDialogButton({
    super.key,
    required this.focusNode,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.text,
  });

  final FocusNode focusNode;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      focusNode: focusNode,
      onPressed: onPressed,
      builder: (context, state, child) {
        final effectiveBackground = state.when(
          pressed: backgroundColor.withValues(alpha: 0.8),
          hovered: backgroundColor.withValues(alpha: 0.9),
          orElse: backgroundColor,
        );
        final duration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150);

        return AnimatedScale(
          scale: state.isPressed ? 0.95 : 1,
          duration: duration,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: state.isFocused
                  ? Border.all(color: const Color(0xFF2563EB), width: 3)
                  : null,
            ),
            child: AnimatedContainer(
              duration: duration,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: effectiveBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
