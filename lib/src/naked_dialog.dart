import 'package:flutter/widgets.dart';

import 'utilities/intents.dart';

/// Displays a headless dialog without default styling.
///
/// Unlike [showDialog], imposes no visuals—you control all appearance
/// via [builder]. The [barrierColor] is required and controls both
/// visual scrim and barrier hit testing.
///
/// Returns a [Future] with the value passed to [Navigator.pop], or null
/// if dismissed.
///
/// Example:
/// ```dart
/// final result = await showNakedDialog<String>(
///   context: context,
///   barrierColor: Colors.black54,
///   barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
///   builder: (context) => NakedDialog(
///     semanticLabel: 'Confirmation Dialog',
///     child: YourCustomContent(),
///   ),
/// );
/// ```
Future<T?> showNakedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required Color barrierColor,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  Duration transitionDuration = const Duration(milliseconds: 400),
  RouteTransitionsBuilder? transitionBuilder,
  bool requestFocus = true,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  return navigator.push<T>(
    RawDialogRoute<T>(
      pageBuilder:
          (
            BuildContext routeContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            // Headless content provided by the caller.
            final Widget content = builder(routeContext);

            // Trap traversal within the dialog subtree. This is resilient even if
            // the content contains its own traversal groups (nested forms, lists, etc.).
            Widget wrapped = FocusTraversalGroup(child: content);

            // Close on Escape only if barrier is dismissible.
            // This mirrors barrier tap policy and keeps behavior predictable.
            if (barrierDismissible) {
              wrapped = Shortcuts(
                shortcuts: NakedIntentActions.dialog.shortcuts,
                child: Actions(
                  actions: NakedIntentActions.dialog.actions(
                    onDismiss: () => Navigator.of(routeContext).maybePop(),
                  ),
                  child: wrapped,
                ),
              );
            }

            return themes.wrap(wrapped);
          },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel, // strongly recommended to pass a label
      transitionDuration: transitionDuration,
      transitionBuilder: transitionBuilder,
      settings: routeSettings,
      requestFocus: requestFocus,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior:
          traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
    ),
  );
}

/// Provides modal dialog semantics and accessibility.
///
/// When [modal] is true, blocks background content interaction and
/// configures screen reader route semantics.
class NakedDialog extends StatelessWidget {
  const NakedDialog({
    super.key,
    required this.child,
    this.modal = true,
    this.semanticLabel,
  });

  /// The dialog content.
  final Widget child;

  /// Whether to block background content interaction.
  final bool modal;

  /// The semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget dialog = Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: modal,
      namesRoute: modal,
      label: semanticLabel,
      child: child,
    );

    // Prevent reading/interaction with background content when modal.
    if (modal) {
      dialog = BlockSemantics(child: dialog);
    }

    return dialog;
  }
}
