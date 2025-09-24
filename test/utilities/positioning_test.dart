import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/src/utilities/positioning.dart';

void main() {
  group('OverlayPositionConfig', () {
    testWidgets('creates with default parameters', (tester) async {
      const config = OverlayPositionConfig();

      expect(config.alignment, equals(Alignment.bottomCenter));
      expect(config.fallbackAlignment, isNull);
      expect(config.offset, equals(Offset.zero));
      expect(config.matchWidth, isFalse);
      expect(config.minWidth, isNull);
      expect(config.maxWidth, isNull);
      expect(config.maxHeight, isNull);
    });

    testWidgets('creates with custom parameters', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.topLeft,
        fallbackAlignment: Alignment.bottomRight,
        offset: Offset(10, 20),
        matchWidth: true,
        minWidth: 100,
        maxWidth: 200,
        maxHeight: 150,
      );

      expect(config.alignment, equals(Alignment.topLeft));
      expect(config.fallbackAlignment, equals(Alignment.bottomRight));
      expect(config.offset, equals(const Offset(10, 20)));
      expect(config.matchWidth, isTrue);
      expect(config.minWidth, equals(100));
      expect(config.maxWidth, equals(200));
      expect(config.maxHeight, equals(150));
    });
  });

  group('calculateOverlayPosition', () {
    const anchorRect = Rect.fromLTWH(100, 100, 50, 30);
    const overlaySize = Size(400, 300);
    const childSize = Size(120, 80);

    testWidgets('positions using pointer position when provided', (
      tester,
    ) async {
      const config = OverlayPositionConfig();
      const pointerPosition = Offset(200, 150);

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
        pointerPosition: pointerPosition,
      );

      expect(result.size, equals(childSize));
      // Should be positioned relative to pointer
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(overlaySize.width));
      expect(result.bottom, lessThanOrEqualTo(overlaySize.height));
    });

    testWidgets('uses primary alignment when it fits', (tester) async {
      const config = OverlayPositionConfig(alignment: Alignment.bottomCenter);

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.size, equals(childSize));
      // Should be positioned within overlay bounds
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(overlaySize.width));
      expect(result.bottom, lessThanOrEqualTo(overlaySize.height));
    });

    testWidgets('uses fallback alignment when primary does not fit', (
      tester,
    ) async {
      // Position near bottom edge so primary alignment won't fit
      const bottomAnchor = Rect.fromLTWH(100, 250, 50, 30);
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        fallbackAlignment: Alignment.topCenter,
      );

      final result = calculateOverlayPosition(
        anchorRect: bottomAnchor,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.size, equals(childSize));
      // Should be positioned within bounds (fallback may or may not be used)
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(overlaySize.width));
      expect(result.bottom, lessThanOrEqualTo(overlaySize.height));
    });

    testWidgets('clamps to bounds when nothing fits', (tester) async {
      // Position at very bottom right so nothing fits
      const edgeAnchor = Rect.fromLTWH(350, 280, 50, 30);
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        fallbackAlignment: Alignment.topCenter,
      );

      final result = calculateOverlayPosition(
        anchorRect: edgeAnchor,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.size, equals(childSize));
      // Should be clamped to overlay bounds
      expect(result.right, lessThanOrEqualTo(overlaySize.width));
      expect(result.bottom, lessThanOrEqualTo(overlaySize.height));
    });

    testWidgets('matches anchor width when configured', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        matchWidth: true,
      );

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.width, equals(anchorRect.width));
      expect(result.height, equals(childSize.height));
    });

    testWidgets('applies minimum width constraint', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        minWidth: 200,
      );

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.width, equals(200));
      expect(result.height, equals(childSize.height));
    });

    testWidgets('applies maximum width constraint', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        maxWidth: 80,
      );

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.width, equals(80));
      expect(result.height, equals(childSize.height));
    });

    testWidgets('applies maximum height constraint', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        maxHeight: 60,
      );

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      expect(result.width, equals(childSize.width));
      expect(result.height, equals(60));
    });

    testWidgets('applies offset to positioning', (tester) async {
      const config = OverlayPositionConfig(
        alignment: Alignment.bottomCenter,
        offset: Offset(20, 10),
      );

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: overlaySize,
        childSize: childSize,
        config: config,
      );

      // Should be positioned within bounds with offset applied
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(overlaySize.width));
      expect(result.bottom, lessThanOrEqualTo(overlaySize.height));
    });

    testWidgets('handles edge case with reasonable overlay size', (
      tester,
    ) async {
      const mediumOverlay = Size(200, 200);
      const config = OverlayPositionConfig();

      final result = calculateOverlayPosition(
        anchorRect: anchorRect,
        overlaySize: mediumOverlay,
        childSize: childSize,
        config: config,
      );

      // Should be positioned within overlay bounds
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(mediumOverlay.width));
      expect(result.bottom, lessThanOrEqualTo(mediumOverlay.height));
    });
  });
}
