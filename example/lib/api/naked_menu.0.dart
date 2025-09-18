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
          child: MenuExample(),
        ),
      ),
    );
  }
}

class MenuExample extends StatefulWidget {
  const MenuExample({super.key});

  @override
  State<MenuExample> createState() => _MenuExampleState();
}

class _MenuExampleState extends State<MenuExample> {
  final _controller = MenuController();

  void _onItemPressed(String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item $item selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NakedMenu(
      autofocus: true,
      builder: (context) => NakedButton(
        onPressed: () => _controller.open(),
        focusOnPress: true,
        builder: (context, states, _) {
          final hovered = states.contains(WidgetState.hovered);
          final focused = states.contains(WidgetState.focused);
          final border =
              hovered || focused ? Colors.grey.shade300 : Colors.grey.shade300;
          final ring =
              focused ? Colors.blue.withOpacity(0.30) : Colors.transparent;
          return Container(
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
                      )
                    ]
                  : const [],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.more_vert, size: 18),
          );
        },
      ),
      overlayBuilder: (context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 280,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuItemTile(
              icon: Icons.person,
              title: 'Profile',
              shortcut: 'P',
              onPressed: () => _onItemPressed('Profile'),
            ),
            MenuItemTile(
              icon: Icons.link,
              title: 'Copy link',
              shortcut: '⌘C',
              onPressed: () => _onItemPressed('Copy link'),
            ),
            const _Hairline(),
            MenuItemTile(
              icon: Icons.delete_outline,
              title: 'Delete',
              destructive: true,
              shortcut: '⌘⌫',
              onPressed: () => _onItemPressed('Delete'),
            ),
            const MenuItemTile(
              icon: Icons.history,
              title: 'Revert',
              onPressed: null, // disabled example
            ),
          ],
        ),
      ),
      controller: _controller,
    );
  }
}

class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    super.key,
    required this.icon,
    required this.title,
    this.shortcut,
    this.destructive = false,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? shortcut;
  final bool destructive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return NakedMenuItem(
      onPressed: onPressed,
      semanticLabel: title,
      builder: (context, states, _) {
        final hovered = states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        final disabled = states.contains(WidgetState.disabled);

        final bg = hovered || focused ? Colors.grey.shade100 : Colors.white;
        final textColor = disabled
            ? Colors.grey.shade400
            : (destructive ? Colors.red.shade700 : Colors.black87);
        final iconColor = disabled
            ? Colors.grey.shade400
            : (destructive ? Colors.red.shade700 : Colors.grey.shade700);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut!,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey.shade200,
    );
  }
}
