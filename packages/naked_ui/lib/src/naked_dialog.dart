import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'utilities/intents.dart';

/// Displays a headless dialog without default styling.
///
/// Unlike [showDialog], imposes no visuals—appearance is fully controlled by
/// [builder]. The [barrierColor] is required and controls both visual scrim
/// and barrier hit testing.
///
/// Returns a [Future] with the value passed to [Navigator.pop], or null if dismissed.
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
///
/// See also:
/// - [showDialog], the Material-styled dialog for typical apps.
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
            final Widget content = builder(routeContext);
            Widget wrapped = FocusTraversalGroup(child: content);

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
      barrierLabel: barrierLabel,
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
///
/// Automatically focuses the first focusable descendant when mounted,
/// following ARIA dialog focus behavior.
///
/// See also:
/// - [showNakedDialog], the function that displays dialogs.
class NakedDialog extends StatefulWidget {
  const NakedDialog({
    super.key,
    required this.child,
    this.modal = true,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  /// The dialog content.
  final Widget child;

  /// Whether to block background content interaction.
  final bool modal;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  @override
  State<NakedDialog> createState() => _NakedDialogState();
}

class _NakedDialogState extends State<NakedDialog> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _focusFirstFocusable();
    });
  }

  void _focusFirstFocusable() {
    if (!mounted) return;

    final scope = FocusScope.of(context);
    // Find the first focusable descendant and focus it
    final firstFocusable = scope.traversalDescendants.firstOrNull;
    if (firstFocusable != null && firstFocusable.canRequestFocus) {
      firstFocusable.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget dialog = widget.excludeSemantics
        ? widget.child
        : Semantics(
            container: true,
            explicitChildNodes: true,
            scopesRoute: widget.modal,
            namesRoute: widget.modal,
            label: widget.semanticLabel,
            child: widget.child,
          );

    if (widget.modal && !widget.excludeSemantics) {
      dialog = BlockSemantics(child: dialog);
    }

    return dialog;
  }
}
