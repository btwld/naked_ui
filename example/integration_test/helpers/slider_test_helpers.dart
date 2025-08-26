import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';

extension SliderTestHelpers on WidgetTester {
  /// Simulate drag gesture to change slider value
  Future<void> dragSlider(Finder finder, double targetValue) async {
    final slider = widget<NakedSlider>(finder);
    final box = getSize(finder);
    final center = getCenter(finder);
    
    // Calculate position based on target value
    final normalizedValue = (targetValue - slider.min) / (slider.max - slider.min);
    final targetOffset = Offset(box.width * normalizedValue, center.dy);
    
    // Start drag from current position to target
    final gesture = await startGesture(center);
    await pump();
    await gesture.moveTo(targetOffset);
    await pump();
    await gesture.up();
    await pump();
  }
  
  /// Verify slider value matches expected value
  void expectSliderValue(Finder finder, double expected, {double tolerance = 0.01}) {
    final slider = widget<NakedSlider>(finder);
    expect(slider.value, closeTo(expected, tolerance));
  }
  
  /// Send keyboard arrow keys to slider
  Future<void> sendArrowKey(LogicalKeyboardKey key) async {
    await sendKeyEvent(key);
    await pump();
  }
  
  /// Send Home/End keys to slider
  Future<void> sendHomeEndKey(LogicalKeyboardKey key) async {
    await sendKeyEvent(key);
    await pump();
  }
}