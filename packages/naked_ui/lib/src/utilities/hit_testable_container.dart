import 'package:flutter/widgets.dart';

/// Internal utility widget that ensures its child is hit-testable.
///
/// This widget guarantees that the entire bounded area responds to hit testing,
/// even if the child widget itself is not hit-testable (e.g., empty Container,
/// SizedBox, or other layout-only widgets).
///
/// This is particularly useful for headless UI components where users might
/// provide builders that return non-hit-testable widgets, but the component
/// needs to ensure consistent interaction behavior.
///
/// Example usage:
/// ```dart
/// // Instead of:
/// ColoredBox(color: Colors.transparent, child: userWidget)
///
/// // Use:
/// HitTestableContainer(child: userWidget)
/// ```
class HitTestableContainer extends StatelessWidget {
  /// Creates a hit-testable container that wraps [child].
  ///
  /// The [child] is required and will be made hit-testable regardless of
  /// its own hit testing behavior.
  const HitTestableContainer({super.key, required this.child});

  /// The widget whose bounds should participate in hit testing.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(behavior: HitTestBehavior.opaque, child: child);
  }
}
