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
          child: TristateCheckboxExample(),
        ),
      ),
    );
  }
}

class TristateCheckboxExample extends StatefulWidget {
  const TristateCheckboxExample({super.key});

  @override
  State<TristateCheckboxExample> createState() => _TristateCheckboxExampleState();
}

class _TristateCheckboxExampleState extends State<TristateCheckboxExample> {
  bool? _mainCheckboxValue = false;
  
  // Child checkboxes for the main example
  bool _option1 = false;
  bool _option2 = true;
  bool _option3 = false;
  
  // Individual tristate checkbox
  bool? _individualTristate;
  
  // Form validation checkboxes
  bool _required1 = false;
  bool _required2 = false;
  bool _required3 = false;

  void _updateMainCheckbox() {
    final checkedCount = [_option1, _option2, _option3].where((v) => v).length;
    
    setState(() {
      if (checkedCount == 0) {
        _mainCheckboxValue = false;
      } else if (checkedCount == 3) {
        _mainCheckboxValue = true;
      } else {
        _mainCheckboxValue = null; // Indeterminate
      }
    });
  }

  void _onMainCheckboxChanged(bool? value) {
    setState(() {
      _mainCheckboxValue = value;
      // Update all child checkboxes based on main checkbox state
      if (value == true) {
        _option1 = true;
        _option2 = true;
        _option3 = true;
      } else if (value == false) {
        _option1 = false;
        _option2 = false;
        _option3 = false;
      }
      // If null, we don't change the individual states
    });
  }

  void _onOption1Changed(bool? value) {
    setState(() {
      _option1 = value ?? false;
      _updateMainCheckbox();
    });
  }

  void _onOption2Changed(bool? value) {
    setState(() {
      _option2 = value ?? false;
      _updateMainCheckbox();
    });
  }

  void _onOption3Changed(bool? value) {
    setState(() {
      _option3 = value ?? false;
      _updateMainCheckbox();
    });
  }

  void _onIndividualTristateChanged(bool? value) {
    setState(() {
      _individualTristate = value;
    });
  }

  bool get _allRequiredSelected {
    return _required1 && _required2 && _required3;
  }

  bool? get _requiredGroupState {
    final checkedCount = [_required1, _required2, _required3].where((v) => v).length;
    
    if (checkedCount == 0) return false;
    if (checkedCount == 3) return true;
    return null; // Indeterminate
  }

  @override
  void initState() {
    super.initState();
    _updateMainCheckbox();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tristate Checkbox Examples',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Checkboxes that support true, false, and indeterminate states',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Main hierarchical checkbox example
          _HierarchicalCheckboxGroup(
            mainValue: _mainCheckboxValue,
            option1: _option1,
            option2: _option2,
            option3: _option3,
            onMainChanged: _onMainCheckboxChanged,
            onOption1Changed: _onOption1Changed,
            onOption2Changed: _onOption2Changed,
            onOption3Changed: _onOption3Changed,
          ),
          
          const SizedBox(height: 32),
          
          // Individual tristate checkbox
          _IndividualTristateSection(
            value: _individualTristate,
            onChanged: _onIndividualTristateChanged,
          ),
          
          const SizedBox(height: 32),
          
          // Form validation example
          _FormValidationExample(
            required1: _required1,
            required2: _required2,
            required3: _required3,
            groupState: _requiredGroupState,
            allRequiredSelected: _allRequiredSelected,
            onRequired1Changed: (value) => setState(() => _required1 = value ?? false),
            onRequired2Changed: (value) => setState(() => _required2 = value ?? false),
            onRequired3Changed: (value) => setState(() => _required3 = value ?? false),
          ),
          
          const SizedBox(height: 32),
          
          // State explanation
          const _StateExplanation(),
        ],
      ),
    );
  }
}

class _HierarchicalCheckboxGroup extends StatelessWidget {
  const _HierarchicalCheckboxGroup({
    required this.mainValue,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.onMainChanged,
    required this.onOption1Changed,
    required this.onOption2Changed,
    required this.onOption3Changed,
  });

  final bool? mainValue;
  final bool option1;
  final bool option2;
  final bool option3;
  final ValueChanged<bool?> onMainChanged;
  final ValueChanged<bool?> onOption1Changed;
  final ValueChanged<bool?> onOption2Changed;
  final ValueChanged<bool?> onOption3Changed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hierarchical Selection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main parent checkbox
          _TristateCheckboxTile(
            value: mainValue,
            tristate: true,
            onChanged: onMainChanged,
            title: 'Select All Options',
            subtitle: _getMainSubtitle(mainValue),
            isParent: true,
          ),
          
          const SizedBox(height: 12),
          
          // Child checkboxes with indentation
          Container(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                _TristateCheckboxTile(
                  value: option1,
                  tristate: false,
                  onChanged: onOption1Changed,
                  title: 'Option 1',
                  subtitle: 'First sub-option',
                ),
                _TristateCheckboxTile(
                  value: option2,
                  tristate: false,
                  onChanged: onOption2Changed,
                  title: 'Option 2',
                  subtitle: 'Second sub-option',
                ),
                _TristateCheckboxTile(
                  value: option3,
                  tristate: false,
                  onChanged: onOption3Changed,
                  title: 'Option 3',
                  subtitle: 'Third sub-option',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMainSubtitle(bool? value) {
    if (value == true) return 'All options selected';
    if (value == false) return 'No options selected';
    return 'Some options selected (indeterminate)';
  }
}

class _IndividualTristateSection extends StatelessWidget {
  const _IndividualTristateSection({
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.toggle_off,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Individual Tristate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _TristateCheckboxTile(
            value: value,
            tristate: true,
            onChanged: onChanged,
            title: 'Tristate Checkbox',
            subtitle: 'Cycles through: false → true → null → false',
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.green.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current state: ${_getStateDescription(value)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStateDescription(bool? value) {
    if (value == true) return 'true (checked)';
    if (value == false) return 'false (unchecked)';
    return 'null (indeterminate/mixed)';
  }
}

class _FormValidationExample extends StatelessWidget {
  const _FormValidationExample({
    required this.required1,
    required this.required2,
    required this.required3,
    required this.groupState,
    required this.allRequiredSelected,
    required this.onRequired1Changed,
    required this.onRequired2Changed,
    required this.onRequired3Changed,
  });

  final bool required1;
  final bool required2;
  final bool required3;
  final bool? groupState;
  final bool allRequiredSelected;
  final ValueChanged<bool?> onRequired1Changed;
  final ValueChanged<bool?> onRequired2Changed;
  final ValueChanged<bool?> onRequired3Changed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Validation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Required fields (all must be selected):',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          _TristateCheckboxTile(
            value: required1,
            tristate: false,
            onChanged: onRequired1Changed,
            title: 'Terms of Service *',
            subtitle: 'I agree to the terms and conditions',
            isRequired: true,
          ),
          _TristateCheckboxTile(
            value: required2,
            tristate: false,
            onChanged: onRequired2Changed,
            title: 'Privacy Policy *',
            subtitle: 'I acknowledge the privacy policy',
            isRequired: true,
          ),
          _TristateCheckboxTile(
            value: required3,
            tristate: false,
            onChanged: onRequired3Changed,
            title: 'Age Confirmation *',
            subtitle: 'I confirm I am 18 years or older',
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: allRequiredSelected 
                ? Colors.green.shade100 
                : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: allRequiredSelected 
                  ? Colors.green.shade300
                  : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allRequiredSelected ? Icons.check_circle : Icons.error,
                  size: 20,
                  color: allRequiredSelected 
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allRequiredSelected 
                      ? 'Form validation passed! All required fields selected.'
                      : 'Form validation failed. Please select all required fields.',
                    style: TextStyle(
                      fontSize: 12,
                      color: allRequiredSelected 
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
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

class _TristateCheckboxTile extends StatefulWidget {
  const _TristateCheckboxTile({
    required this.value,
    required this.tristate,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    this.isParent = false,
    this.isRequired = false,
  });

  final bool? value;
  final bool tristate;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;
  final bool isParent;
  final bool isRequired;

  @override
  State<_TristateCheckboxTile> createState() => _TristateCheckboxTileState();
}

class _TristateCheckboxTileState extends State<_TristateCheckboxTile> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color get backgroundColor {
    if (_isPressed) {
      return Colors.grey.shade200;
    }
    if (_isHovered) {
      return Colors.grey.shade100;
    }
    return Colors.transparent;
  }

  Color get checkboxColor {
    if (widget.isParent) return const Color(0xFF2196F3);
    if (widget.isRequired) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  Color get borderColor {
    if (widget.value == true) {
      return checkboxColor;
    }
    if (_isFocused) {
      return checkboxColor.withValues(alpha: 0.8);
    }
    if (_isHovered || _isPressed) {
      return checkboxColor.withValues(alpha: 0.6);
    }
    return checkboxColor.withValues(alpha: 0.4);
  }

  IconData get checkboxIcon {
    if (widget.value == true) {
      return Icons.check_box;
    } else if (widget.value == null) {
      return Icons.indeterminate_check_box;
    } else {
      return Icons.check_box_outline_blank;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedCheckbox(
        value: widget.value,
        tristate: widget.tristate,
        onChanged: widget.onChanged,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHoverChange: (hovered) => setState(() => _isHovered = hovered),
        onPressChange: (pressed) => setState(() => _isPressed = pressed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused 
                ? checkboxColor
                : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.value == true ? checkboxColor : Colors.transparent,
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: widget.value == true
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : widget.value == null
                    ? Icon(
                        Icons.remove,
                        size: 16,
                        color: checkboxColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: widget.isParent ? 16 : 14,
                              fontWeight: widget.isParent 
                                ? FontWeight.bold 
                                : FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (widget.isRequired)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateExplanation extends StatelessWidget {
  const _StateExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tristate Checkbox States',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _StateExplanationItem(
            icon: Icons.check_box,
            state: 'true (checked)',
            description: 'The checkbox is selected/checked',
            example: 'User has explicitly selected this option',
          ),
          const _StateExplanationItem(
            icon: Icons.check_box_outline_blank,
            state: 'false (unchecked)',
            description: 'The checkbox is unselected/unchecked',
            example: 'User has not selected this option',
          ),
          const _StateExplanationItem(
            icon: Icons.indeterminate_check_box,
            state: 'null (indeterminate)',
            description: 'The checkbox is in a mixed/indeterminate state',
            example: 'Some child options are selected, but not all',
          ),
        ],
      ),
    );
  }
}

class _StateExplanationItem extends StatelessWidget {
  const _StateExplanationItem({
    required this.icon,
    required this.state,
    required this.description,
    required this.example,
  });

  final IconData icon;
  final String state;
  final String description;
  final String example;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
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