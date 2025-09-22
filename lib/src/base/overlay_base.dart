/// Base abstractions for overlay widgets like [NakedMenu] and [NakedSelect].
///
/// This file provides:
/// - [OverlayScope]: InheritedWidget pattern for overlay context
/// - [OverlayItem]: Base class for overlay items (actions/options)
/// - [OverlayStateMixin]: State management for overlay widgets
library;

import 'package:flutter/widgets.dart';

import '../naked_button.dart';
import '../utilities/state.dart';

// =============================================================================
// OVERLAY SCOPE PATTERN
// =============================================================================

/// Base class for overlay scope widgets that provide context to their children.
///
/// This class provides the common pattern for InheritedWidget-based scopes
/// used by overlay widgets like NakedMenu and NakedSelect.
abstract class OverlayScope<T> extends InheritedWidget {
  const OverlayScope({required super.child, super.key});

  /// Returns the scope of the specified type that most tightly encloses the given [context].
  ///
  /// This method returns null if no scope of the specified type is found.
  @protected
  static S? maybeOf<S extends OverlayScope>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  /// Returns the scope of the specified type that most tightly encloses the given [context].
  ///
  /// If no scope is found, this method throws a [FlutterError] with a descriptive message.
  @protected
  static S of<S extends OverlayScope>(
    BuildContext context, {
    required Type scopeConsumer,
    required Type scopeOwner,
  }) {
    final S? result = maybeOf<S>(context);
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts([
          ErrorSummary('$scopeConsumer requires a $scopeOwner ancestor.'),
          ErrorDescription(
            'The $scopeConsumer widget must be placed inside the overlayBuilder '
            'callback of a $scopeOwner widget.',
          ),
          ErrorHint(
            'Ensure that $scopeConsumer is only used within:\n'
            '$scopeOwner(\n'
            '  overlayBuilder: (context, info) {\n'
            '    return $scopeConsumer(...); // ✓ Correct usage\n'
            '  },\n'
            ')',
          ),
          context.describeElement('The context used was'),
        ]);
      }

      return true;
    }());

    return result!;
  }
}

// =============================================================================
// OVERLAY ITEM PATTERN
// =============================================================================

/// Base class for overlay item widgets (actions, options, etc.)
///
/// This class provides the common pattern for widgets that represent
/// selectable/actionable items within overlay panels.
abstract class OverlayItem<T, S extends NakedState> extends StatelessWidget {
  const OverlayItem({
    super.key,
    required this.value,
    this.enabled = true,
    this.semanticLabel,
    this.child,
    this.builder,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The value associated with this item.
  final T value;

  /// Whether this item is enabled for interaction.
  final bool enabled;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Optional child widget to display.
  final Widget? child;

  /// Optional builder function for custom styling based on widget states.
  final NakedStateBuilder<S>? builder;

  /// Helper method to build a [NakedButton] with consistent behavior.
  ///
  /// This method handles the common pattern of wrapping item content
  /// in a button with proper state management.
  @protected
  Widget buildButton({
    required VoidCallback? onPressed,
    required bool effectiveEnabled,
    bool? isSelected,
    required S Function(Set<WidgetState> states) mapStates,
  }) {
    return NakedButton(
      onPressed: onPressed,
      enabled: effectiveEnabled,
      semanticLabel: semanticLabel,
      child: child,
      builder: builder == null
          ? null
          : (context, buttonState, child) {
              final effectiveStates = <WidgetState>{...buttonState.states};
              if (isSelected == true) {
                effectiveStates.add(WidgetState.selected);
              }

              return builder!(context, mapStates(effectiveStates), child);
            },
    );
  }
}

// =============================================================================
// OVERLAY STATE MANAGEMENT
// =============================================================================

/// Mixin that provides common state management for overlay widgets.
///
/// This mixin handles the shared patterns for tracking selection sessions
/// and managing overlay lifecycle callbacks.
mixin OverlayStateMixin<T extends StatefulWidget> on State<T> {
  /// Tracks whether a selection was made during the current overlay session.
  ///
  /// This is used to determine whether to call onCanceled callback when
  /// the overlay closes.
  bool _selectionMadeDuringSession = false;

  /// Returns whether a selection was made during the current session.
  @protected
  bool get selectionMadeDuringSession => _selectionMadeDuringSession;

  /// Handles overlay opening logic.
  ///
  /// Resets the selection tracking and calls the provided [onOpen] callback.
  @protected
  void handleOpen(VoidCallback? onOpen) {
    _selectionMadeDuringSession = false;
    onOpen?.call();
  }

  /// Handles overlay closing logic.
  ///
  /// If no selection was made during the session, calls [onCanceled].
  /// Always calls [onClose] and optionally requests focus on [triggerFocusNode].
  @protected
  void handleClose({
    VoidCallback? onClose,
    VoidCallback? onCanceled,
    FocusNode? triggerFocusNode,
  }) {
    if (!_selectionMadeDuringSession) {
      onCanceled?.call();
    }
    onClose?.call();
    triggerFocusNode?.requestFocus();
  }

  /// Marks that a selection was made during the current session.
  ///
  /// This prevents the onCanceled callback from being called when the overlay closes.
  @protected
  void markSelectionMade() {
    _selectionMadeDuringSession = true;
  }
}
