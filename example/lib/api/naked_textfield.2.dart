import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          child: ValidationExample(),
        ),
      ),
    );
  }
}

class ValidationExample extends StatefulWidget {
  const ValidationExample({super.key});

  @override
  State<ValidationExample> createState() => _ValidationExampleState();
}

class _ValidationExampleState extends State<ValidationExample> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _creditCardController = TextEditingController();
  final _urlController = TextEditingController();

  String? _emailError;
  String? _phoneError;
  String? _creditCardError;
  String? _urlError;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _creditCardController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (digits.length != 10) {
        _phoneError = 'Phone must be 10 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validateCreditCard(String value) {
    setState(() {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        _creditCardError = 'Card number is required';
      } else if (digits.length != 16) {
        _creditCardError = 'Card must be 16 digits';
      } else if (!_isValidLuhn(digits)) {
        _creditCardError = 'Invalid card number';
      } else {
        _creditCardError = null;
      }
    });
  }

  bool _isValidLuhn(String digits) {
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  void _validateUrl(String value) {
    setState(() {
      if (value.isEmpty) {
        _urlError = 'URL is required';
      } else if (!Uri.tryParse(value)!.hasAbsolutePath &&
          !value.startsWith('http')) {
        _urlError = 'Please enter a valid URL';
      } else {
        _urlError = null;
      }
    });
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
            'Form Validation & Formatters',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _EmailField(
            controller: _emailController,
            error: _emailError,
            onChanged: _validateEmail,
          ),
          const SizedBox(height: 24),
          _PhoneField(
            controller: _phoneController,
            error: _phoneError,
            onChanged: _validatePhone,
          ),
          const SizedBox(height: 24),
          _CreditCardField(
            controller: _creditCardController,
            error: _creditCardError,
            onChanged: _validateCreditCard,
          ),
          const SizedBox(height: 24),
          _UrlField(
            controller: _urlController,
            error: _urlError,
            onChanged: _validateUrl,
          ),
          const SizedBox(height: 32),
          _SubmitButton(
            onPressed: () {
              _validateEmail(_emailController.text);
              _validatePhone(_phoneController.text);
              _validateCreditCard(_creditCardController.text);
              _validateUrl(_urlController.text);

              if (_emailError == null &&
                  _phoneError == null &&
                  _creditCardError == null &&
                  _urlError == null &&
                  _emailController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty &&
                  _creditCardController.text.isNotEmpty &&
                  _urlController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Form submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatefulWidget {
  const _EmailField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<_EmailField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onChanged: widget.onChanged,
          keyboardType: TextInputType.emailAddress,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            LengthLimitingTextInputFormatter(100),
          ],
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : _isFocused
                          ? Colors.blue
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 20, color: Color(0xFF999999)),
                    const SizedBox(width: 12),
                    Expanded(child: editableText),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhoneField extends StatefulWidget {
  const _PhoneField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onChanged: widget.onChanged,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _PhoneNumberFormatter(),
          ],
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : _isFocused
                          ? Colors.blue
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 20, color: Color(0xFF999999)),
                    const SizedBox(width: 12),
                    Expanded(child: editableText),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CreditCardField extends StatefulWidget {
  const _CreditCardField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_CreditCardField> createState() => _CreditCardFieldState();
}

class _CreditCardFieldState extends State<_CreditCardField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credit Card Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onChanged: widget.onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CreditCardFormatter(),
          ],
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : _isFocused
                          ? Colors.blue
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_outlined,
                        size: 20, color: Color(0xFF999999)),
                    const SizedBox(width: 12),
                    Expanded(child: editableText),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _UrlField extends StatefulWidget {
  const _UrlField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_UrlField> createState() => _UrlFieldState();
}

class _UrlFieldState extends State<_UrlField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Website URL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        NakedTextField(
          controller: widget.controller,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onChanged: widget.onChanged,
          keyboardType: TextInputType.url,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            LengthLimitingTextInputFormatter(200),
          ],
          builder: (context, editableText) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : _isFocused
                          ? Colors.blue
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.link_outlined,
                        size: 20, color: Color(0xFF999999)),
                    const SizedBox(width: 12),
                    Expanded(child: editableText),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;

    if (newText.isNotEmpty) {
      buffer.write('(');
      if (newValue.selection.end >= 1) selectionIndex++;
    }
    if (newText.length >= 4) {
      buffer.write('${newText.substring(0, 3)}) ');
      if (newValue.selection.end >= 3) selectionIndex += 2;
      usedSubstringIndex = 3;
    }
    if (newText.length >= 7) {
      buffer.write('${newText.substring(3, 6)}-');
      if (newValue.selection.end >= 6) selectionIndex++;
      usedSubstringIndex = 6;
    }
    if (newText.length >= usedSubstringIndex) {
      buffer.write(newText.substring(usedSubstringIndex));
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _CreditCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
        if (i <= newValue.selection.end) selectionIndex++;
      }
      buffer.write(newText[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onPressed,
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.blue.shade700 : Colors.blue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: const Center(
          child: Text(
            'Submit Form',
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
