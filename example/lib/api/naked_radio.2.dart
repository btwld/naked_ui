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
          child: ToggleableRadioExample(),
        ),
      ),
    );
  }
}

class ToggleableRadioExample extends StatefulWidget {
  const ToggleableRadioExample({super.key});

  @override
  State<ToggleableRadioExample> createState() => _ToggleableRadioExampleState();
}

class _ToggleableRadioExampleState extends State<ToggleableRadioExample> {
  // Toggleable settings
  String? _selectedToggleable = 'option1';
  
  // Builder pattern examples
  String? _selectedMaterial;
  String? _selectedNeon = 'neon2';
  String? _selectedCustom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Toggleable Radio & Builder Pattern',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Radio buttons that can be deselected and custom builder patterns',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Toggleable radio group
          _ToggleableRadioSection(
            selectedValue: _selectedToggleable,
            onChanged: (value) => setState(() => _selectedToggleable = value),
          ),
          
          const SizedBox(height: 32),
          
          // Material builder pattern
          _MaterialBuilderSection(
            selectedValue: _selectedMaterial,
            onChanged: (value) => setState(() => _selectedMaterial = value),
          ),
          
          const SizedBox(height: 24),
          
          // Neon builder pattern
          _NeonBuilderSection(
            selectedValue: _selectedNeon,
            onChanged: (value) => setState(() => _selectedNeon = value),
          ),
          
          const SizedBox(height: 24),
          
          // Custom shape builder pattern
          _CustomBuilderSection(
            selectedValue: _selectedCustom,
            onChanged: (value) => setState(() => _selectedCustom = value),
          ),
          
          const SizedBox(height: 32),
          
          // Builder benefits
          const _BuilderBenefits(),
        ],
      ),
    );
  }
}

class _ToggleableRadioSection extends StatelessWidget {
  const _ToggleableRadioSection({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

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
                Icons.toggle_on,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Toggleable Radio Buttons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Can be deselected by clicking the selected option again',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: [
                _ToggleableRadioTile(
                  value: 'option1',
                  title: 'Toggleable Option 1',
                  subtitle: 'Click again to deselect',
                  color: const Color(0xFFFF6B35),
                  icon: Icons.star,
                  isSelected: selectedValue == 'option1',
                ),
                _ToggleableRadioTile(
                  value: 'option2',
                  title: 'Toggleable Option 2',
                  subtitle: 'Can be turned on and off',
                  color: const Color(0xFF4CAF50),
                  icon: Icons.favorite,
                  isSelected: selectedValue == 'option2',
                ),
                _ToggleableRadioTile(
                  value: 'option3',
                  title: 'Toggleable Option 3',
                  subtitle: 'Optional selection',
                  color: const Color(0xFF2196F3),
                  icon: Icons.thumb_up,
                  isSelected: selectedValue == 'option3',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedValue != null
                        ? 'Selected: $selectedValue (click again to deselect)'
                        : 'No selection (all options can be deselected)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
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

class _MaterialBuilderSection extends StatelessWidget {
  const _MaterialBuilderSection({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

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
                Icons.design_services,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Material Design Builder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: [
                _MaterialBuilderRadio(
                  value: 'material1',
                  title: 'Elevated Style',
                  subtitle: 'Material elevation and shadows',
                  icon: Icons.layers,
                ),
                _MaterialBuilderRadio(
                  value: 'material2',
                  title: 'Outlined Style',
                  subtitle: 'Clean borders with subtle shadows',
                  icon: Icons.crop_portrait,
                ),
                _MaterialBuilderRadio(
                  value: 'material3',
                  title: 'Filled Style',
                  subtitle: 'Solid background with rounded corners',
                  icon: Icons.rectangle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonBuilderSection extends StatelessWidget {
  const _NeonBuilderSection({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.electric_bolt,
                color: const Color(0xFF00E676),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Neon Glow Builder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00E676),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: [
                _NeonBuilderRadio(
                  value: 'neon1',
                  title: 'Cyan Glow',
                  subtitle: 'Electric cyan neon effect',
                  color: const Color(0xFF00E5FF),
                  icon: Icons.flash_on,
                ),
                _NeonBuilderRadio(
                  value: 'neon2',
                  title: 'Green Glow',
                  subtitle: 'Matrix-style green glow',
                  color: const Color(0xFF00E676),
                  icon: Icons.bolt,
                ),
                _NeonBuilderRadio(
                  value: 'neon3',
                  title: 'Purple Glow',
                  subtitle: 'Futuristic purple neon',
                  color: const Color(0xFFE91E63),
                  icon: Icons.auto_awesome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBuilderSection extends StatelessWidget {
  const _CustomBuilderSection({
    required this.selectedValue,
    required this.onChanged,
  });

  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brush,
                color: Colors.purple.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Shape Builder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NakedRadioGroup<String>(
            groupValue: selectedValue,
            onChanged: onChanged,
            child: Column(
              children: [
                _CustomBuilderRadio(
                  value: 'custom1',
                  title: 'Diamond Shape',
                  subtitle: 'Rotated square with animations',
                  color: const Color(0xFF9C27B0),
                  icon: Icons.diamond,
                ),
                _CustomBuilderRadio(
                  value: 'custom2',
                  title: 'Heart Shape',
                  subtitle: 'Love-themed radio button',
                  color: const Color(0xFFE91E63),
                  icon: Icons.favorite,
                ),
                _CustomBuilderRadio(
                  value: 'custom3',
                  title: 'Star Shape',
                  subtitle: 'Five-pointed star selection',
                  color: const Color(0xFFFF9800),
                  icon: Icons.star,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleableRadioTile extends StatefulWidget {
  const _ToggleableRadioTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isSelected,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isSelected;

  @override
  State<_ToggleableRadioTile> createState() => _ToggleableRadioTileState();
}

class _ToggleableRadioTileState extends State<_ToggleableRadioTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedRadio<String>(
        value: widget.value,
        toggleable: true,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHoverChange: (hovered) => setState(() => _isHovered = hovered),
        onPressChange: (pressed) {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.1)
                : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? widget.color
                  : (widget.isSelected ? widget.color : Colors.transparent),
              width: widget.isSelected ? 2 : (_isFocused ? 2 : 1),
            ),
          ),
          child: Row(
            children: [
              // Toggle indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? widget.color : Colors.transparent,
                  border: Border.all(
                    color: widget.color,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.color.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isSelected ? widget.color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? widget.color
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isSelected
                            ? widget.color.withValues(alpha: 0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection badge
              if (widget.isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialBuilderRadio extends StatelessWidget {
  const _MaterialBuilderRadio({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedRadio<String>(
        value: value,
        builder: (context, states, child) {
          final isSelected = states.contains(WidgetState.selected);
          final isHovered = states.contains(WidgetState.hovered);
          final isPressed = states.contains(WidgetState.pressed);
          final isFocused = states.contains(WidgetState.focused);

          double elevation = 0;
          Color backgroundColor = Colors.white;
          Color borderColor = Colors.grey.shade300;

          if (isSelected) {
            elevation = 4;
            backgroundColor = const Color(0xFF2196F3).withValues(alpha: 0.1);
            borderColor = const Color(0xFF2196F3);
          } else if (isPressed) {
            elevation = 1;
            backgroundColor = Colors.grey.shade100;
          } else if (isHovered) {
            elevation = 2;
            backgroundColor = Colors.grey.shade50;
          }

          return Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? const Color(0xFF2196F3) : borderColor,
                  width: isFocused ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF2196F3),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          subtitle,
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
          );
        },
      ),
    );
  }
}

class _NeonBuilderRadio extends StatelessWidget {
  const _NeonBuilderRadio({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedRadio<String>(
        value: value,
        builder: (context, states, child) {
          final isSelected = states.contains(WidgetState.selected);
          final isHovered = states.contains(WidgetState.hovered);
          final isFocused = states.contains(WidgetState.focused);

          double glowIntensity = 0.3;
          if (isSelected) glowIntensity = 0.8;
          else if (isHovered) glowIntensity = 0.6;

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected || isHovered
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: glowIntensity * 0.6),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: glowIntensity * 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused ? color : Colors.grey.shade800,
                  width: isFocused ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? color : Colors.transparent,
                      border: Border.all(color: color, width: 2),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.black87,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    color: isSelected ? color : color.withValues(alpha: 0.7),
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                            shadows: isSelected
                                ? [
                                    Shadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomBuilderRadio extends StatelessWidget {
  const _CustomBuilderRadio({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NakedRadio<String>(
        value: value,
        builder: (context, states, child) {
          final isSelected = states.contains(WidgetState.selected);
          final isHovered = states.contains(WidgetState.hovered);
          final isPressed = states.contains(WidgetState.pressed);
          final isFocused = states.contains(WidgetState.focused);

          double scale = 1.0;
          double rotation = 0.0;

          if (isPressed) {
            scale = 0.98;
          } else if (isSelected) {
            scale = 1.02;
            rotation = 0.05;
          }

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : (isHovered ? Colors.grey.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFocused ? color : (isSelected ? color : Colors.grey.shade300),
                    width: isFocused ? 3 : (isSelected ? 2 : 1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isSelected
                          ? Transform.rotate(
                              angle: rotation * 2,
                              child: Icon(
                                icon,
                                key: ValueKey('selected_$icon'),
                                size: 24,
                                color: color,
                              ),
                            )
                          : Icon(
                              Icons.radio_button_unchecked,
                              key: const ValueKey('unselected'),
                              size: 24,
                              color: Colors.grey.shade400,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : const Color(0xFF1A1A1A),
                            ),
                            child: Text(title),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? color.withValues(alpha: 0.8)
                                  : Colors.grey.shade600,
                            ),
                            child: Text(subtitle),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      AnimatedRotation(
                        turns: 1.0,
                        duration: const Duration(milliseconds: 600),
                        child: Icon(
                          Icons.check_circle,
                          color: color,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuilderBenefits extends StatelessWidget {
  const _BuilderBenefits();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.construction,
                color: Colors.purple.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Builder Pattern Benefits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.tune,
            title: 'State-Driven Design',
            description: 'Visual appearance changes based on interaction states',
          ),
          const _BenefitItem(
            icon: Icons.animation,
            title: 'Custom Animations',
            description: 'Create unique transitions and morphing effects',
          ),
          const _BenefitItem(
            icon: Icons.palette,
            title: 'Brand Consistency',
            description: 'Match your exact design system and brand colors',
          ),
          const _BenefitItem(
            icon: Icons.toggle_on,
            title: 'Toggleable Support',
            description: 'Enable deselection for optional radio groups',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.purple.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade700,
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