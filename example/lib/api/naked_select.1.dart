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
          child: AnimatedSelectExample(),
        ),
      ),
    );
  }
}

class AnimatedSelectExample extends StatefulWidget {
  const AnimatedSelectExample({super.key});

  @override
  State<AnimatedSelectExample> createState() => _AnimatedSelectExampleState();
}

class _AnimatedSelectExampleState extends State<AnimatedSelectExample>
    with TickerProviderStateMixin {
  String? _selectedValue;

  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) {
          setState(() => _selectedValue = value);
        },
        onOpen: () => _animationController.forward(),
        onClose: () => _animationController.reverse(),
        overlayBuilder: (context, info) {
          return SlideTransition(
            position: _animationController.drive(Tween<Offset>(
              begin: const Offset(0, -0.05),
              end: Offset.zero,
            )),
            child: FadeTransition(
              opacity: _animation,
              child: SizedBox(
                width: 250,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NakedSelectOption<String>(
                        value: 'Option 1',
                        builder: (context, states, child) {
                          final isHovered = states.contains(WidgetState.hovered);
                          final isFocused = states.contains(WidgetState.focused);

                          final Color backgroundColor = isHovered
                              ? Colors.grey.shade100
                              : isFocused
                                  ? Colors.grey.shade50
                                  : Colors.transparent;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Option 1',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                      NakedSelectOption<String>(
                        value: 'Option 2',
                        builder: (context, states, child) {
                          final isHovered = states.contains(WidgetState.hovered);
                          final isFocused = states.contains(WidgetState.focused);

                          final Color backgroundColor = isHovered
                              ? Colors.grey.shade100
                              : isFocused
                                  ? Colors.grey.shade50
                                  : Colors.transparent;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Option 2',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                      NakedSelectOption<String>(
                        value: 'Option 3',
                        builder: (context, states, child) {
                          final isHovered = states.contains(WidgetState.hovered);
                          final isFocused = states.contains(WidgetState.focused);

                          final Color backgroundColor = isHovered
                              ? Colors.grey.shade100
                              : isFocused
                                  ? Colors.grey.shade50
                                  : Colors.transparent;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Option 3',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        triggerBuilder: (context, states) {
          final isFocused = states.contains(WidgetState.focused);
          final isHovered = states.contains(WidgetState.hovered);

          final Color borderColor = isFocused
              ? Colors.grey.shade800
              : isHovered
                  ? Colors.grey.shade100
                  : Colors.grey.shade300;

          final Color backgroundColor =
              isHovered ? Colors.grey.shade100 : Colors.white;

          final List<BoxShadow> boxShadow = isFocused
              ? [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 0,
                    spreadRadius: 4,
                    offset: Offset.zero,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 0,
                    spreadRadius: 2,
                    offset: Offset.zero,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: boxShadow,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedValue ?? 'Select your favorite fruit'),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

