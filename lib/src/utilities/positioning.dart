import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef AlignmentPair = ({Alignment target, Alignment follower});

/// Configuration for overlay positioning.
class OverlayPositionConfig {
  /// Primary alignment for positioning the overlay relative to the anchor.
  final AlignmentPair alignment;

  /// Additional offset to apply after alignment positioning.
  final Offset offset;

  const OverlayPositionConfig({
    this.alignment = (
      target: Alignment.bottomLeft,
      follower: Alignment.topLeft,
    ),
    this.offset = Offset.zero,
  });
}

class OverlayPositioner extends StatelessWidget {
  const OverlayPositioner({
    super.key,
    required this.targetRect,
    this.alignment = (
      target: Alignment.bottomCenter,
      follower: Alignment.topCenter,
    ),
    this.offset = Offset.zero,
    required this.child,
  });

  final Rect targetRect;
  final AlignmentPair alignment;

  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _OverlayPositionerDelegate(
        targetPosition: targetRect.topLeft,
        targetSize: targetRect.size,
        alignment: alignment,

        offset: offset,
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

  final AlignmentPair alignment;

  final Offset offset;

  /// Creates a delegate for computing the layout of a tooltip.
  const _OverlayPositionerDelegate({
    required this.targetPosition,
    required this.targetSize,
    required this.alignment,
    required this.offset,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final targetAnchorOffset = alignment.target.alongSize(targetSize);
    final followerAnchorOffset = alignment.follower.alongSize(childSize);

    final preferedPosition =
        targetPosition + targetAnchorOffset - followerAnchorOffset + offset;

    return _clampToBounds(preferedPosition, childSize, size);
  }

  @override
  bool shouldRelayout(_OverlayPositionerDelegate oldDelegate) {
    return targetPosition != oldDelegate.targetPosition ||
        targetSize != oldDelegate.targetSize ||
        alignment.target != oldDelegate.alignment.target ||
        alignment.follower != oldDelegate.alignment.follower ||
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
