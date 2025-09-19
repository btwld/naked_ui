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
          child: AnimatedMenuExample(),
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
  final _menuController = MenuController();

  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
  }

  void _onMenuOpen() {
    _animationController.forward();
  }

  void _onMenuClose() {
    _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemPressed(String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item $item selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NakedMenu<String>(
      controller: _menuController,
      triggerBuilder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        final border =
            hovered || focused ? Colors.grey.shade300 : Colors.grey.shade300;
        final ring =
            focused ? Colors.blue.withValues(alpha: 0.30) : Colors.transparent;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: ring,
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: const Icon(Icons.settings, size: 18),
        );
      },
      overlayBuilder: (context, info) => ScaleTransition(
        alignment: Alignment.topLeft,
        scale: _animationController.drive(Tween<double>(begin: 0.95, end: 1.0)),
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NakedMenuItem<String>(
                  value: '1',
                  builder: (context, states, _) => ItemContent(
                    title: 'Menu Item 1',
                    states: states,
                  ),
                ),
                NakedMenuItem<String>(
                  value: '2',
                  builder: (context, states, _) => ItemContent(
                    title: 'Menu Item 2',
                    states: states,
                  ),
                ),
                NakedMenuItem<String>(
                  value: '3',
                  builder: (context, states, _) => ItemContent(
                    title: 'Menu Item 3',
                    states: states,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onSelected: _onItemPressed,
      onOpen: _onMenuOpen,
      onClose: _onMenuClose,
    );
  }
}

class ItemContent extends StatelessWidget {
  const ItemContent({
    super.key,
    required this.title,
    required this.states,
  });

  final String title;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final hovered = states.contains(WidgetState.hovered);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: hovered ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          AnimatedOpacity(
            opacity: hovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
