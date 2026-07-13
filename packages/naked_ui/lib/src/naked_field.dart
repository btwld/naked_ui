import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

/// Controls whether changed field errors create an accessibility announcement.
enum NakedFieldErrorAnnouncement {
  /// Never create an announcement node for an error transition.
  none,

  /// Announce each changed non-empty error after the initial build.
  whenChanged,
}

/// Immutable view passed to [NakedField.builder].
@immutable
class NakedFieldState extends NakedState {
  /// Creates an immutable field-state snapshot.
  NakedFieldState({
    required super.states,
    required this.label,
    required this.description,
    required this.errorText,
    required this.isRequired,
    required this.isReadOnly,
    required this.isFilled,
    required this.validationResult,
  });

  /// The accessible label owned by the field.
  final String label;

  /// Optional descriptive text owned by the field.
  final String? description;

  /// The current normalized error, if any.
  final String? errorText;

  /// Whether the field is required.
  final bool isRequired;

  /// Whether the primary control is effectively read-only.
  final bool isReadOnly;

  /// Whether the primary control currently contains a value.
  final bool isFilled;

  /// The controlled semantic validation result.
  final SemanticsValidationResult validationResult;

  /// Returns the nearest [NakedFieldState].
  static NakedFieldState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedFieldState], if one exists.
  static NakedFieldState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the state controller from the nearest field scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf<NakedFieldState>(context);

  /// Returns the state controller from the nearest field scope, if one exists.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf<NakedFieldState>(context);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedFieldState &&
        statesEqual(other) &&
        other.label == label &&
        other.description == description &&
        other.errorText == errorText &&
        other.isRequired == isRequired &&
        other.isReadOnly == isReadOnly &&
        other.isFilled == isFilled &&
        other.validationResult == validationResult;
  }

  @override
  int get hashCode => Object.hash(
    statesHashCode,
    label,
    description,
    errorText,
    isRequired,
    isReadOnly,
    isFilled,
    validationResult,
  );
}

/// A headless semantic scope for one primary form control.
class NakedField extends StatefulWidget {
  /// Creates a controlled field scope.
  const NakedField({
    super.key,
    required this.label,
    this.description,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.validationResult = SemanticsValidationResult.none,
    this.errorAnnouncement = NakedFieldErrorAnnouncement.whenChanged,
    this.child,
    this.builder,
    this.excludeSemantics = false,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       ),
       assert(
         errorText == null ||
             errorText == '' ||
             validationResult != SemanticsValidationResult.valid,
         'A visible field error cannot have a valid validation result.',
       );

  /// The canonical accessible label for the primary control.
  final String label;

  /// Optional descriptive text for the primary control.
  final String? description;

  /// Optional current validation error.
  ///
  /// Null and the empty string are treated as absent. Other strings are kept
  /// verbatim so localized content is not rewritten.
  final String? errorText;

  /// Whether the primary control is required.
  final bool isRequired;

  /// Whether the field permits interaction.
  final bool enabled;

  /// Whether the primary control is read-only.
  final bool readOnly;

  /// The controlled semantic validation result.
  final SemanticsValidationResult validationResult;

  /// How changed non-empty errors are announced.
  final NakedFieldErrorAnnouncement errorAnnouncement;

  /// The optional field subtree.
  final Widget? child;

  /// Builds the field subtree from the current state.
  final ValueWidgetBuilder<NakedFieldState>? builder;

  /// Whether to exclude the complete field subtree from semantics.
  final bool excludeSemantics;

  @override
  State<NakedField> createState() => _NakedFieldState();
}

class _NakedFieldState extends State<NakedField> {
  late final NakedFieldScopeController _scopeController =
      NakedFieldScopeController._(this);
  final Map<Object, NakedFieldControlRegistration> _registrations = {};
  bool _stateSyncScheduled = false;
  bool _multipleControlCheckScheduled = false;

  String? get _normalizedError {
    final errorText = widget.errorText;
    return errorText == null || errorText.isEmpty ? null : errorText;
  }

  NakedFieldControlRegistration? get _primaryControl {
    if (_registrations.isEmpty) return null;
    final registration = _registrations.values.first;
    return registration.isMounted() ? registration : null;
  }

  void _registerControl(
    Object token,
    NakedFieldControlRegistration registration,
  ) {
    _registrations[token] = registration;
    _scheduleStateSync();
    _scheduleMultipleControlCheck();
  }

  void _unregisterControl(Object token) {
    if (_registrations.remove(token) != null) {
      _scheduleStateSync();
    }
  }

  void _controlChanged(Object token) {
    if (_registrations.containsKey(token)) {
      _scheduleStateSync();
    }
  }

  void _requestPrimaryFocus() {
    if (!widget.enabled) return;
    final registration = _primaryControl;
    if (registration == null ||
        !registration.isEnabled() ||
        !registration.canRequestFocus()) {
      return;
    }
    registration.requestFocus();
  }

  void _scheduleStateSync() {
    if (_stateSyncScheduled || !mounted) return;
    _stateSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stateSyncScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _scheduleMultipleControlCheck() {
    if (_multipleControlCheckScheduled || _registrations.length < 2) return;
    _multipleControlCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _multipleControlCheckScheduled = false;
      assert(
        !mounted || _registrations.length <= 1,
        'NakedField supports exactly one mounted primary control.',
      );
    });
  }

  @override
  void dispose() {
    _scopeController._detach();
    _registrations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryControl = _primaryControl;
    final effectiveEnabled =
        widget.enabled && (primaryControl?.isEnabled() ?? true);
    final effectiveReadOnly =
        widget.readOnly || (primaryControl?.isReadOnly() ?? false);
    final states = <WidgetState>{
      if (!effectiveEnabled) WidgetState.disabled,
      if (_normalizedError != null) WidgetState.error,
      if (primaryControl?.isFocused() ?? false) WidgetState.focused,
    };
    final fieldState = NakedFieldState(
      states: states,
      label: widget.label,
      description: widget.description,
      errorText: _normalizedError,
      isRequired: widget.isRequired,
      isReadOnly: effectiveReadOnly,
      isFilled: primaryControl?.isFilled() ?? false,
      validationResult: widget.validationResult,
    );

    Widget result = NakedStateScopeBuilder(
      value: fieldState,
      child: widget.child,
      builder: widget.builder,
    );
    result = NakedFieldScope(
      controller: _scopeController,
      label: widget.label,
      description: widget.description,
      errorText: _normalizedError,
      isRequired: widget.isRequired,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      validationResult: widget.validationResult,
      errorAnnouncement: widget.errorAnnouncement,
      child: result,
    );

    return widget.excludeSemantics ? ExcludeSemantics(child: result) : result;
  }
}

/// Makes a visible field label focus the registered primary control.
class NakedFieldLabel extends StatelessWidget {
  /// Creates a field label around [child].
  const NakedFieldLabel({super.key, required this.child});

  /// The visible label content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = NakedFieldScope.maybeOf(context);
    assert(scope != null, 'NakedFieldLabel must be inside a NakedField.');
    if (scope == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: scope.controller.requestPrimaryFocus,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Excludes visible field-description text after it is associated to a control.
class NakedFieldDescription extends StatelessWidget {
  /// Creates a visual field description.
  const NakedFieldDescription({super.key, required this.child});

  /// The visible description content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = NakedFieldScope.maybeOf(context);
    assert(scope != null, 'NakedFieldDescription must be inside a NakedField.');
    if (scope == null) return child;
    return ExcludeSemantics(child: child);
  }
}

/// Excludes visible error text from duplicating the control's associated error.
class NakedFieldError extends StatelessWidget {
  /// Creates a visual field error.
  const NakedFieldError({super.key, required this.child});

  /// The visible error content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = NakedFieldScope.maybeOf(context);
    assert(scope != null, 'NakedFieldError must be inside a NakedField.');
    if (scope == null) return child;
    return ExcludeSemantics(child: child);
  }
}

/// Internal registration supplied by a TextField-first primary control.
@internal
class NakedFieldControlRegistration {
  /// Creates callbacks that report the current control state without taking
  /// ownership of the control's focus node or controller.
  const NakedFieldControlRegistration({
    required this.isMounted,
    required this.isEnabled,
    required this.isReadOnly,
    required this.canRequestFocus,
    required this.isFocused,
    required this.isFilled,
    required this.requestFocus,
  });

  final bool Function() isMounted;
  final bool Function() isEnabled;
  final bool Function() isReadOnly;
  final bool Function() canRequestFocus;
  final bool Function() isFocused;
  final bool Function() isFilled;
  final VoidCallback requestFocus;
}

/// Internal controller shared by a field and its TextField integration.
@internal
class NakedFieldScopeController {
  NakedFieldScopeController._(this._owner);

  _NakedFieldState? _owner;

  void registerControl(
    Object token,
    NakedFieldControlRegistration registration,
  ) => _owner?._registerControl(token, registration);

  void unregisterControl(Object token) => _owner?._unregisterControl(token);

  void controlChanged(Object token) => _owner?._controlChanged(token);

  void requestPrimaryFocus() => _owner?._requestPrimaryFocus();

  void _detach() => _owner = null;
}

/// Internal inherited metadata consumed by [NakedTextField].
@internal
class NakedFieldScope extends InheritedWidget {
  const NakedFieldScope({
    super.key,
    required this.controller,
    required this.label,
    required this.description,
    required this.errorText,
    required this.isRequired,
    required this.enabled,
    required this.readOnly,
    required this.validationResult,
    required this.errorAnnouncement,
    required super.child,
  });

  static NakedFieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NakedFieldScope>();

  final NakedFieldScopeController controller;
  final String label;
  final String? description;
  final String? errorText;
  final bool isRequired;
  final bool enabled;
  final bool readOnly;
  final SemanticsValidationResult validationResult;
  final NakedFieldErrorAnnouncement errorAnnouncement;

  @override
  bool updateShouldNotify(NakedFieldScope oldWidget) {
    return !identical(controller, oldWidget.controller) ||
        label != oldWidget.label ||
        description != oldWidget.description ||
        errorText != oldWidget.errorText ||
        isRequired != oldWidget.isRequired ||
        enabled != oldWidget.enabled ||
        readOnly != oldWidget.readOnly ||
        validationResult != oldWidget.validationResult ||
        errorAnnouncement != oldWidget.errorAnnouncement;
  }
}
