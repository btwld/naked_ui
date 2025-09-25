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
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Simple Tooltip',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hover the button to see the tooltip',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              TooltipExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class TooltipExample extends StatefulWidget {
  const TooltipExample({super.key});

  @override
  State<TooltipExample> createState() => _TooltipExampleState();
}

class _TooltipExampleState extends State<TooltipExample>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NakedTooltip(
      semanticsLabel: 'This is a tooltip',
      positioning: const OverlayPositionConfig(
        alignment: Alignment.topCenter,
        fallbackAlignment: Alignment.bottomCenter,
      ),
      waitDuration: const Duration(seconds: 0),
      showDuration: const Duration(seconds: 0),
      // onOpen: () => _animationController.forward(),
      // onClose: () => _animationController.reverse(),
      overlayBuilder: (context, info) => Align(
        child: Container(
          height: 100,
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text('This is a tooltip'),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D3D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Hover me',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
