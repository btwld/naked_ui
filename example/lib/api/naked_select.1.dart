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
                  'Select with Checkmarks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Options show checkmarks when selected',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                CheckmarkSelectExample(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckmarkSelectExample extends StatefulWidget {
  const CheckmarkSelectExample({super.key});

  @override
  State<CheckmarkSelectExample> createState() => _CheckmarkSelectExampleState();
}

class _CheckmarkSelectExampleState extends State<CheckmarkSelectExample> {
  String? _selectedValue;

  // Available fruits
  static const fruits = [
    Fruit(value: 'apple', label: 'Apple', emoji: '🍎'),
    Fruit(value: 'banana', label: 'Banana', emoji: '🍌'),
    Fruit(value: 'orange', label: 'Orange', emoji: '🍊'),
    Fruit(value: 'grape', label: 'Grape', emoji: '🍇'),
    Fruit(value: 'strawberry', label: 'Strawberry', emoji: '🍓'),
  ];

  // Get selected fruit for display
  Fruit? get _selectedFruit {
    if (_selectedValue == null) return null;
    return fruits.firstWhere((f) => f.value == _selectedValue);
  }

  Widget _buildOptionWithCheckmark(Fruit fruit) {
    return NakedSelect.Option(
      value: fruit.value,
      builder: (context, state, _) {
        final backgroundColor = state.when<Color?>(
          selected: Colors.blue.shade50,
          hovered: Colors.grey.shade100,
          orElse: Colors.transparent,
        );

        final textColor = state.when<Color>(
          selected: Colors.blue,
          orElse: Colors.black,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                fruit.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fruit.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight:
                        state.isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              AnimatedScale(
                scale: state.isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        builder: (context, state, _) {
          final focused = state.isFocused;
          final hovered = state.isHovered;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focused ? Colors.blue : Colors.grey.shade300,
              ),
              boxShadow: [
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
                if (_selectedFruit != null) ...[
                  Text(
                    _selectedFruit!.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    _selectedFruit?.label ?? 'Choose your favorite fruit...',
                    style: TextStyle(
                      color:
                          _selectedFruit != null ? Colors.black : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
        overlayBuilder: (context, info) {
          return Container(
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
              children: fruits.map(_buildOptionWithCheckmark).toList(),
            ),
          );
        },
      ),
    );
  }
}
