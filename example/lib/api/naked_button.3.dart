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
          child: BuilderPatternExample(),
        ),
      ),
    );
  }
}

class BuilderPatternExample extends StatefulWidget {
  const BuilderPatternExample({super.key});

  @override
  State<BuilderPatternExample> createState() => _BuilderPatternExampleState();
}

class _BuilderPatternExampleState extends State<BuilderPatternExample> {
  int _clickCount = 0;
  String _selectedTheme = 'gradient';

  void _incrementCounter() {
    setState(() {
      _clickCount++;
    });
  }

  void _changeTheme(String theme) {
    setState(() {
      _selectedTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Builder Pattern Examples',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Dynamic styling based on widget states',
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
            onThemeChanged: _changeTheme,
          ),

          const SizedBox(height: 32),

          // Main builder button based on selected theme
          Center(
            child: _getBuilderButton(),
          ),

          const SizedBox(height: 24),

          // Click counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Click Count: $_clickCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The button appearance changes based on its state',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Showcase different builder patterns
          const _BuilderShowcase(),
        ],
      ),
    );
  }

  Widget _getBuilderButton() {
    switch (_selectedTheme) {
      case 'gradient':
        return _GradientBuilderButton(
          onPressed: _incrementCounter,
          clickCount: _clickCount,
        );
      case 'morphing':
        return _MorphingBuilderButton(
          onPressed: _incrementCounter,
          clickCount: _clickCount,
        );
      case 'neon':
        return _NeonBuilderButton(
          onPressed: _incrementCounter,
          clickCount: _clickCount,
        );
      case 'material':
        return _MaterialBuilderButton(
          onPressed: _incrementCounter,
          clickCount: _clickCount,
        );
      default:
        return _GradientBuilderButton(
          onPressed: _incrementCounter,
          clickCount: _clickCount,
        );
    }
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
      {'id': 'gradient', 'name': 'Gradient', 'color': const Color(0xFF6366F1)},
      {'id': 'morphing', 'name': 'Morphing', 'color': const Color(0xFFEC4899)},
      {'id': 'neon', 'name': 'Neon Glow', 'color': const Color(0xFF10B981)},
      {'id': 'material', 'name': 'Material', 'color': const Color(0xFFF59E0B)},
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBuilderButton extends StatelessWidget {
  const _GradientBuilderButton({
    required this.onPressed,
    required this.clickCount,
  });

  final VoidCallback onPressed;
  final int clickCount;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);
        final isDisabled = states.contains(WidgetState.disabled);

        Color startColor = const Color(0xFF6366F1);
        Color endColor = const Color(0xFF8B5CF6);
        double scale = 1.0;
        double elevation = 4.0;

        if (isDisabled) {
          startColor = Colors.grey.shade300;
          endColor = Colors.grey.shade400;
          elevation = 0.0;
        } else if (isPressed) {
          startColor = const Color(0xFF4F46E5);
          endColor = const Color(0xFF7C3AED);
          scale = 0.98;
          elevation = 2.0;
        } else if (isHovered) {
          startColor = const Color(0xFF5B21B6);
          endColor = const Color(0xFF9333EA);
          elevation = 8.0;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.all(isFocused ? 4 : 0),
            decoration: isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 2,
                    ),
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [startColor, endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: startColor.withValues(alpha: 0.3),
                    blurRadius: elevation,
                    offset: Offset(0, elevation / 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.gradient,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPressed ? 'Pressed!' : 'Gradient Button',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (clickCount > 0)
                    Text(
                      'Clicked: $clickCount times',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
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

class _MorphingBuilderButton extends StatelessWidget {
  const _MorphingBuilderButton({
    required this.onPressed,
    required this.clickCount,
  });

  final VoidCallback onPressed;
  final int clickCount;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        // Morphing shapes based on state
        BorderRadiusGeometry borderRadius;
        Color backgroundColor;
        IconData icon;
        String text;

        if (isPressed) {
          borderRadius = BorderRadius.circular(30);
          backgroundColor = const Color(0xFFBE185D);
          icon = Icons.favorite;
          text = 'Loved!';
        } else if (isHovered) {
          borderRadius = BorderRadius.circular(20);
          backgroundColor = const Color(0xFFDB2777);
          icon = Icons.favorite_border;
          text = 'Hover Love';
        } else {
          borderRadius = BorderRadius.circular(12);
          backgroundColor = const Color(0xFFEC4899);
          icon = Icons.auto_awesome;
          text = 'Morphing Button';
        }

        return Container(
          padding: EdgeInsets.all(isFocused ? 4 : 0),
          decoration: isFocused
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: const Color(0xFFEC4899),
                    width: 2,
                  ),
                )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: isHovered ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    text,
                    key: ValueKey(text),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (clickCount > 0)
                  Text(
                    '$clickCount clicks',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
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

class _NeonBuilderButton extends StatelessWidget {
  const _NeonBuilderButton({
    required this.onPressed,
    required this.clickCount,
  });

  final VoidCallback onPressed;
  final int clickCount;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        Color neonColor = const Color(0xFF10B981);
        double glowIntensity = 0.3;
        double scale = 1.0;

        if (isPressed) {
          glowIntensity = 0.8;
          scale = 0.95;
        } else if (isHovered) {
          glowIntensity = 0.6;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Multiple glow layers for neon effect
                BoxShadow(
                  color: neonColor.withValues(alpha: glowIntensity * 0.8),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: neonColor.withValues(alpha: glowIntensity * 0.6),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: neonColor.withValues(alpha: glowIntensity * 0.4),
                  blurRadius: 60,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: neonColor,
                  width: isFocused ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPressed ? Icons.electric_bolt : Icons.flash_on,
                    color: neonColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPressed ? 'ELECTRIFIED!' : 'NEON GLOW',
                    style: TextStyle(
                      color: neonColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: neonColor.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (clickCount > 0)
                    Text(
                      'Energy: ${clickCount * 10}%',
                      style: TextStyle(
                        color: neonColor.withValues(alpha: 0.8),
                        fontSize: 10,
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

class _MaterialBuilderButton extends StatelessWidget {
  const _MaterialBuilderButton({
    required this.onPressed,
    required this.clickCount,
  });

  final VoidCallback onPressed;
  final int clickCount;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      builder: (context, states, child) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);
        final isFocused = states.contains(WidgetState.focused);

        double elevation = 2.0;
        Color backgroundColor = const Color(0xFFF59E0B);
        Color shadowColor = Colors.black26;

        if (isPressed) {
          elevation = 0.5;
          backgroundColor = const Color(0xFFD97706);
        } else if (isHovered) {
          elevation = 8.0;
          backgroundColor = const Color(0xFFEAB308);
        }

        return Container(
          padding: EdgeInsets.all(isFocused ? 4 : 0),
          decoration: isFocused
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2563EB),
                    width: 2,
                  ),
                )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: elevation,
                  offset: Offset(0, elevation),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  isPressed ? 'Material Pressed' : 'Material Design',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (clickCount > 0)
                  Text(
                    'Level $clickCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
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

class _BuilderShowcase extends StatelessWidget {
  const _BuilderShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Builder Pattern Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.palette,
            title: 'Dynamic Styling',
            description: 'Change appearance based on widget state',
          ),
          _BenefitItem(
            icon: Icons.code,
            title: 'Flexible Implementation',
            description: 'Complete control over rendering logic',
          ),
          _BenefitItem(
            icon: Icons.speed,
            title: 'Performance Optimized',
            description: 'Child widget reuse prevents unnecessary rebuilds',
          ),
          _BenefitItem(
            icon: Icons.accessibility,
            title: 'State Awareness',
            description: 'Access to all widget states for conditional styling',
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
            size: 20,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }
}
