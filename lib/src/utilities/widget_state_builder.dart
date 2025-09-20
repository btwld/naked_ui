import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Observes changes to a [WidgetStatesController].
///
/// Fires callbacks when individual [WidgetState]s toggle.
class _WidgetStateObserver {
  /// Called when a state toggles.
  final void Function(WidgetState state, bool isActive)? onStateChange;

  /// Per-state callbacks. These take precedence over [onStateChange].
  final Map<WidgetState, ValueChanged<bool>> _callbacks;

  // ignore: dispose-class-fields
  WidgetStatesController? _controller;

  Set<WidgetState>? _prev;
  VoidCallback? _subscription;
  _WidgetStateObserver({
    this.onStateChange,
    Map<WidgetState, ValueChanged<bool>>? callbacks,
  }) : _callbacks = callbacks ?? const {};

  void _diffAndNotify(Set<WidgetState> prev, Set<WidgetState> next) {
    // Removed states became inactive; added states became active.
    for (final state in prev.difference(next)) {
      final callback = _callbacks[state];
      if (callback != null) {
        callback(false);
      } else {
        onStateChange?.call(state, false);
      }
    }
    for (final state in next.difference(prev)) {
      final callback = _callbacks[state];
      if (callback != null) {
        callback(true);
      } else {
        onStateChange?.call(state, true);
      }
    }
  }

  void attach(WidgetStatesController controller) {
    if (identical(_controller, controller)) return; // Already attached.
    detach();
    _controller = controller;
    _prev = Set<WidgetState>.of(controller.value);
    _subscription = () {
      final next = controller.value;
      _diffAndNotify(_prev!, next);
      _prev = Set<WidgetState>.of(next);
    };
    controller.addListener(_subscription!);
  }

  void detach() {
    final c = _controller;
    final s = _subscription;
    if (c != null && s != null) c.removeListener(s);
    _controller = null;
    _subscription = null;
    _prev = null;
  }

  void dispose() => detach();
}

/// Builder signature for the host/scope widgets.
typedef WidgetStatesBuilder =
    Widget Function(
      BuildContext context,
      WidgetStatesController controller,
      Widget? child,
    );

/// Hosts a [WidgetStatesController] and rebuilds when its value changes.
///
/// - Creates an internal controller when [controller] is null.
/// - Rebuilds using [ValueListenableBuilder].
/// - Attaches/detaches an internal observer when callbacks are provided.
/// - Safely swaps between internal and external controllers.
class _WidgetStatesHost extends StatefulWidget {
  const _WidgetStatesHost({
    this.controller,
    this.onStateChange,
    this.callbacks,
    required this.builder,
    this.child,
  });

  /// External controller. If null, an internal controller is created.
  final WidgetStatesController? controller;

  /// Called when a state toggles.
  final void Function(WidgetState, bool)? onStateChange;

  /// Per-state callbacks. These take precedence over [onStateChange].
  final Map<WidgetState, ValueChanged<bool>>? callbacks;

  /// Builds descendants with the effective controller.
  final WidgetStatesBuilder builder;
  final Widget? child;

  @override
  State<_WidgetStatesHost> createState() => _WidgetStatesHostState();
}

class _WidgetStatesHostState extends State<_WidgetStatesHost> {
  WidgetStatesController? _internal; // Lazily created.
  // ignore: dispose-fields
  _WidgetStateObserver? _obs; // Created only when callbacks are provided.

  WidgetStatesController get _controller =>
      widget.controller ?? (_internal ??= WidgetStatesController());

  bool get _hasObserver =>
      widget.onStateChange != null || (widget.callbacks?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    if (_hasObserver) {
      _obs = _WidgetStateObserver(
        onStateChange: widget.onStateChange,
        callbacks: widget.callbacks,
      )..attach(_controller);
    }
  }

  @override
  void didUpdateWidget(covariant _WidgetStatesHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldController = oldWidget.controller ?? _internal;
    final newController = widget.controller ?? _internal ?? _controller;
    final effectiveChanged = !identical(oldController, newController);

    final configChanged =
        !identical(widget.onStateChange, oldWidget.onStateChange) ||
        !mapEquals(
          widget.callbacks ?? const {},
          oldWidget.callbacks ?? const {},
        );

    if (configChanged) {
      _obs?.detach();
      _obs = _hasObserver
          ? _WidgetStateObserver(
              onStateChange: widget.onStateChange,
              callbacks: widget.callbacks,
            )
          : null;
      _obs?.attach(_controller);
    } else if (effectiveChanged) {
      _obs?.attach(_controller);
    }

    if (oldWidget.controller == null && widget.controller != null) {
      // Switched to external: dispose internal.
      _internal?.dispose();
      _internal = null;
    }
  }

  @override
  void dispose() {
    _obs?.detach();
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller; // Stable local reference.

    // Rebuild when the controller's value changes. Do not expose the
    // Set<WidgetState> to the builder; the controller is the source of truth.
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: controller,
      child: widget.child,
      builder: (context, _, __) =>
          widget.builder(context, controller, widget.child),
    );
  }
}

/// Rebuilds when a specific [WidgetState] toggles.
///
/// Uses [ValueListenableBuilder] with a [WidgetStatesController].
class WidgetStateSelector extends StatelessWidget {
  const WidgetStateSelector({
    super.key,
    required this.controller,
    required this.state,
    required this.builder,
    this.child,
  });

  final WidgetStatesController controller;
  final WidgetState state;
  final Widget Function(BuildContext, bool, Widget?) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: controller,
      child: child,
      builder: (context, states, child) =>
          builder(context, states.contains(state), child),
    );
  }
}

/// Convenience getters for common states.
extension WidgetStatesX on WidgetStatesController {
  bool get isHovered => value.contains(WidgetState.hovered);
  bool get isFocused => value.contains(WidgetState.focused);
  bool get isPressed => value.contains(WidgetState.pressed);
  bool get isDisabled => value.contains(WidgetState.disabled);
  bool get isSelected => value.contains(WidgetState.selected);
  bool get isError => value.contains(WidgetState.error);
  bool get isDragged => value.contains(WidgetState.dragged);
  bool get isScrolledUnder => value.contains(WidgetState.scrolledUnder);
}

/// Exposes a [WidgetStatesController] to descendants and supports aspect-based
/// subscriptions via [InheritedModel].
///
/// This widget does not add listeners; updates are driven by the host above it.
class WidgetStatesModel extends InheritedModel<WidgetState> {
  const WidgetStatesModel({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Returns the full state set and subscribes to all changes.
  static Set<WidgetState> of(BuildContext context) {
    final model = InheritedModel.inheritFrom<WidgetStatesModel>(context);
    assert(model != null, 'No WidgetStatesModel found in context');

    return model!.controller.value;
  }

  /// Returns whether [aspect] is active and subscribes only to that aspect.
  static bool ofState(BuildContext context, WidgetState aspect) {
    final model = InheritedModel.inheritFrom<WidgetStatesModel>(
      context,
      aspect: aspect,
    );
    assert(model != null, 'No WidgetStatesModel found in context');

    return model!.controller.value.contains(aspect);
  }

  /// Returns the controller without subscribing to updates.
  static WidgetStatesController controllerOf(BuildContext context) {
    final model = context.getInheritedWidgetOfExactType<WidgetStatesModel>();
    assert(model != null, 'No WidgetStatesModel found in context');

    return model!.controller;
  }

  /// Nullable variants (return null when absent).
  static Set<WidgetState>? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<WidgetStatesModel>(context)?.controller.value;

  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WidgetStatesModel>()?.controller;

  // Typed helpers.
  static bool hoveredOf(BuildContext c) => ofState(c, WidgetState.hovered);

  static bool focusedOf(BuildContext c) => ofState(c, WidgetState.focused);
  static bool pressedOf(BuildContext c) => ofState(c, WidgetState.pressed);
  static bool disabledOf(BuildContext c) => ofState(c, WidgetState.disabled);
  static bool selectedOf(BuildContext c) => ofState(c, WidgetState.selected);
  static bool errorOf(BuildContext c) => ofState(c, WidgetState.error);
  static bool draggedOf(BuildContext c) => ofState(c, WidgetState.dragged);
  static bool scrolledUnderOf(BuildContext c) =>
      ofState(c, WidgetState.scrolledUnder);
  final WidgetStatesController controller;

  @override
  bool updateShouldNotify(covariant WidgetStatesModel oldWidget) {
    // Notify full-model dependents when anything changes.
    return !setEquals(controller.value, oldWidget.controller.value);
  }

  @override
  bool updateShouldNotifyDependent(
    covariant WidgetStatesModel oldWidget,
    Set<WidgetState> dependencies,
  ) {
    final oldStates = oldWidget.controller.value;
    final newStates = controller.value;
    for (final aspect in dependencies) {
      if (oldStates.contains(aspect) != newStates.contains(aspect)) {
        return true;
      }
    }

    return false;
  }
}

/// Composes the host with [WidgetStatesModel] for lifecycle and tree access.
class WidgetStatesScope extends StatelessWidget {
  const WidgetStatesScope({
    super.key,
    this.controller,
    this.onStateChange,
    this.callbacks,
    required this.builder,
    this.child,
  });

  final WidgetStatesController? controller;
  final void Function(WidgetState, bool)? onStateChange;
  final Map<WidgetState, ValueChanged<bool>>? callbacks;
  final WidgetStatesBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _WidgetStatesHost(
      controller: controller,
      onStateChange: onStateChange,
      callbacks: callbacks,
      child: child,
      builder: (context, ctrl, child) {
        return WidgetStatesModel(
          controller: ctrl,
          child: builder(context, ctrl, child),
        );
      },
    );
  }
}
