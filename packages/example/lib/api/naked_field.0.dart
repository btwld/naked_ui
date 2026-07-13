import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

const fieldEmailKey = ValueKey<String>('field.email');
const fieldEmailLabelKey = ValueKey<String>('field.email.label');
const fieldEmailControlKey = ValueKey<String>('field.email.control');
const fieldEmailDescriptionKey = ValueKey<String>('field.email.description');
const fieldEmailErrorKey = ValueKey<String>('field.email.error');
const fieldEmailSubmitKey = ValueKey<String>('field.email.submit');
const fieldEmailStateKey = ValueKey<String>('field.email.state');
const fieldEmailResetKey = ValueKey<String>('field.email.reset');

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
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Center(child: FieldExample()),
          ),
        ),
      ),
    );
  }
}

class FieldExample extends StatefulWidget {
  const FieldExample({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.initialValue = '',
    this.label = 'Email address',
    this.description = 'Use the address where we can reach you.',
    this.requiredError = 'Enter an email address.',
    this.invalidError = 'Enter a valid email address.',
  });

  final bool enabled;
  final bool readOnly;
  final String initialValue;
  final String label;
  final String description;
  final String requiredError;
  final String invalidError;

  @override
  State<FieldExample> createState() => _FieldExampleState();
}

class _FieldExampleState extends State<FieldExample> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _submitted = false;

  SemanticsValidationResult get _validationResult {
    if (!_submitted) return SemanticsValidationResult.none;
    return _errorText == null
        ? SemanticsValidationResult.valid
        : SemanticsValidationResult.invalid;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final candidate = value.trim();
    if (candidate.isEmpty) return widget.requiredError;

    final at = candidate.indexOf('@');
    final dot = candidate.lastIndexOf('.');
    if (at <= 0 || dot <= at + 1 || dot == candidate.length - 1) {
      return widget.invalidError;
    }
    return null;
  }

  void _handleChanged(String value) {
    if (!_submitted) return;
    setState(() => _errorText = _validate(value));
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _errorText = _validate(_controller.text);
    });
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _submitted = false;
      _errorText = null;
    });
  }

  String _stateSummary(NakedFieldState state) {
    return <String>[
      state.isFocused ? 'focused' : 'unfocused',
      state.isFilled ? 'filled' : 'empty',
      if (state.isDisabled)
        'disabled'
      else if (state.isReadOnly)
        'read-only'
      else
        'editable',
      state.validationResult.name,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              'Semantic email field',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              'Validation remains application-owned while Field coordinates '
              'metadata and control state.',
            ),
          ),
          const SizedBox(height: 24),
          NakedField(
            key: fieldEmailKey,
            label: widget.label,
            description: widget.description,
            errorText: _errorText,
            isRequired: true,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            validationResult: _validationResult,
            builder: (context, state, _) {
              final borderColor = state.isError
                  ? Colors.red.shade700
                  : state.isFocused
                  ? Colors.blue.shade700
                  : Colors.grey.shade400;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NakedFieldLabel(
                    key: fieldEmailLabelKey,
                    child: Text(
                      '${widget.label} *',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  NakedTextField(
                    key: fieldEmailControlKey,
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onChanged: _handleChanged,
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 16),
                    builder: (context, _, editable) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: state.isDisabled
                                ? Colors.grey.shade200
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            child: editable,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  NakedFieldDescription(
                    key: fieldEmailDescriptionKey,
                    child: Text(
                      widget.description,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  NakedFieldError(
                    key: fieldEmailErrorKey,
                    child: Text(
                      _errorText ?? '',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExcludeSemantics(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _stateSummary(state),
                        key: fieldEmailStateKey,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                key: fieldEmailSubmitKey,
                onPressed: widget.enabled ? _submit : null,
                child: const Text('Submit'),
              ),
              TextButton(
                key: fieldEmailResetKey,
                onPressed: widget.enabled && !widget.readOnly ? _reset : null,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
