library;

export 'naked_interactable.dart';
export 'naked_menu_anchor.dart';
export 'widget_state_extensions.dart';

/// No-op focus handler for Semantics.onFocus to satisfy lints and provide
/// a consistent focus action exposure without side effects.
void semanticsFocusNoop() {
  // ignore: avoid-unnecessary-return
  return;
}
