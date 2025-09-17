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
          child: CheckboxBuilderExample(),
        ),
      ),
    );
  }
}

class CheckboxBuilderExample extends StatefulWidget {
  const CheckboxBuilderExample({super.key});

  @override
  State<CheckboxBuilderExample> createState() => _CheckboxBuilderExampleState();
}

class _CheckboxBuilderExampleState extends State<CheckboxBuilderExample> {
  bool _materialCheckbox = false;
  bool _customShapeCheckbox = true;
  bool _animatedCheckbox = false;

  String _selectedStyle = 'Material';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Checkbox Builder Patterns',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Custom checkbox styling with builder pattern',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Style selector
          _StyleSelector(
            selectedStyle: _selectedStyle,
            onStyleChanged: (style) => setState(() => _selectedStyle = style),
          ),

          const SizedBox(height: 32),

          // Material Design style
          if (_selectedStyle == 'Material') ...[
            const _SectionHeader(
              icon: Icons.design_services,
              title: 'Material Design Style',
              subtitle: 'Clean, standard Material Design checkboxes',
            ),
            const SizedBox(height: 16),
            _MaterialStyleCheckbox(
              value: _materialCheckbox,
              onChanged: (value) => setState(() => _materialCheckbox = value),
              label: 'Accept terms and conditions',
            ),
          ],

          // Custom Shape style
          if (_selectedStyle == 'Custom Shape') ...[
            const _SectionHeader(
              icon: Icons.star,
              title: 'Custom Shape Style',
              subtitle: 'Creative shapes and custom styling',
            ),
            const SizedBox(height: 16),
            _CustomShapeCheckbox(
              value: _customShapeCheckbox,
              onChanged: (value) =>
                  setState(() => _customShapeCheckbox = value),
              label: 'Enable notifications',
            ),
          ],

          // Animated style
          if (_selectedStyle == 'Animated') ...[
            const _SectionHeader(
              icon: Icons.animation,
              title: 'Animated Style',
              subtitle: 'Smooth animations and transitions',
            ),
            const SizedBox(height: 16),
            _AnimatedCheckbox(
              value: _animatedCheckbox,
              onChanged: (value) => setState(() => _animatedCheckbox = value),
              label: 'Remember my preferences',
            ),
          ],

          const SizedBox(height: 32),

          // Features summary
          _FeaturesSummary(),
        ],
      ),
    );
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  final String selectedStyle;
  final ValueChanged<String> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    final styles = ['Material', 'Custom Shape', 'Animated'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: styles.map((style) {
          final isSelected = style == selectedStyle;
          return Expanded(
            child: GestureDetector(
              onTap: () => onStyleChanged(style),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  style,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MaterialStyleCheckbox extends StatefulWidget {
  const _MaterialStyleCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  State<_MaterialStyleCheckbox> createState() => _MaterialStyleCheckboxState();
}

class _MaterialStyleCheckboxState extends State<_MaterialStyleCheckbox> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: widget.value,
      onChanged: (value) => widget.onChanged(value ?? false),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      builder: (context, states, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isPressed
                ? Colors.grey.shade100
                : _isHovered
                    ? Colors.grey.shade50
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.value ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.value ? Colors.blue : Colors.white,
                  border: Border.all(
                    color: widget.value ? Colors.blue : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: widget.value
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomShapeCheckbox extends StatefulWidget {
  const _CustomShapeCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  State<_CustomShapeCheckbox> createState() => _CustomShapeCheckboxState();
}

class _CustomShapeCheckboxState extends State<_CustomShapeCheckbox> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: widget.value,
      onChanged: (value) => widget.onChanged(value ?? false),
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      builder: (context, states, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.value
                ? LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  )
                : null,
            color: widget.value ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border:
                widget.value ? null : Border.all(color: Colors.grey.shade300),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.value
                          ? Colors.purple.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: widget.value
                        ? Colors.transparent
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: widget.value
                    ? Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.purple.shade600,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        widget.value ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight:
                        widget.value ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedCheckbox extends StatefulWidget {
  const _AnimatedCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.value) {
      _colorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _colorController.forward();
        _scaleController.forward().then((_) => _scaleController.reverse());
      } else {
        _colorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: widget.value,
      onChanged: (value) => widget.onChanged(value ?? false),
      builder: (context, states, child) {
        return AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _colorController]),
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTween(
                  begin: Colors.white,
                  end: Colors.green.shade50,
                ).animate(_colorController).value,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorTween(
                    begin: Colors.grey.shade300,
                    end: Colors.green.shade300,
                  ).animate(_colorController).value!,
                ),
              ),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.0 + (_scaleController.value * 0.2),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ColorTween(
                          begin: Colors.white,
                          end: Colors.green,
                        ).animate(_colorController).value,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ColorTween(
                            begin: Colors.grey.shade400,
                            end: Colors.green,
                          ).animate(_colorController).value!,
                          width: 2,
                        ),
                      ),
                      child: widget.value
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FeaturesSummary extends StatelessWidget {
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
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Builder Pattern Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Complete visual control with builder pattern\n'
            '• State-aware styling (hover, press, focus)\n'
            '• Custom animations and transitions\n'
            '• Proper accessibility and semantics handling',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
