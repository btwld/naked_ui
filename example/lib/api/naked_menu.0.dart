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
                'Simple Menu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Click the button to see a context menu',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              SimpleMenuExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleMenuExample extends StatefulWidget {
  const SimpleMenuExample({super.key});

  @override
  State<SimpleMenuExample> createState() => _SimpleMenuExampleState();
}

class _SimpleMenuExampleState extends State<SimpleMenuExample> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return NakedMenu<String>(
      controller: _controller,
      onSelected: (item) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $item')),
        );
      },
      builder: (context, state, _) {
        final isPressed = state.isPressed;
        return Container(
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
          child: const Icon(Icons.more_vert, size: 20),
        );
      },
      overlayBuilder: (context, info) {
        return Container(
          constraints: BoxConstraints(
            minWidth: info.anchorRect.width,
            maxWidth: 200,
          ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NakedMenuItem<String>(
                value: 'edit',
                builder: (context, state, _) {
                  final hovered = state.isHovered;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: hovered ? Colors.grey.shade100 : null,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  );
                },
              ),
              NakedMenuItem<String>(
                value: 'copy',
                builder: (context, state, _) {
                  final hovered = state.isHovered;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: hovered ? Colors.grey.shade100 : null,
                    child: const Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Copy'),
                        Spacer(),
                        Text('⌘C',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
              Container(height: 1, color: Colors.grey.shade200),
              NakedMenuItem<String>(
                value: 'delete',
                builder: (context, state, _) {
                  final hovered = state.isHovered;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: hovered ? Colors.red.shade50 : null,
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
