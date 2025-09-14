import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

class SwitchExample extends StatefulWidget {
  const SwitchExample({super.key});

  @override
  State<SwitchExample> createState() => _SwitchExampleState();
}

class _SwitchExampleState extends State<SwitchExample> {
  bool _value = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  Color get _trackColor {
    if (!_value) return const Color(0xFFE5E7EB);
    if (_pressed) return const Color(0xFF3D3D3D).withValues(alpha: 0.9);
    if (_hovered) return const Color(0xFF3D3D3D).withValues(alpha: 0.8);
    return const Color(0xFF3D3D3D).withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return NakedSwitch(
      value: _value,
      onChanged: (next) => setState(() => _value = (next ?? false)),
      onHoverChange: (h) => setState(() => _hovered = h),
      onPressChange: (p) => setState(() => _pressed = p),
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: _trackColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? const Color(0xFF111827) : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

