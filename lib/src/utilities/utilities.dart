library;

export 'naked_interactable.dart';
export 'naked_menu_anchor.dart';
export 'widget_state_extensions.dart';

/// No-op focus handler for Semantics.onFocus to satisfy lints and provide
/// a consistent focus action exposure without side effects.
void semanticsFocusNoop() {
  // Explicit return to avoid empty-block analyzer warnings.
  // ignore: avoid-unnecessary-return
  return;
}
