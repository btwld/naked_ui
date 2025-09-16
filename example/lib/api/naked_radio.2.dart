import 'package:flutter/material.dart';

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
          child: RadioGroupExample(),
        ),
      ),
    );
  }
}

class RadioGroupExample extends StatefulWidget {
  const RadioGroupExample({super.key});

  @override
  State<RadioGroupExample> createState() => _RadioGroupExampleState();
}

class _RadioGroupExampleState extends State<RadioGroupExample> {
  String? _selectedTheme = 'dark';
  String? _selectedSize = 'medium';
  String? _selectedPayment;

  bool _enableValidation = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Radio Button Groups',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Multiple radio groups with validation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Theme Selection
          _RadioGroup(
            title: 'Theme Preference',
            icon: Icons.palette,
            options: const [
              _RadioOption(
                  'light', 'Light Theme', 'Bright and clean interface'),
              _RadioOption('dark', 'Dark Theme', 'Easy on the eyes'),
              _RadioOption('auto', 'Auto', 'Matches system theme'),
            ],
            selectedValue: _selectedTheme,
            onChanged: (value) => setState(() => _selectedTheme = value),
            color: Colors.blue,
          ),

          const SizedBox(height: 32),

          // Size Selection
          _RadioGroup(
            title: 'Content Size',
            icon: Icons.text_fields,
            options: const [
              _RadioOption('small', 'Small', 'Compact layout'),
              _RadioOption('medium', 'Medium', 'Standard size'),
              _RadioOption('large', 'Large', 'More spacious'),
            ],
            selectedValue: _selectedSize,
            onChanged: (value) => setState(() => _selectedSize = value),
            color: Colors.green,
          ),

          const SizedBox(height: 32),

          // Payment Method (with validation)
          _RadioGroup(
            title: 'Payment Method',
            icon: Icons.payment,
            options: const [
              _RadioOption('card', 'Credit Card', 'Visa, MasterCard, etc.'),
              _RadioOption('paypal', 'PayPal', 'Quick and secure'),
              _RadioOption('bank', 'Bank Transfer', 'Direct bank payment'),
            ],
            selectedValue: _selectedPayment,
            onChanged: (value) => setState(() => _selectedPayment = value),
            color: Colors.orange,
            isRequired: _enableValidation,
            errorText: _enableValidation && _selectedPayment == null
                ? 'Please select a payment method'
                : null,
          ),

          const SizedBox(height: 32),

          // Validation toggle
          Row(
            children: [
              Checkbox(
                value: _enableValidation,
                onChanged: (value) =>
                    setState(() => _enableValidation = value ?? false),
              ),
              const SizedBox(width: 8),
              const Text('Enable validation for payment method'),
            ],
          ),

          const SizedBox(height: 32),

          // Summary
          _SelectionSummary(
            theme: _selectedTheme,
            size: _selectedSize,
            payment: _selectedPayment,
          ),
        ],
      ),
    );
  }
}

class _RadioOption {
  const _RadioOption(this.value, this.title, this.subtitle);

  final String value;
  final String title;
  final String subtitle;
}

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.color,
    this.isRequired = false,
    this.errorText,
  });

  final String title;
  final IconData icon;
  final List<_RadioOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final Color color;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red.shade300 : color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasError
                      ? Colors.red.shade100
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: hasError ? Colors.red.shade700 : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasError
                                ? Colors.red.shade700
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errorText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Options
          ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CustomRadioTile(
                  option: option,
                  isSelected: selectedValue == option.value,
                  onTap: () => onChanged(option.value),
                  color: hasError ? Colors.red : color,
                ),
              )),
        ],
      ),
    );
  }
}

class _CustomRadioTile extends StatefulWidget {
  const _CustomRadioTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final _RadioOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_CustomRadioTile> createState() => _CustomRadioTileState();
}

class _CustomRadioTileState extends State<_CustomRadioTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.1)
                : _isHovered
                    ? Colors.grey.shade50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? widget.color : Colors.grey.shade300,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        widget.isSelected ? widget.color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.option.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: widget.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.theme,
    required this.size,
    required this.payment,
  });

  final String? theme;
  final String? size;
  final String? payment;

  @override
  Widget build(BuildContext context) {
    final hasSelections = theme != null || size != null || payment != null;

    if (!hasSelections) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Make your selections to see the summary',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: Colors.purple.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Selections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (theme != null)
            _SummaryItem(
              icon: Icons.palette,
              label: 'Theme',
              value: _getThemeLabel(theme!),
            ),
          if (size != null)
            _SummaryItem(
              icon: Icons.text_fields,
              label: 'Size',
              value: _getSizeLabel(size!),
            ),
          if (payment != null)
            _SummaryItem(
              icon: Icons.payment,
              label: 'Payment',
              value: _getPaymentLabel(payment!),
            ),
        ],
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light Theme';
      case 'dark':
        return 'Dark Theme';
      case 'auto':
        return 'Auto Theme';
      default:
        return theme;
    }
  }

  String _getSizeLabel(String size) {
    switch (size) {
      case 'small':
        return 'Small Size';
      case 'medium':
        return 'Medium Size';
      case 'large':
        return 'Large Size';
      default:
        return size;
    }
  }

  String _getPaymentLabel(String payment) {
    switch (payment) {
      case 'card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'bank':
        return 'Bank Transfer';
      default:
        return payment;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.purple.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
