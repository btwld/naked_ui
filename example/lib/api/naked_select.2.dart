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
          child: AnimatedBuilderSelectExample(),
        ),
      ),
    );
  }
}

class AnimatedBuilderSelectExample extends StatefulWidget {
  const AnimatedBuilderSelectExample({super.key});

  @override
  State<AnimatedBuilderSelectExample> createState() =>
      _AnimatedBuilderSelectExampleState();
}

class _AnimatedBuilderSelectExampleState
    extends State<AnimatedBuilderSelectExample> with TickerProviderStateMixin {
  String? _selectedValue;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final CurvedAnimation _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: NakedSelect<String>(
        value: _selectedValue,
        onChanged: (value) => setState(() => _selectedValue = value),
        onOpen: _controller.forward,
        onClose: _controller.reverse,
        overlayBuilder: (context, info) {
          return ScaleTransition(
            scale: _controller.drive(Tween<double>(
              begin: 0.98,
              end: 1,
            )),
            child: SlideTransition(
              position: _controller.drive(Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              )),
              child: FadeTransition(
                opacity: _fade,
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
                        value: 'Apple',
                        builder: (context, states, child) {
                          final bool isHovered = states.contains(WidgetState.hovered);
                          final bool isSelected = states.contains(WidgetState.selected);

                          final Color backgroundColor = isSelected
                              ? (isHovered ? Colors.blue.shade100 : Colors.blue.shade50)
                              : (isHovered ? Colors.grey.shade100 : Colors.transparent);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Apple',
                                    style: TextStyle(
                                      color:
                                          isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.blue.shade600,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      NakedSelectOption<String>(
                        value: 'Banana',
                        builder: (context, states, child) {
                          final bool isHovered = states.contains(WidgetState.hovered);
                          final bool isSelected = states.contains(WidgetState.selected);

                          final Color backgroundColor = isSelected
                              ? (isHovered ? Colors.blue.shade100 : Colors.blue.shade50)
                              : (isHovered ? Colors.grey.shade100 : Colors.transparent);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Banana',
                                    style: TextStyle(
                                      color:
                                          isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.blue.shade600,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      NakedSelectOption<String>(
                        value: 'Orange',
                        builder: (context, states, child) {
                          final bool isHovered = states.contains(WidgetState.hovered);
                          final bool isSelected = states.contains(WidgetState.selected);

                          final Color backgroundColor = isSelected
                              ? (isHovered ? Colors.blue.shade100 : Colors.blue.shade50)
                              : (isHovered ? Colors.grey.shade100 : Colors.transparent);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Orange',
                                    style: TextStyle(
                                      color:
                                          isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.blue.shade600,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      NakedSelectOption<String>(
                        value: 'Mango',
                        builder: (context, states, child) {
                          final bool isHovered = states.contains(WidgetState.hovered);
                          final bool isSelected = states.contains(WidgetState.selected);

                          final Color backgroundColor = isSelected
                              ? (isHovered ? Colors.blue.shade100 : Colors.blue.shade50)
                              : (isHovered ? Colors.grey.shade100 : Colors.transparent);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Mango',
                                    style: TextStyle(
                                      color:
                                          isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.blue.shade600,
                                  ),
                              ],
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
          final bool isFocused = states.contains(WidgetState.focused);
          final bool isHovered = states.contains(WidgetState.hovered);

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
              children: [
                Expanded(
                  child: Text(
                    _selectedValue ?? 'Select your favorite fruit',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
