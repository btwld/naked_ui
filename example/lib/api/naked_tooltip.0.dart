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
      semanticsLabel: 'This is a tooltip',
      positioning: const OverlayPositionConfig(
        alignment: Alignment.topCenter,
        fallbackAlignment: Alignment.bottomCenter,
      ),
      waitDuration: const Duration(seconds: 0),
      showDuration: const Duration(seconds: 0),
      onOpen: () => _animationController.forward(),
      onClose: () => _animationController.reverse(),
      tooltipBuilder: (context) => SlideTransition(
        position: _animationController.drive(Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: const Offset(0, 0),
        )),
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            // Add gap between tooltip and trigger, since follower is aligned on its bottom.
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const DefaultTextStyle(
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
                child: Text('This is a tooltip'),
              ),
            ),
          ),
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
