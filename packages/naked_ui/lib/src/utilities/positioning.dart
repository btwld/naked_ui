import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Configuration for overlay positioning.
class OverlayPositionConfig {
  /// Primary alignment for positioning the overlay relative to the anchor.
  final Alignment targetAnchor;

  /// Alignment on the overlay that is placed at [targetAnchor].
  final Alignment followerAnchor;

  /// Additional offset to apply after alignment positioning.
  final Offset offset;

  /// Creates overlay positioning configuration.
  const OverlayPositionConfig({
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
  });
}

/// Positions an overlay relative to an anchor rectangle and clamps it on-screen.
class OverlayPositioner extends StatelessWidget {
  /// Creates a positioner for [child] relative to [targetRect].
  const OverlayPositioner({
    super.key,
    required this.targetRect,
    this.positioning = const OverlayPositionConfig(),
    required this.child,
  });

  /// The anchor rectangle in the overlay's coordinate space.
  final Rect targetRect;

  /// Alignment and offset configuration for the overlay.
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

    return clampOverlayPosition(
      preferredPosition,
      overlaySize: childSize,
      boundsSize: size,
    );
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

/// Clamps an overlay's top-left position to its available layout bounds.
///
/// If the overlay is larger than the available bounds on either axis, that
/// axis is pinned to zero. This keeps the result valid and lets the overlay's
/// own clipping or scrolling policy decide how to expose oversized content.
Offset clampOverlayPosition(
  Offset overlayTopLeft, {
  required Size overlaySize,
  required Size boundsSize,
}) {
  final maxX = math.max(0.0, boundsSize.width - overlaySize.width);
  final maxY = math.max(0.0, boundsSize.height - overlaySize.height);

  return Offset(
    overlayTopLeft.dx.clamp(0.0, maxX),
    overlayTopLeft.dy.clamp(0.0, maxY),
  );
}
