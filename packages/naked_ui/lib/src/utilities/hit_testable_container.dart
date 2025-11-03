import 'package:flutter/rendering.dart';
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
/// The widget is designed to be invisible in the widget inspector to reduce
/// debugging noise, as it's purely an implementation detail.
///
/// Example usage:
/// ```dart
/// // Instead of:
/// ColoredBox(color: Colors.transparent, child: userWidget)
///
/// // Use:
/// HitTestableContainer(child: userWidget)
/// ```
class HitTestableContainer extends SingleChildRenderObjectWidget {
  /// Creates a hit-testable container that wraps [child].
  ///
  /// The [child] is required and will be made hit-testable regardless of
  /// its own hit testing behavior.
  const HitTestableContainer({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderHitTestableContainer();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Hide this implementation detail from the widget inspector
    // to reduce noise during debugging
    properties.add(
      DiagnosticsProperty<String>(
        'inspector',
        'hidden',
        description: 'Hidden from widget inspector as implementation detail',
        level: DiagnosticLevel.hidden,
      ),
    );
  }
}

/// Render object that ensures hit testing always succeeds within its bounds.
///
/// This render object acts as a transparent hit-testable area that:
/// 1. Always accepts hits within its bounds
/// 2. Passes hits to children when possible
/// 3. Still accepts the hit even if children reject it
/// 4. Paints only the child (no additional visual elements)
class _RenderHitTestableContainer extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Only consider hits within our bounds
    if (!size.contains(position)) {
      return false;
    }

    // Try to hit test children first
    hitTestChildren(result, position: position);

    // Always add ourselves to the hit result within bounds,
    // ensuring the area is hit-testable even if children aren't
    result.add(BoxHitTestEntry(this, position));

    // We always consider ourselves hit if the position is within bounds
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Only paint the child, no additional decoration
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    // Don't paint debug information to keep it truly invisible
    // Only paint child's debug info if debugging is enabled
    if (child != null) {
      super.debugPaintSize(context, offset);
    }
  }
}
