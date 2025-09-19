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

class _CheckmarkSelectExampleState extends State<CheckmarkSelectExample>
    with TickerProviderStateMixin {
  String? _selectedValue;
  late final _controller = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );

  final List<Map<String, dynamic>> _fruits = [
    {'value': 'apple', 'label': 'Apple', 'emoji': '🍎'},
    {'value': 'banana', 'label': 'Banana', 'emoji': '🍌'},
    {'value': 'orange', 'label': 'Orange', 'emoji': '🍊'},
    {'value': 'grape', 'label': 'Grape', 'emoji': '🍇'},
    {'value': 'strawberry', 'label': 'Strawberry', 'emoji': '🍓'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildOptionWithCheckmark(Map<String, dynamic> fruit) {
    return NakedSelectOption<String>(
      value: fruit['value'],
      builder: (context, states, _) {
        final hovered = states.contains(WidgetState.hovered);
        final selected = states.contains(WidgetState.selected);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.blue.shade50
                : hovered
                    ? Colors.grey.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                fruit['emoji'],
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fruit['label'],
                  style: TextStyle(
                    color: selected ? Colors.blue : Colors.black,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1.0 : 0.0,
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
    final selectedFruit = _fruits.firstWhere(
      (fruit) => fruit['value'] == _selectedValue,
      orElse: () => {'emoji': '', 'label': ''},
    );

    return SizedBox(
      width: 280,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        onOpen: () => _controller.forward(),
        onClose: () => _controller.reverse(),
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
                if (_selectedValue != null) ...[
                  Text(
                    selectedFruit['emoji'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    _selectedValue != null
                        ? selectedFruit['label']
                        : 'Choose your favorite fruit...',
                    style: TextStyle(
                      color: _selectedValue != null
                          ? Colors.black
                          : Colors.grey,
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
          return ScaleTransition(
            scale: _controller.drive(
              Tween<double>(begin: 0.95, end: 1.0).chain(
                CurveTween(curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: _controller.drive(
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
                  children: _fruits.map(_buildOptionWithCheckmark).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
