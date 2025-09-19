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
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Animated Select',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select with smooth animations',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                AnimatedSelectExample(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedSelectExample extends StatefulWidget {
  const AnimatedSelectExample({super.key});

  @override
  State<AnimatedSelectExample> createState() => _AnimatedSelectExampleState();
}

class _AnimatedSelectExampleState extends State<AnimatedSelectExample>
    with TickerProviderStateMixin {
  String? _selectedValue;
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );

  final List<String> _colors = [
    'Blue',
    'Green',
    'Purple',
    'Orange',
  ];

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedOption(String option) {
    return NakedSelectOption<String>(
      value: option,
      builder: (context, states, _) {
        final hovered = states.contains(WidgetState.hovered);
        final selected = states.contains(WidgetState.selected);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blue.shade50
                : hovered
                    ? Colors.grey.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(
                _getColorEmoji(option),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: selected ? Colors.blue : Colors.black,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.blue,
                ),
            ],
          ),
        );
      },
    );
  }

  String _getColorEmoji(String color) {
    switch (color) {
      case 'Blue':
        return '🔵';
      case 'Green':
        return '🟢';
      case 'Purple':
        return '🟣';
      case 'Orange':
        return '🟠';
      default:
        return '🎨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        onOpen: () => _animationController.forward(),
        onClose: () => _animationController.reverse(),
        triggerBuilder: (context, states) {
          final focused = states.contains(WidgetState.focused);
          final hovered = states.contains(WidgetState.hovered);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focused
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                if (focused)
                  const BoxShadow(
                    color: Color(0x1F2563EB),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                BoxShadow(
                  color: hovered
                      ? const Color(0x14000000)
                      : const Color(0x0A000000),
                  blurRadius: hovered ? 8 : 4,
                  offset: Offset(0, hovered ? 2 : 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_selectedValue != null) ...[
                  Text(
                    _getColorEmoji(_selectedValue!),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _selectedValue ?? 'Choose a color...',
                    style: TextStyle(
                      color: _selectedValue != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: focused ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: focused
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        },
        overlayBuilder: (context, info) {
          return SlideTransition(
            position: _animationController.drive(
              Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: FadeTransition(
              opacity: _animationController.drive(
                CurveTween(curve: Curves.easeOut),
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _colors.map(_buildAnimatedOption).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

