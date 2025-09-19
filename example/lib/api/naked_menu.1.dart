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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Animated Menu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Menu with smooth animations',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
                AnimatedMenuExample(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedMenuExample extends StatefulWidget {
  const AnimatedMenuExample({super.key});

  @override
  State<AnimatedMenuExample> createState() => _AnimatedMenuExampleState();
}

class _AnimatedMenuExampleState extends State<AnimatedMenuExample>
    with TickerProviderStateMixin {
  final _controller = MenuController();
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedMenu<String>(
      controller: _controller,
      onSelected: (item) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $item')),
        );
      },
      onOpen: () => _animationController.forward(),
      onClose: () => _animationController.reverse(),
      triggerBuilder: (context, states) {
        final isPressed = states.contains(WidgetState.pressed);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isPressed ? 0.1 : 0.05),
                blurRadius: 4,
                offset: Offset(0, isPressed ? 1 : 2),
              ),
            ],
          ),
          child: const Icon(Icons.menu, size: 20),
        );
      },
      overlayBuilder: (context, info) {
        return ScaleTransition(
          scale: _animationController.drive(Tween(begin: 0.95, end: 1.0)),
          child: FadeTransition(
            opacity: _animationController,
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
                  NakedMenuItem<String>(
                    value: 'new',
                    builder: (context, states, _) {
                      final hovered = states.contains(WidgetState.hovered);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: hovered ? Colors.grey.shade100 : null,
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 8),
                            Text('New Document'),
                          ],
                        ),
                      );
                    },
                  ),
                  NakedMenuItem<String>(
                    value: 'open',
                    builder: (context, states, _) {
                      final hovered = states.contains(WidgetState.hovered);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: hovered ? Colors.grey.shade100 : null,
                        child: const Row(
                          children: [
                            Icon(Icons.folder_open, size: 16),
                            SizedBox(width: 8),
                            Text('Open'),
                          ],
                        ),
                      );
                    },
                  ),
                  NakedMenuItem<String>(
                    value: 'save',
                    builder: (context, states, _) {
                      final hovered = states.contains(WidgetState.hovered);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: hovered ? Colors.grey.shade100 : null,
                        child: const Row(
                          children: [
                            Icon(Icons.save, size: 16),
                            SizedBox(width: 8),
                            Text('Save'),
                          ],
                        ),
                      );
                    },
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
