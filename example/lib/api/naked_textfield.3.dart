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
          child: ReadOnlySubmissionExample(),
        ),
      ),
    );
  }
}

class ReadOnlySubmissionExample extends StatefulWidget {
  const ReadOnlySubmissionExample({super.key});

  @override
  State<ReadOnlySubmissionExample> createState() => _ReadOnlySubmissionExampleState();
}

class _ReadOnlySubmissionExampleState extends State<ReadOnlySubmissionExample> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isReadOnly = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Sample Article Title';
    _descriptionController.text = 'This is a sample article description that demonstrates read-only mode.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Read-Only & Submission Demo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              _ReadOnlyToggle(
                isReadOnly: _isReadOnly,
                onToggle: () => setState(() => _isReadOnly = !_isReadOnly),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Title field
          _TextField(
            label: 'Title',
            controller: _titleController,
            readOnly: _isReadOnly,
          ),
          
          const SizedBox(height: 24),
          
          // Description field
          _TextField(
            label: 'Description',
            controller: _descriptionController,
            readOnly: _isReadOnly,
            maxLines: 4,
          ),
          
          const SizedBox(height: 32),
          
          // Submit button or read-only info
          if (!_isReadOnly)
            _SubmitButton(
              onPressed: _handleSubmit,
              isSubmitting: _isSubmitting,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Content is in read-only mode. Toggle to enable editing.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyToggle extends StatelessWidget {
  const _ReadOnlyToggle({
    required this.isReadOnly,
    required this.onToggle,
  });

  final bool isReadOnly;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isReadOnly ? Colors.orange.shade50 : Colors.blue.shade50,
          border: Border.all(
            color: isReadOnly ? Colors.orange.shade300 : Colors.blue.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReadOnly ? Icons.visibility : Icons.edit,
              size: 16,
              color: isReadOnly ? Colors.orange.shade700 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              isReadOnly ? 'Read Only' : 'Editable',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isReadOnly ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    required this.controller,
    required this.readOnly,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.readOnly ? Colors.grey.shade500 : const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                color: widget.readOnly ? Colors.grey.shade50 : Colors.white,
                border: Border.all(
                  color: widget.readOnly
                      ? Colors.grey.shade200
                      : _isFocused
                          ? Colors.blue
                          : Colors.grey.shade300,
                  width: _isFocused && !widget.readOnly ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: editableText,
              ),
            );
          },
          style: TextStyle(
            fontSize: 14,
            color: widget.readOnly ? Colors.grey.shade700 : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.onPressed,
    required this.isSubmitting,
  });

  final VoidCallback onPressed;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSubmitting ? Colors.blue.shade300 : Colors.blue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!isSubmitting)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit Article',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}