import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

/// Displays a headless dialog without default styling.
///
/// Unlike `showDialog`, imposes no visuals—appearance is fully controlled by
/// [builder]. The [barrierColor] is required and controls both visual scrim
/// and barrier hit testing.
///
/// A dismissible barrier must have a localized [barrierLabel].
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
/// - `showDialog`, the Material-styled dialog for typical apps.
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
  if (barrierDismissible && barrierLabel == null) {
    throw ArgumentError.notNull('barrierLabel');
  }
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
            // Build below the captured themes so lookups inside `builder` use
            // the same inherited theme values as the call site.
            return themes.wrap(Builder(builder: builder));
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
/// When [modal] is true, blocks background semantics and configures screen
/// reader route semantics. Pointer blocking is provided by the route barrier
/// created by [showNakedDialog].
///
/// See also:
/// - [showNakedDialog], the function that displays dialogs.
class NakedDialog extends StatelessWidget {
  /// Creates a semantic wrapper around [child].
  const NakedDialog({
    super.key,
    required this.child,
    this.modal = true,
    this.semanticLabel,
    this.semanticsRole = SemanticsRole.dialog,
    this.excludeSemantics = false,
  });

  /// The dialog content.
  final Widget child;

  /// Whether to scope the semantic route and block background semantics.
  final bool modal;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// The accessibility role represented by this dialog.
  ///
  /// Use [SemanticsRole.alertDialog] for a message that requires an immediate
  /// response. Defaults to [SemanticsRole.dialog].
  final SemanticsRole semanticsRole;

  /// Whether to omit the semantics contributed by [NakedDialog].
  ///
  /// Semantics supplied by [child] remain in the tree, allowing callers to
  /// provide a complete custom dialog contract.
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    Widget dialog = excludeSemantics
        ? child
        : Semantics(
            container: true,
            explicitChildNodes: true,
            scopesRoute: modal,
            namesRoute: modal && semanticLabel != null,
            role: semanticsRole,
            label: semanticLabel,
            child: child,
          );

    if (modal) {
      dialog = BlockSemantics(child: dialog);
    }

    return dialog;
  }
}
