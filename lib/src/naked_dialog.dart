import 'package:flutter/material.dart';

/// Provides dialog functionality without default styling.
///
/// Unlike [showDialog], gives complete control over appearance through [builder].
/// Has no default background, border radius, or padding.
///
/// Returns [Future] that resolves to [Navigator.pop] value or null if dismissed.
/// The [barrierColor] must be specified for overlay background.
///
/// Example:
/// ```dart
/// final result = await showNakedDialog<String>(
///   context: context,
///   barrierColor: Colors.black54,
///   builder: (context) => NakedDialog(
///     modal: true,
///     semanticLabel: 'Confirmation Dialog',
///     child: Container(
///       margin: EdgeInsets.all(40),
///       decoration: BoxDecoration(
///         color: Colors.white,
///         borderRadius: BorderRadius.circular(8),
///       ),
///       child: Text('Custom Dialog'),
///     ),
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
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => themes.wrap(builder(context)),
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

/// Provides dialog semantics for modal dialog content.
///
/// Wraps dialog content with proper semantic properties for accessibility.
/// Use inside showNakedDialog builder for correct modal behavior.
class NakedDialog extends StatelessWidget {
  /// Creates a naked dialog widget.
  const NakedDialog({
    super.key,
    required this.child,
    this.modal = true,
    this.addSemantics = true,
    this.semanticLabel,
  });

  /// Child widget to display.
  final Widget child;

  /// Whether this is a modal dialog that blocks background interaction.
  final bool modal;

  /// Whether to add semantics to this dialog.
  final bool addSemantics;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (!addSemantics) return child;

    Widget dialog = Semantics(
      scopesRoute: modal,
      namesRoute: modal,
      label: semanticLabel,
      child: child,
    );

    // Block background interaction for modal dialogs
    if (modal) {
      dialog = BlockSemantics(child: dialog);
    }

    return dialog;
  }
}
