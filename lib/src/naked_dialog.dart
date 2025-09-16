import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Provides dialog functionality without default styling.
///
/// Unlike [showDialog], this is headless: it does not impose any visuals.
/// You control all appearance via [builder] (no default background, radius, or padding).
///
/// Returns a [Future] that resolves with the value passed to [Navigator.pop],
/// or null if dismissed. The [barrierColor] is required and controls both the
/// visual scrim and (together with [barrierDismissible]) barrier hit testing.
///
/// Tip: If you depend on Material, pass a localized barrier label:
/// `barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel`.
///
/// Example:
/// ```dart
/// final result = await showNakedDialog<String>(
///   context: context,
///   barrierColor: Colors.black54,
///   barrierLabel: 'Dismiss', // or MaterialLocalizations...
///   builder: (context) => NakedDialog(
///     modal: true,
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
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                },
                child: Actions(
                  actions: {
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) => Navigator.of(routeContext).maybePop(),
                    ),
                  },
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

/// Provides dialog semantics for modal dialog content.
///
/// - When [modal] is true (default), wraps content with [BlockSemantics] to
///   prevent reading/interaction with background content.
/// - Uses [scopesRoute]/[namesRoute] so screen readers treat this as a route.
class NakedDialog extends StatelessWidget {
  const NakedDialog({
    super.key,
    required this.child,
    this.modal = true,
    this.semanticLabel,
  });

  final Widget child;
  final bool modal;
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
