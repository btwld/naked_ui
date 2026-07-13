import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/link.dart' as launcher;

import 'mixins/naked_mixins.dart';
import 'utilities/intents.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// An immutable snapshot of a [NakedLink]'s interaction state and destination.
class NakedLinkState extends NakedState {
  /// Creates a snapshot with the current interaction [states] and [linkUrl].
  NakedLinkState({required super.states, required this.linkUrl});

  /// The Link's destination, or null when it is unavailable.
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
/// Primary pointer tap, Enter, Numpad Enter, and semantic tap follow [linkUrl]
/// while the Link is effectively enabled. When [onPressed] is supplied, it
/// replaces the default navigation path. Space is not bound by this widget, so
/// a surrounding page retains its normal scrolling behavior. Secondary click
/// is likewise left available for consumer-owned context menus.
///
/// Naked UI delegates default navigation and the native web anchor to
/// `url_launcher`'s Link coordinator. The [builder] owns all visual styling. A
/// supplied [focusNode] remains caller-owned and is never disposed by Naked UI.
///
/// ```dart
/// NakedLink(
///   linkUrl: Uri.parse('https://example.com/docs'),
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

  /// Overrides default navigation when the Link activates.
  ///
  /// When null, activation follows [linkUrl] through the platform Link
  /// coordinator. When non-null, only this callback runs; native navigation is
  /// suppressed.
  final VoidCallback? onPressed;

  /// The destination exposed to assistive technologies and the web DOM.
  ///
  /// A null destination makes the Link effectively disabled, even if
  /// [onPressed] is supplied.
  final Uri? linkUrl;

  /// Whether the Link may activate when [linkUrl] is also non-null.
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

  bool get _effectiveEnabled => enabled && linkUrl != null;

  @override
  State<NakedLink> createState() => _NakedLinkState();
}

class _NakedLinkState extends State<NakedLink>
    with WidgetStatesMixin<NakedLink> {
  // url_launcher's web delegate always contributes Link semantics, including
  // for a null URI. Keep its wrapper out of the unavailable tree and use this
  // key to preserve the consumer subtree as the wrapper is added or removed.
  final _contentKey = GlobalKey(debugLabel: 'NakedLink content');

  void _handleActivation(launcher.FollowLink? followLink) {
    if (!widget._effectiveEnabled) return;

    if (widget.enableFeedback) {
      Feedback.forTap(context);
    }
    final override = widget.onPressed;
    if (override != null) {
      override();
    } else {
      assert(followLink != null);
      unawaited(followLink!());
    }
  }

  void _handlePressStart(TapDownDetails details) {
    updatePressState(true, widget.onPressChange);
  }

  void _handlePressEnd() {
    updatePressState(false, widget.onPressChange);
  }

  void _clearInteractionStates() {
    final endedPress = updateState(WidgetState.pressed, false, rebuild: false);
    final endedHover = updateState(WidgetState.hovered, false, rebuild: false);
    final endedFocus = updateState(WidgetState.focused, false, rebuild: false);
    if (!endedPress && !endedHover && !endedFocus) return;

    final onPressChange = widget.onPressChange;
    final onHoverChange = widget.onHoverChange;
    final onFocusChange = widget.onFocusChange;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (endedPress) onPressChange?.call(false);
      if (endedHover) onHoverChange?.call(false);
      if (endedFocus) onFocusChange?.call(false);
    });
  }

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget._effectiveEnabled);
  }

  @override
  void didUpdateWidget(covariant NakedLink oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasEnabled = oldWidget.enabled && oldWidget.linkUrl != null;
    if (wasEnabled == widget._effectiveEnabled) return;

    updateDisabledState(!widget._effectiveEnabled, rebuild: false);
    if (!widget._effectiveEnabled) _clearInteractionStates();
  }

  Widget _buildLink(launcher.FollowLink? followLink) {
    final isEnabled = widget._effectiveEnabled;
    final activation = isEnabled ? () => _handleActivation(followLink) : null;
    Widget result = GestureDetector(
      onTapDown: isEnabled ? _handlePressStart : null,
      onTapUp: isEnabled ? (_) => _handlePressEnd() : null,
      onTapCancel: isEnabled ? _handlePressEnd : null,
      onTap: activation,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: NakedStateScopeBuilder(
        value: NakedLinkState(
          states: widgetStates,
          linkUrl: isEnabled ? widget.linkUrl : null,
        ),
        child: widget.child,
        builder: widget.builder,
      ),
    );

    if (!widget.excludeSemantics) {
      result = Semantics(
        enabled: isEnabled,
        link: isEnabled,
        linkUrl: isEnabled ? widget.linkUrl : null,
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        excludeSemantics: widget.semanticLabel != null,
        onTap: activation,
        child: result,
      );
    }

    result = NakedFocusableDetector(
      key: _contentKey,
      enabled: isEnabled,
      autofocus: widget.autofocus,
      canRequestFocus: isEnabled,
      includeSemantics: !widget.excludeSemantics,
      restoreHoverOnEnable: true,
      onFocusChange: (focused) {
        updateFocusState(focused, widget.onFocusChange);
      },
      onHoverChange: (hovered) {
        updateHoverState(hovered, widget.onHoverChange);
      },
      focusNode: widget.focusNode,
      mouseCursor: isEnabled
          ? (widget.mouseCursor ?? SystemMouseCursors.click)
          : SystemMouseCursors.basic,
      shortcuts: NakedIntentActions.link.shortcuts,
      actions: NakedIntentActions.link.actions(
        onPressed: () => _handleActivation(followLink),
      ),
      debugLabel: 'NakedLink',
      child: result,
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final Widget result;
    if (widget._effectiveEnabled) {
      result = launcher.Link(
        uri: widget.linkUrl,
        builder: (context, followLink) => _buildLink(followLink),
      );
    } else {
      result = _buildLink(null);
    }

    return widget.excludeSemantics ? ExcludeSemantics(child: result) : result;
  }
}
