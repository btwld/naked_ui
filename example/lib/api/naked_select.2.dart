import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

// Simple fruit data class for type safety
class Fruit {
  const Fruit({
    required this.value,
    required this.label,
    required this.emoji,
  });

  final String value;
  final String label;
  final String emoji;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CYBER SELECT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FF41),
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '> INITIALIZE DATA STREAM_',
                style: TextStyle(
                  color: Color(0xFF00AA33),
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 24),
              CyberpunkSelectExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class CyberpunkSelectExample extends StatefulWidget {
  const CyberpunkSelectExample({super.key});

  @override
  State<CyberpunkSelectExample> createState() => _CyberpunkSelectExampleState();
}

class _CyberpunkSelectExampleState extends State<CyberpunkSelectExample> {
  String? _selectedValue;

  // Available cyber fruits
  static const fruits = [
    Fruit(value: 'apple', label: 'APPLE.EXE', emoji: '🍎'),
    Fruit(value: 'banana', label: 'BANANA.SYS', emoji: '🍌'),
    Fruit(value: 'orange', label: 'ORANGE.BAT', emoji: '🍊'),
    Fruit(value: 'grape', label: 'GRAPE.DLL', emoji: '🍇'),
  ];

  // Get selected fruit label for display
  String? get _selectedLabel {
    if (_selectedValue == null) return null;
    return fruits.firstWhere((f) => f.value == _selectedValue).label;
  }

  Widget _buildOption(Fruit fruit) {
    return NakedSelect.Option(
      value: fruit.value,
      builder: (context, states, _) {
        final selected = states.contains(WidgetState.selected);
        final hovered = states.contains(WidgetState.hovered);

        final textStyle = TextStyle(
          color: selected ? const Color(0xFF00FF41) : const Color(0xFF00AA33),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontFamily: 'monospace',
        );

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(-0.05),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF001100)
                  : hovered
                      ? const Color(0xFF001A00)
                      : Colors.transparent,
              border: Border.all(
                color: selected || hovered
                    ? const Color(0xFF00FF41)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: selected || hovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF41).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              spacing: 8,
              children: [
                Text(
                  fruit.emoji,
                  style: TextStyle(
                    fontSize: 16,
                    shadows: selected || hovered
                        ? [
                            const Shadow(
                              color: Color(0xFF00FF41),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: Text(
                    fruit.label,
                    style: textStyle,
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.keyboard_arrow_right,
                    size: 16,
                    color: Color(0xFF00FF41),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        triggerBuilder: (context, states) {
          final focused = states.contains(WidgetState.focused);
          final hovered = states.contains(WidgetState.hovered);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-0.1),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF001100),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF00FF41)
                      : const Color(0xFF003300),
                  width: 2,
                ),
                boxShadow: [
                  if (focused || hovered)
                    BoxShadow(
                      color: const Color(0xFF00FF41)
                          .withValues(alpha: focused ? 0.4 : 0.2),
                      blurRadius: focused ? 12 : 8,
                      spreadRadius: focused ? 2 : 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_selectedValue != null) ...[
                    Text(
                      fruits.firstWhere((f) => f.value == _selectedValue).emoji,
                      style: const TextStyle(
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Color(0xFF00FF41),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _selectedLabel ?? '> SELECT DATA_',
                      style: TextStyle(
                        color: _selectedValue != null
                            ? const Color(0xFF00FF41)
                            : const Color(0xFF00AA33),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: focused
                        ? const Color(0xFF00FF41)
                        : const Color(0xFF00AA33),
                  ),
                ],
              ),
            ),
          );
        },
        overlayBuilder: (context, info) {
          return SizedBox(
            width: 250,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-0.1),
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF000A00),
                  border: Border.all(
                    color: const Color(0xFF00FF41),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF41).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: fruits.map(_buildOption).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}