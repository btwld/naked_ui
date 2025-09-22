import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'state.dart';

/// Internal inherited widget that provides state and controller.
class _NakedStateScopeInherited<T extends NakedState> extends InheritedWidget {
  const _NakedStateScopeInherited({
    required this.value,
    required this.controller,
    required super.child,
  });

  final T value;
  final WidgetStatesController controller;

  @override
  bool updateShouldNotify(_NakedStateScopeInherited<T> oldWidget) {
    // Only notify when the value changes, not the controller
    // Controller changes are handled through ValueListenableBuilder
    return value != oldWidget.value;
  }
}

/// Provides a [NakedState] instance to descendant widgets.
///
/// This widget allows widgets to share a typed state throughout
/// the widget tree with compile-time type safety. It also manages
/// a [WidgetStatesController] based on the state's widget states.
///
/// ```dart
/// NakedStateScope<NakedMenuState>(
///   value: NakedMenuState(states: {...}, isOpen: true),
///   child: MyApp(),
/// )
/// ```
///
/// Access the state and controller anywhere in the subtree:
/// ```dart
/// final menuState = NakedState.of<NakedMenuState>(context);
/// final controller = NakedState.controllerOf(context);
/// ```
///
/// ## Multiple States
///
/// For multiple state types, nest providers:
///
/// ```dart
/// NakedStateScope<AppThemeState>(
///   value: AppThemeState(isDark: true),
///   child: NakedStateScope<NakedMenuState>(
///     value: NakedMenuState(states: {...}, isOpen: false),
///     child: MyWidget(), // Can access both AppThemeState and NakedMenuState
///   ),
/// )
/// ```
///
/// See also:
/// - [NakedState], the base class for all provided states
/// - [InheritedWidget], Flutter's foundation for widget state sharing
class NakedStateScope<T extends NakedState> extends StatefulWidget {
  /// Creates a scope with the given [value].
  const NakedStateScope({super.key, required this.value, required this.child});

  /// Gets the state value from the nearest [NakedStateScope].
  static T? maybeOf<T extends NakedState>(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_NakedStateScopeInherited<T>>();

    return inherited?.value;
  }

  /// Gets the [WidgetStatesController] from the nearest [NakedStateScope].
  ///
  /// This method does not create a dependency, so the calling widget won't
  /// rebuild when the controller's value changes.
  ///
  /// Throws if no [NakedStateScope] is found.
  static WidgetStatesController controllerOf(BuildContext context) {
    _NakedStateScopeInherited? inherited;
    context.visitAncestorElements((element) {
      if (element.widget is _NakedStateScopeInherited) {
        inherited = element.widget as _NakedStateScopeInherited;

        return false; // Stop walking
      }

      return true; // Continue walking
    });

    if (inherited == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'NakedStateScope.controllerOf() called with a context that does not contain a NakedStateScope.',
        ),
        ErrorDescription('No NakedStateScope was found above this widget.'),
        ErrorHint(
          'Ensure that a NakedStateScope is above this widget in the tree.\n'
          'Example:\n'
          '  NakedStateScope<YourStateType>(\n'
          '    value: YourStateType(...),\n'
          '    child: YourWidget(),\n'
          '  )',
        ),
        context.describeElement('The context used was'),
      ]);
    }

    return inherited!.controller;
  }

  /// Gets the [WidgetStatesController] from the nearest [NakedStateScope].
  ///
  /// Returns null if no scope is found.
  ///
  /// This method does not create a dependency.
  static WidgetStatesController? maybeControllerOf(BuildContext context) {
    _NakedStateScopeInherited? inherited;
    context.visitAncestorElements((element) {
      if (element.widget is _NakedStateScopeInherited) {
        inherited = element.widget as _NakedStateScopeInherited;

        return false; // Stop walking
      }

      return true; // Continue walking
    });

    return inherited?.controller;
  }

  /// The state value to provide to descendant widgets.
  final T value;

  /// The widget subtree that can access the state.
  final Widget child;

  @override
  State<NakedStateScope<T>> createState() => _NakedStateScopeState<T>();
}

class _NakedStateScopeState<T extends NakedState>
    extends State<NakedStateScope<T>> {
  late final WidgetStatesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WidgetStatesController();
    _controller.value = widget.value.states;
  }

  @override
  void didUpdateWidget(NakedStateScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller value if states changed
    if (!setEquals(widget.value.states, oldWidget.value.states)) {
      _controller.value = widget.value.states;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NakedStateScopeInherited<T>(
      value: widget.value,
      controller: _controller,
      child: widget.child,
    );
  }
}
