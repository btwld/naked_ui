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
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simple Select',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose from a dropdown list',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              SimpleSelectExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleSelectExample extends StatefulWidget {
  const SimpleSelectExample({super.key});

  @override
  State<SimpleSelectExample> createState() => _SimpleSelectExampleState();
}

class _SimpleSelectExampleState extends State<SimpleSelectExample> {
  String? _selectedFruit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NakedSelect<String>(
        value: _selectedFruit,
        onChanged: (value) => setState(() => _selectedFruit = value),
        triggerBuilder: (context, states) {
          final focused = states.contains(WidgetState.focused);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused ? Colors.blue : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFruit ?? 'Choose fruit...',
                    style: TextStyle(
                      color: _selectedFruit != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20, color: Colors.grey),
              ],
            ),
          );
        },
        overlayBuilder: (context, info) {
          return SizedBox(
            width: 200,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedSelectOption<String>(
                  value: 'apple',
                  builder: (context, states, _) {
                    final hovered = states.contains(WidgetState.hovered);
                    final selected = states.contains(WidgetState.selected);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: selected
                          ? Colors.blue.shade50
                          : hovered
                              ? Colors.grey.shade100
                              : null,
                      child: Row(
                        children: [
                          const Text('🍎'),
                          const SizedBox(width: 8),
                          Text(
                            'Apple',
                            style: TextStyle(
                              color: selected ? Colors.blue : Colors.black,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                NakedSelectOption<String>(
                  value: 'banana',
                  builder: (context, states, _) {
                    final hovered = states.contains(WidgetState.hovered);
                    final selected = states.contains(WidgetState.selected);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: selected
                          ? Colors.blue.shade50
                          : hovered
                              ? Colors.grey.shade100
                              : null,
                      child: Row(
                        children: [
                          const Text('🍌'),
                          const SizedBox(width: 8),
                          Text(
                            'Banana',
                            style: TextStyle(
                              color: selected ? Colors.blue : Colors.black,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                NakedSelectOption<String>(
                  value: 'orange',
                  builder: (context, states, _) {
                    final hovered = states.contains(WidgetState.hovered);
                    final selected = states.contains(WidgetState.selected);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: selected
                          ? Colors.blue.shade50
                          : hovered
                              ? Colors.grey.shade100
                              : null,
                      child: Row(
                        children: [
                          const Text('🍊'),
                          const SizedBox(width: 8),
                          Text(
                            'Orange',
                            style: TextStyle(
                              color: selected ? Colors.blue : Colors.black,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
