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
          child: SelectExample(),
        ),
      ),
    );
  }
}

class SelectExample extends StatefulWidget {
  const SelectExample({super.key});

  @override
  State<SelectExample> createState() => _SelectExampleState();
}

class _SelectExampleState extends State<SelectExample>
    with TickerProviderStateMixin {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NakedSelect<String>(
        value: _selectedValue,
        closeOnSelect: true,
        onChanged: (value) {
          setState(() => _selectedValue = value);
        },
        overlayBuilder: (context, info) {
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NakedSelectOption<String>(
                    value: 'Option 1',
                    builder: (context, states, child) {
                      final isHovered = states.contains(WidgetState.hovered);
                      final isSelected = states.contains(WidgetState.selected);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : isHovered
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Option 1',
                          style: TextStyle(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  NakedSelectOption<String>(
                    value: 'Option 2',
                    builder: (context, states, child) {
                      final isHovered = states.contains(WidgetState.hovered);
                      final isSelected = states.contains(WidgetState.selected);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : isHovered
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Option 2',
                          style: TextStyle(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  NakedSelectOption<String>(
                    value: 'Option 3',
                    builder: (context, states, child) {
                      final isHovered = states.contains(WidgetState.hovered);
                      final isSelected = states.contains(WidgetState.selected);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : isHovered
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Option 3',
                          style: TextStyle(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        triggerBuilder: (context, states) {
          final isFocused = states.contains(WidgetState.focused);
          final isHovered = states.contains(WidgetState.hovered);

          Color borderColor;
          if (isFocused) {
            borderColor = Colors.blue.shade600;
          } else if (isHovered) {
            borderColor = Colors.grey.shade400;
          } else {
            borderColor = Colors.grey.shade300;
          }

          final Color backgroundColor = isFocused
              ? Colors.blue.shade50
              : isHovered
                  ? Colors.grey.shade50
                  : Colors.white;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isFocused)
                  BoxShadow(
                    color: Colors.blue.shade200.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedValue ?? 'Select an option',
                  style: TextStyle(
                    color: _selectedValue != null
                        ? Colors.grey.shade800
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isFocused ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
