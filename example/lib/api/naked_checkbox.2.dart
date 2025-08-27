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
  bool _neonCheckbox = true;
  bool _customShapeCheckbox = false;
  bool _animatedCheckbox = false;

  bool _enableDisabledDemo = true;
  bool _disabledChecked = true;
  bool _disabledUnchecked = false;

  String _selectedTheme = 'material';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Checkbox Builder Pattern & Disabled States',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Custom styling with builder pattern and disabled state handling',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Theme selector
          _ThemeSelector(
            selectedTheme: _selectedTheme,
            onThemeChanged: (theme) => setState(() => _selectedTheme = theme),
          ),

          const SizedBox(height: 24),

          // Builder pattern examples
          _BuilderExamplesSection(
            materialValue: _materialCheckbox,
            neonValue: _neonCheckbox,
            customShapeValue: _customShapeCheckbox,
            animatedValue: _animatedCheckbox,
            onMaterialChanged: (value) =>
                setState(() => _materialCheckbox = value ?? false),
            onNeonChanged: (value) =>
                setState(() => _neonCheckbox = value ?? false),
            onCustomShapeChanged: (value) =>
                setState(() => _customShapeCheckbox = value ?? false),
            onAnimatedChanged: (value) =>
                setState(() => _animatedCheckbox = value ?? false),
          ),

          const SizedBox(height: 32),

          // Disabled states section
          _DisabledStatesSection(
            enableDemo: _enableDisabledDemo,
            disabledChecked: _disabledChecked,
            disabledUnchecked: _disabledUnchecked,
            onEnableDemoChanged: (value) =>
                setState(() => _enableDisabledDemo = value ?? false),
            onDisabledCheckedChanged: (value) =>
                setState(() => _disabledChecked = value ?? false),
            onDisabledUncheckedChanged: (value) =>
                setState(() => _disabledUnchecked = value ?? false),
          ),

          const SizedBox(height: 32),

          // Pattern benefits
          const _PatternBenefits(),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  final String selectedTheme;
  final ValueChanged<String> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'id': 'material', 'name': 'Material', 'color': const Color(0xFF2196F3)},
      {'id': 'neon', 'name': 'Neon Glow', 'color': const Color(0xFF00E676)},
      {
        'id': 'custom',
        'name': 'Custom Shape',
        'color': const Color(0xFFFF6B35)
      },
      {'id': 'animated', 'name': 'Animated', 'color': const Color(0xFF9C27B0)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: themes.map((theme) {
        final isSelected = selectedTheme == theme['id'];
        return _ThemeOption(
          name: theme['name'] as String,
          color: theme['color'] as Color,
          isSelected: isSelected,
          onTap: () => onThemeChanged(theme['id'] as String),
        );
      }).toList(),
    );
  }
}

class _ThemeOption extends StatefulWidget {
  const _ThemeOption({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: widget.onTap,
      onPressChange: (pressed) => setState(() => _isPressed = pressed),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color,
              width: widget.isSelected ? 0 : 1,
            ),
          ),
          child: Text(
            widget.name,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : widget.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuilderExamplesSection extends StatelessWidget {
  const _BuilderExamplesSection({
    required this.materialValue,
    required this.neonValue,
    required this.customShapeValue,
    required this.animatedValue,
    required this.onMaterialChanged,
    required this.onNeonChanged,
    required this.onCustomShapeChanged,
    required this.onAnimatedChanged,
  });

  final bool materialValue;
  final bool neonValue;
  final bool customShapeValue;
  final bool animatedValue;
  final ValueChanged<bool?> onMaterialChanged;
  final ValueChanged<bool?> onNeonChanged;
  final ValueChanged<bool?> onCustomShapeChanged;
  final ValueChanged<bool?> onAnimatedChanged;

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
                Icons.palette,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Builder Pattern Examples',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Material Design Builder
          _MaterialBuilderCheckbox(
            value: materialValue,
            onChanged: onMaterialChanged,
            title: 'Material Design',
            subtitle: 'Google Material Design inspired checkbox',
          ),

          const SizedBox(height: 16),

          // Neon Glow Builder
          _NeonBuilderCheckbox(
            value: neonValue,
            onChanged: onNeonChanged,
            title: 'Neon Glow Effect',
            subtitle: 'Glowing checkbox with neon aesthetics',
          ),

          const SizedBox(height: 16),

          // Custom Shape Builder
          _CustomShapeBuilderCheckbox(
            value: customShapeValue,
            onChanged: onCustomShapeChanged,
            title: 'Custom Shape',
            subtitle: 'Heart-shaped checkbox with custom styling',
          ),

          const SizedBox(height: 16),

          // Animated Builder
          _AnimatedBuilderCheckbox(
            value: animatedValue,
            onChanged: onAnimatedChanged,
            title: 'Animated Morphing',
            subtitle: 'Smooth animations and morphing effects',
          ),
        ],
      ),
    );
  }
}

class _MaterialBuilderCheckbox extends StatelessWidget {
  const _MaterialBuilderCheckbox({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: value,
      onChanged: onChanged,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);
        final isDisabled = states.contains(WidgetState.disabled);

        Color backgroundColor = Colors.grey.shade100;
        Color checkboxColor = const Color(0xFF2196F3);
        double elevation = 0.0;

        if (isDisabled) {
          backgroundColor = Colors.grey.shade200;
          checkboxColor = Colors.grey.shade400;
        } else if (isPressed) {
          backgroundColor = Colors.grey.shade200;
          elevation = 1.0;
        } else if (isHovered) {
          backgroundColor = Colors.grey.shade50;
          elevation = 2.0;
        }

        return Container(
          padding: EdgeInsets.all(isFocused ? 4 : 0),
          decoration: isFocused
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: checkboxColor,
                    width: 2,
                  ),
                )
              : null,
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: value ? checkboxColor : Colors.transparent,
                      border: Border.all(
                        color: checkboxColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: value
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: child!),
                ],
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
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
    );
  }
}

class _NeonBuilderCheckbox extends StatelessWidget {
  const _NeonBuilderCheckbox({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: value,
      onChanged: onChanged,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        const neonColor = Color(0xFF00E676);
        double glowIntensity = 0.3;

        if (isPressed) {
          glowIntensity = 0.8;
        } else if (isHovered || value) {
          glowIntensity = 0.6;
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (value || isHovered || isPressed) ...[
                BoxShadow(
                  color: neonColor.withValues(alpha: glowIntensity * 0.6),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: neonColor.withValues(alpha: glowIntensity * 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFocused ? neonColor : Colors.grey.shade800,
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: value ? neonColor : Colors.transparent,
                    border: Border.all(
                      color: neonColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: neonColor.withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: value
                      ? Icon(
                          Icons.electric_bolt,
                          size: 12,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              color: neonColor.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        )
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
                          color: neonColor,
                          shadows: [
                            Shadow(
                              color: neonColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: neonColor.withValues(alpha: 0.8),
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
    );
  }
}

class _CustomShapeBuilderCheckbox extends StatelessWidget {
  const _CustomShapeBuilderCheckbox({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: value,
      onChanged: onChanged,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        const heartColor = Color(0xFFFF6B35);
        double scale = 1.0;

        if (isPressed) {
          scale = 0.95;
        } else if (isHovered) {
          scale = 1.05;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.all(isFocused ? 4 : 0),
            decoration: isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: heartColor,
                      width: 2,
                    ),
                  )
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: value
                    ? heartColor.withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value ? heartColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: value
                        ? const Icon(
                            Icons.favorite,
                            key: ValueKey('filled_heart'),
                            size: 20,
                            color: heartColor,
                          )
                        : Icon(
                            Icons.favorite_border,
                            key: const ValueKey('empty_heart'),
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: child!),
                ],
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
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
    );
  }
}

class _AnimatedBuilderCheckbox extends StatelessWidget {
  const _AnimatedBuilderCheckbox({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: value,
      onChanged: onChanged,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        const primaryColor = Color(0xFF9C27B0);
        BorderRadius borderRadius = BorderRadius.circular(value ? 20 : 8);
        double scale = isPressed ? 0.98 : (isHovered ? 1.05 : 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.all(isFocused ? 4 : 0),
            decoration: isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor,
                      width: 2,
                    ),
                  )
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.8),
                          primaryColor.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: value ? null : Colors.grey.shade50,
                borderRadius: borderRadius,
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: value ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: value
                          ? const Icon(
                              Icons.stars,
                              key: ValueKey('stars'),
                              size: 20,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.star_border,
                              key: const ValueKey('star_border'),
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                value ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                          child: Text(title),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                value ? Colors.white70 : Colors.grey.shade600,
                          ),
                          child: Text(subtitle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DisabledStatesSection extends StatelessWidget {
  const _DisabledStatesSection({
    required this.enableDemo,
    required this.disabledChecked,
    required this.disabledUnchecked,
    required this.onEnableDemoChanged,
    required this.onDisabledCheckedChanged,
    required this.onDisabledUncheckedChanged,
  });

  final bool enableDemo;
  final bool disabledChecked;
  final bool disabledUnchecked;
  final ValueChanged<bool?> onEnableDemoChanged;
  final ValueChanged<bool?> onDisabledCheckedChanged;
  final ValueChanged<bool?> onDisabledUncheckedChanged;

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
                Icons.block,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Disabled States',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Control toggle
          _SimpleCheckboxTile(
            value: enableDemo,
            onChanged: onEnableDemoChanged,
            title: 'Enable Disabled Demo',
            subtitle: 'Toggle to see how disabled checkboxes behave',
          ),

          const SizedBox(height: 16),

          // Disabled examples
          Opacity(
            opacity: enableDemo ? 0.5 : 1.0,
            child: Column(
              children: [
                _SimpleCheckboxTile(
                  value: disabledChecked,
                  onChanged: enableDemo ? null : onDisabledCheckedChanged,
                  title: 'Disabled Checked',
                  subtitle: 'This checkbox is disabled in checked state',
                  semanticLabel: 'Disabled checked checkbox example',
                  semanticHint: enableDemo
                      ? 'This checkbox is currently disabled and cannot be changed'
                      : 'This checkbox demonstrates the disabled checked appearance',
                ),
                _SimpleCheckboxTile(
                  value: disabledUnchecked,
                  onChanged: enableDemo ? null : onDisabledUncheckedChanged,
                  title: 'Disabled Unchecked',
                  subtitle: 'This checkbox is disabled in unchecked state',
                  semanticLabel: 'Disabled unchecked checkbox example',
                  semanticHint: enableDemo
                      ? 'This checkbox is currently disabled and cannot be changed'
                      : 'This checkbox demonstrates the disabled unchecked appearance',
                ),
              ],
            ),
          ),

          if (enableDemo)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disabled checkboxes cannot be interacted with and have visual feedback indicating their disabled state.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
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

class _SimpleCheckboxTile extends StatefulWidget {
  const _SimpleCheckboxTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    this.semanticLabel,
    this.semanticHint,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final String subtitle;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  State<_SimpleCheckboxTile> createState() => _SimpleCheckboxTileState();
}

class _SimpleCheckboxTileState extends State<_SimpleCheckboxTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onChanged != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NakedCheckbox(
        value: widget.value,
        onChanged: widget.onChanged,
        enabled: isEnabled,
        semanticLabel: widget.semanticLabel,
        semanticHint: widget.semanticHint,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHoverChange: (hovered) {},
        mouseCursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.value
                      ? (isEnabled
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade400)
                      : Colors.transparent,
                  border: Border.all(
                    color: isEnabled
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: widget.value
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: isEnabled ? Colors.white : Colors.grey.shade600,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
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

class _PatternBenefits extends StatelessWidget {
  const _PatternBenefits();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
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
            icon: Icons.brush,
            title: 'Complete Visual Control',
            description: 'Design checkboxes that match your brand perfectly',
          ),
          const _BenefitItem(
            icon: Icons.psychology,
            title: 'State-Aware Styling',
            description:
                'Different appearances for hover, focus, pressed, and disabled states',
          ),
          const _BenefitItem(
            icon: Icons.animation,
            title: 'Custom Animations',
            description: 'Create unique transitions and morphing effects',
          ),
          const _BenefitItem(
            icon: Icons.accessibility,
            title: 'Accessibility Preserved',
            description:
                'Maintains screen reader support and keyboard navigation',
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
