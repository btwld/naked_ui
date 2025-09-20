import 'package:flutter/widgets.dart';

/// Configuration for overlay positioning.
class OverlayPositionConfig {
  /// Primary alignment for positioning the overlay relative to the anchor.
  final Alignment alignment;

  /// Fallback alignment when primary doesn't fit.
  final Alignment? fallbackAlignment;

  /// Additional offset to apply after alignment positioning.
  final Offset offset;

  /// Whether to match the anchor's width.
  final bool matchWidth;

  /// Minimum width constraint for the overlay.
  final double? minWidth;

  /// Maximum width constraint for the overlay.
  final double? maxWidth;

  /// Maximum height constraint for the overlay.
  final double? maxHeight;

  const OverlayPositionConfig({
    this.alignment = Alignment.bottomCenter,
    this.fallbackAlignment,
    this.offset = Offset.zero,
    this.matchWidth = false,
    this.minWidth,
    this.maxWidth,
    this.maxHeight,
  });
}

/// Calculates overlay position using alignment-based positioning.
///
/// Returns a [Rect] that can be used with [Positioned.fromRect].
Rect calculateOverlayPosition({
  required Rect anchorRect,
  required Size overlaySize,
  required Size childSize,
  required OverlayPositionConfig config,
  Offset? pointerPosition,
}) {
  // If pointer position is provided (context menu), position relative to that
  if (pointerPosition != null) {
    final followerAnchor = config.alignment.alongSize(childSize);
    final desired = pointerPosition - followerAnchor + config.offset;

    return _clampToBounds(
      Rect.fromLTWH(desired.dx, desired.dy, childSize.width, childSize.height),
      overlaySize,
    );
  }

  // Try primary alignment first
  final primaryRect = _calculateAlignedRect(
    anchorRect,
    childSize,
    config.alignment,
    config.offset,
    config.matchWidth,
  );

  if (_fitsInBounds(primaryRect, overlaySize)) {
    return _applyConstraints(primaryRect, config);
  }

  // Try fallback alignment if primary doesn't fit
  if (config.fallbackAlignment != null) {
    final fallbackRect = _calculateAlignedRect(
      anchorRect,
      childSize,
      config.fallbackAlignment!,
      config.offset,
      config.matchWidth,
    );

    if (_fitsInBounds(fallbackRect, overlaySize)) {
      return _applyConstraints(fallbackRect, config);
    }
  }

  // If nothing fits, clamp primary to bounds
  final clampedRect = _clampToBounds(primaryRect, overlaySize);

  return _applyConstraints(clampedRect, config);
}

/// Calculates positioned rect for given alignment.
Rect _calculateAlignedRect(
  Rect anchorRect,
  Size childSize,
  Alignment alignment,
  Offset offset,
  bool matchWidth,
) {
  final targetPoint = alignment.alongSize(anchorRect.size);
  final anchorPoint = (-alignment).alongSize(childSize);
  final position = anchorRect.topLeft + targetPoint + anchorPoint + offset;

  final width = matchWidth ? anchorRect.width : childSize.width;

  return Rect.fromLTWH(position.dx, position.dy, width, childSize.height);
}

/// Checks if rect fits within overlay bounds.
bool _fitsInBounds(Rect rect, Size overlaySize) {
  return rect.left >= 0 &&
      rect.top >= 0 &&
      rect.right <= overlaySize.width &&
      rect.bottom <= overlaySize.height;
}

/// Clamps rect to overlay bounds.
Rect _clampToBounds(Rect rect, Size overlaySize) {
  final left = rect.left.clamp(0.0, overlaySize.width - rect.width);
  final top = rect.top.clamp(0.0, overlaySize.height - rect.height);

  return Rect.fromLTWH(left, top, rect.width, rect.height);
}

/// Applies width/height constraints to rect.
Rect _applyConstraints(Rect rect, OverlayPositionConfig config) {
  double width = rect.width;
  double height = rect.height;

  if (config.minWidth != null) {
    width = width.clamp(config.minWidth!, double.infinity);
  }
  if (config.maxWidth != null) {
    width = width.clamp(0.0, config.maxWidth!);
  }
  if (config.maxHeight != null) {
    height = height.clamp(0.0, config.maxHeight!);
  }

  return Rect.fromLTWH(rect.left, rect.top, width, height);
}
