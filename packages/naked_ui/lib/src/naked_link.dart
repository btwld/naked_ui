import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// An immutable snapshot of a [NakedLink]'s interaction state and URL metadata.
class NakedLinkState extends NakedState {
  /// Creates a snapshot with the current interaction [states] and [linkUrl].
  NakedLinkState({required super.states, required this.linkUrl});

  /// The URL exposed to assistive technologies, if one was supplied.
  ///
  /// This value is metadata only. Naked UI does not launch it or update browser
  /// history.
  final Uri? linkUrl;

  /// Returns the nearest [NakedLinkState] provided by [NakedStateScope].
  static NakedLinkState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedLinkState], if one is available.
  static NakedLinkState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest state scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf<NakedLinkState>(context);

  /// Returns the nearest state scope's controller, if one is available.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf<NakedLinkState>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedLinkState &&
        statesEqual(other) &&
        other.linkUrl == linkUrl;
  }

  @override
  int get hashCode => Object.hash(statesHashCode, linkUrl);
}

/// A headless navigation Link with observable interaction state.
///
/// Primary pointer tap, Enter, Numpad Enter, and semantic tap invoke
/// [onPressed] once while the Link is effectively enabled. Space is not bound
/// by this widget, so a surrounding page retains its normal scrolling
/// behavior. Secondary click is likewise left available for consumer-owned
/// context menus.
///
/// [linkUrl] is accessibility metadata and does not perform navigation. The
/// application owns routing or URL launching, while [builder] owns all visual
/// styling. A supplied [focusNode] remains caller-owned and is never disposed
/// by Naked UI.
///
/// ```dart
/// NakedLink(
///   linkUrl: Uri.parse('https://example.com/docs'),
///   onPressed: openDocumentation,
///   child: const Text('Documentation'),
///   builder: (context, state, child) => DecoratedBox(
///     decoration: BoxDecoration(
///       border: Border.all(
///         color: state.isFocused
///             ? const Color(0xFF2563EB)
///             : const Color(0x00000000),
///       ),
///     ),
///     child: child!,
///   ),
/// )
/// ```
class NakedLink extends StatefulWidget {
  /// Creates a Link with either [child] or [builder] as its visual surface.
  const NakedLink({
    super.key,
    this.child,
    this.builder,
    this.onPressed,
    this.linkUrl,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.enableFeedback = true,
    this.onFocusChange,
    this.onHoverChange,
    this.onPressChange,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  /// The visual Link content.
  final Widget? child;

  /// Builds the Link using the current immutable state.
  final ValueWidgetBuilder<NakedLinkState>? builder;

  /// Performs application-owned navigation when the Link activates.
  ///
  /// A null callback makes the Link effectively disabled even when [enabled]
  /// is true.
  final VoidCallback? onPressed;

  /// The optional URL exposed to assistive technologies and the web DOM.
  ///
  /// Supplying a URL does not launch it; [onPressed] remains responsible for
  /// application navigation.
  final Uri? linkUrl;

  /// Whether the Link may activate when [onPressed] is also non-null.
  final bool enabled;

  /// The optional caller-owned focus node.
  ///
  /// Naked UI borrows this node and never disposes it.
  final FocusNode? focusNode;

  /// Whether the Link should request focus when first built.
  final bool autofocus;

  /// The cursor used while effectively enabled.
  ///
  /// Defaults to [SystemMouseCursors.click]. Disabled Links always use
  /// [SystemMouseCursors.basic].
  final MouseCursor? mouseCursor;

  /// Whether accepted activations provide platform feedback.
  final bool enableFeedback;

  /// Called when keyboard focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Called when pointer hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when primary-pointer press state changes.
  final ValueChanged<bool>? onPressChange;

  /// The optional caller-localized accessible name.
  ///
  /// When non-null, this replaces descendant naming semantics so the Link is
  /// announced once. Otherwise visible child text supplies the name.
  final String? semanticLabel;

  /// Optional caller-localized accessible hint.
  final String? semanticHint;

  /// Whether to hide the Link and its subtree from semantics.
  ///
  /// This is an advanced escape hatch. Callers remain responsible for
  /// providing an equivalent accessible navigation path.
  final bool excludeSemantics;

  bool get _effectiveEnabled => enabled && onPressed != null;

  @override
  State<NakedLink> createState() => _NakedLinkState();
}

class _NakedLinkState extends State<NakedLink>
    with WidgetStatesMixin<NakedLink> {
  void _handleActivation() {
    if (!widget._effectiveEnabled) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }
    widget.onPressed!();
  }

  void _handlePressStart(TapDownDetails details) {
    updatePressState(true, widget.onPressChange);
  }

  void _handlePressEnd() {
    updatePressState(false, widget.onPressChange);
  }

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
  }

  @override
  void didUpdateWidget(covariant NakedLink oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasEnabled = oldWidget.enabled && oldWidget.onPressed != null;
    if (wasEnabled != widget._effectiveEnabled) {
      updateDisabledState(!widget._effectiveEnabled);
      if (!widget._effectiveEnabled) {
        _handlePressEnd();
        updateHoverState(false, widget.onHoverChange);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = GestureDetector(
      onTapDown: widget._effectiveEnabled ? _handlePressStart : null,
      onTapUp: widget._effectiveEnabled ? (_) => _handlePressEnd() : null,
      onTapCancel: widget._effectiveEnabled ? _handlePressEnd : null,
      onTap: widget._effectiveEnabled ? _handleActivation : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: NakedStateScopeBuilder(
        value: NakedLinkState(states: widgetStates, linkUrl: widget.linkUrl),
        child: widget.child,
        builder: widget.builder,
      ),
    );

    if (!widget.excludeSemantics) {
      result = Semantics(
        enabled: widget._effectiveEnabled,
        link: true,
        linkUrl: widget.linkUrl,
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        excludeSemantics: widget.semanticLabel != null,
        onTap: widget._effectiveEnabled ? _handleActivation : null,
        child: result,
      );
    }

    result = NakedFocusableDetector(
      enabled: widget._effectiveEnabled,
      autofocus: widget.autofocus,
      includeSemantics: !widget.excludeSemantics,
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      onHoverChange: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      focusNode: widget.focusNode,
      mouseCursor: widget._effectiveEnabled
          ? (widget.mouseCursor ?? SystemMouseCursors.click)
          : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.link.shortcuts,
      actions: NakedIntentActions.link.actions(onPressed: _handleActivation),
      debugLabel: 'NakedLink',
      child: result,
    );

    return widget.excludeSemantics ? ExcludeSemantics(child: result) : result;
  }
}
