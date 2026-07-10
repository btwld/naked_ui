import 'package:flutter/widgets.dart';

/// Configuration for overlay positioning.
class OverlayPositionConfig {
  /// Primary alignment for positioning the overlay relative to the anchor.
  final Alignment targetAnchor;

  /// Alignment on the overlay placed at [targetAnchor].
  final Alignment followerAnchor;

  /// Additional offset to apply after alignment positioning.
  final Offset offset;

  /// Creates an overlay positioning configuration.
  const OverlayPositionConfig({
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
  });
}

/// Positions [child] relative to the global [targetRect].
class OverlayPositioner extends StatelessWidget {
  /// Creates a positioner for [targetRect].
  const OverlayPositioner({
    super.key,
    required this.targetRect,
    this.positioning = const OverlayPositionConfig(),
    required this.child,
  });

  /// The anchor rectangle in global coordinates.
  final Rect targetRect;

  /// The alignments and offset applied to [child].
  final OverlayPositionConfig positioning;

  /// The overlay content to position.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _OverlayPositionerDelegate(
        targetPosition: targetRect.topLeft,
        targetSize: targetRect.size,
        targetAnchor: positioning.targetAnchor,
        followerAnchor: positioning.followerAnchor,
        offset: positioning.offset,
      ),
      child: child,
    );
  }
}

class _OverlayPositionerDelegate extends SingleChildLayoutDelegate {
  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset targetPosition;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final Size targetSize;

  final Alignment targetAnchor;
  final Alignment followerAnchor;

  final Offset offset;

  /// Creates a delegate for computing the layout of a tooltip.
  const _OverlayPositionerDelegate({
    required this.targetPosition,
    required this.targetSize,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final targetAnchorOffset = targetAnchor.alongSize(targetSize);
    final followerAnchorOffset = followerAnchor.alongSize(childSize);

    final preferredPosition =
        targetPosition + targetAnchorOffset - followerAnchorOffset + offset;

    return clampOverlayToBounds(preferredPosition, childSize, size);
  }

  @override
  bool shouldRelayout(_OverlayPositionerDelegate oldDelegate) {
    return targetPosition != oldDelegate.targetPosition ||
        targetSize != oldDelegate.targetSize ||
        targetAnchor != oldDelegate.targetAnchor ||
        followerAnchor != oldDelegate.followerAnchor ||
        offset != oldDelegate.offset;
  }
}

/// Keeps an overlay origin inside the available size.
///
/// This is public only so the package's internal positioning contract can be
/// unit tested. It is not exported from `package:naked_ui/naked_ui.dart`.
Offset clampOverlayToBounds(
  Offset overlayTopLeft,
  Size overlaySize,
  Size screenSize,
) {
  final maxX = screenSize.width > overlaySize.width
      ? screenSize.width - overlaySize.width
      : 0.0;
  final maxY = screenSize.height > overlaySize.height
      ? screenSize.height - overlaySize.height
      : 0.0;

  return Offset(
    overlayTopLeft.dx.clamp(0.0, maxX),
    overlayTopLeft.dy.clamp(0.0, maxY),
  );
}
