import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Configuration for overlay positioning.
class OverlayPositionConfig {
  /// Primary alignment for positioning the overlay relative to the anchor.
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  /// Additional offset to apply after alignment positioning.
  final Offset offset;

  const OverlayPositionConfig({
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
  });
}

class OverlayPositioner extends StatelessWidget {
  const OverlayPositioner({
    super.key,
    required this.targetRect,
    this.positioning = const OverlayPositionConfig(),
    required this.child,
  });

  final Rect targetRect;

  final OverlayPositionConfig positioning;
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

    final preferedPosition =
        targetPosition + targetAnchorOffset - followerAnchorOffset + offset;

    return _clampToBounds(preferedPosition, childSize, size);
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

Offset _clampToBounds(
  Offset overlayTopLeft,
  Size overlaySize,
  Size screenSize,
) {
  return Offset(
    overlayTopLeft.dx.clamp(0.0, screenSize.width - overlaySize.width),
    overlayTopLeft.dy.clamp(0.0, screenSize.height - overlaySize.height),
  );
}
