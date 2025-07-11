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
          child: TooltipExample(),
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
      position: const NakedMenuPosition(
        target: Alignment.topCenter,
        follower: Alignment.bottomCenter,
      ),
      waitDuration: const Duration(seconds: 0),
      showDuration: const Duration(seconds: 0),
      removalDelay: const Duration(milliseconds: 300),
      onStateChange: (state) {
        state == OverlayChildLifecycleState.present
            ? _animationController.forward()
            : _animationController.reverse();
      },
      tooltipBuilder: (context) => SlideTransition(
        position: _animationController.drive(Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: const Offset(0, 0),
        )),
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'This is a tooltip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D3D),
          borderRadius: BorderRadius.circular(4),
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
