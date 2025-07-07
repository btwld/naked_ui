import 'package:flutter/widgets.dart';

class PressedStateRegion extends StatelessWidget {
  const PressedStateRegion({
    super.key,
    required this.child,
    this.onPressedState,
    this.onTap,
    this.enabled = true,
  });

  final bool enabled;
  final void Function(bool)? onPressedState;
  final void Function()? onTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onPressedState?.call(true) : null,
      onTapUp: enabled ? (_) => onPressedState?.call(false) : null,
      onTap: enabled ? onTap : null,
      onTapCancel: enabled ? () => onPressedState?.call(false) : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
