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
    return NakedMenu(
      builder: (context) => NakedButton(
        onPressed: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
            _onMenuOpen();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.settings, size: 18),
        ),
      ),
      overlayBuilder: (context) => ScaleTransition(
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
            constraints: const BoxConstraints(
              maxWidth: 200,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ItemContent(
                  title: 'Menu Item 1',
                  onPressed: () => _onItemPressed('1'),
                ),
                ItemContent(
                  title: 'Menu Item 2',
                  onPressed: () => _onItemPressed('2'),
                ),
                ItemContent(
                  title: 'Menu Item 3',
                  onPressed: () => _onItemPressed('3'),
                ),
              ],
            ),
          ),
        ),
      ),
      controller: _menuController,
      onClose: _onMenuClose,
    );
  }
}

class ItemContent extends StatefulWidget {
  const ItemContent({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  State<ItemContent> createState() => _ItemContentState();
}

class _ItemContentState extends State<ItemContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return NakedMenuItem(
      onPressed: widget.onPressed,
      onHoverChange: (hovered) => setState(() => _isHovered = hovered),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.title),
          AnimatedOpacity(
            opacity: _isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ),
        ]),
      ),
    );
  }
}
