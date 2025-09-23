import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/cupertino.dart'
    show
        cupertinoTextSelectionHandleControls,
        cupertinoDesktopTextSelectionHandleControls;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
// We import just what we need from Material/Cupertino to keep surface minimal,
// but we intentionally *opt in* to OS-adaptive selection/magnifier.
import 'package:flutter/material.dart'
    show
        TextMagnifier,
        materialTextSelectionHandleControls,
        desktopTextSelectionHandleControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'mixins/naked_mixins.dart';
import 'utilities/naked_focusable_detector.dart';
import 'utilities/naked_state_scope.dart';
import 'utilities/state.dart';

typedef NakedTextFieldBuilder =
    Widget Function(BuildContext context, Widget editableText);

/// Immutable view passed to [NakedTextField.builder].
class NakedTextFieldState extends NakedState {
  /// The current text value.
  final String text;

  /// Whether the text field is currently focused.
  final bool isFocused;

  /// Whether the text field has text content.
  final bool hasText;

  /// Whether the text field is read-only.
  final bool isReadOnly;

  /// Whether the text field is enabled.
  final bool isEnabled;

  NakedTextFieldState({
    required super.states,
    required this.text,
    required this.isFocused,
    required this.hasText,
    required this.isReadOnly,
    required this.isEnabled,
  });

  /// Returns the nearest [NakedTextFieldState] provided by [NakedStateScope].
  static NakedTextFieldState of(BuildContext context) => NakedState.of(context);

  /// Returns the nearest [NakedTextFieldState] if one is available.
  static NakedTextFieldState? maybeOf(BuildContext context) =>
      NakedState.maybeOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope.
  static WidgetStatesController controllerOf(BuildContext context) =>
      NakedState.controllerOf(context);

  /// Returns the [WidgetStatesController] from the nearest scope, if any.
  static WidgetStatesController? maybeControllerOf(BuildContext context) =>
      NakedState.maybeControllerOf(context);

  /// Whether the text field is empty.
  bool get isEmpty => !hasText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NakedTextFieldState &&
        setEquals(other.states, states) &&
        other.text == text &&
        other.isFocused == isFocused &&
        other.hasText == hasText &&
        other.isReadOnly == isReadOnly &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode =>
      Object.hash(states, text, isFocused, hasText, isReadOnly, isEnabled);
}

/// Headless, builder-first text input built on [EditableText].
///
/// Exposes native-feeling defaults while remaining design-system agnostic.
/// Renders no visuals—wrap the provided [editableText] via [builder] to style or decorate.
///
/// ```dart
/// NakedTextField(
///   controller: textController,
///   onChanged: (text) => print('Changed: $text'),
///   builder: (context, editableText) => Container(
///     decoration: BoxDecoration(border: Border.all()),
///     child: editableText,
///   ),
/// )
/// ```
///
/// See also:
/// - [EditableText], the underlying primitive text input.
/// - [TextField], the Material-styled text input for typical apps.
class NakedTextField extends StatefulWidget {
  const NakedTextField({
    super.key,
    this.groupId = EditableText, // Keeps parity with EditableText default.
    this.controller,
    this.focusNode,
    this.undoController,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled = true,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates,
    this.cursorColor, // override adaptive color if needed
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls, // override adaptive controls if needed
    this.onTap, // prefer this name for a field tap
    this.onTapAlwaysCalled = false,
    this.onTapChange,
    this.onTapOutside,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.contentInsertionConfiguration,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.onTapUpOutside,
    this.stylusHandwritingEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.onHoverChange,
    this.onFocusChange,
    this.onPressChange,
    this.style,
    this.builder,
    this.ignorePointers,
    this.semanticLabel,
    this.semanticHint,
  }) : assert(obscuringCharacter.length == 1),
       smartDashesType =
           smartDashesType ??
           (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
       smartQuotesType =
           smartQuotesType ??
           (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(builder != null, 'NakedTextField requires a builder'),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         "minLines can't be greater than maxLines",
       ),
       assert(
         !expands || (maxLines == null && minLines == null),
         'minLines and maxLines must be null when expands is true.',
       ),
       assert(
         !obscureText || maxLines == 1,
         'Obscured fields cannot be multiline.',
       ),
       assert(maxLength == null || maxLength > 0);

  /// The magnifier configuration (defaults to platform-appropriate).
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// The controller for the text being edited.
  final TextEditingController? controller;

  /// The focus node for this widget.
  final FocusNode? focusNode;

  /// The undo/redo controller.
  final UndoHistoryController? undoController;

  /// The keyboard type and action.
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// The text capitalization and alignment.
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextDirection? textDirection;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to show the cursor.
  final bool? showCursor;

  final bool autofocus;

  /// The character used for obscuring text.
  final String obscuringCharacter;

  /// Whether to obscure text (for example, passwords).
  final bool obscureText;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// The smart dashes type.
  final SmartDashesType smartDashesType;

  /// The smart quotes type.
  final SmartQuotesType smartQuotesType;

  /// Whether to enable suggestions.
  final bool enableSuggestions;

  /// The maximum number of lines.
  final int? maxLines;

  /// The minimum number of lines.
  final int? minLines;

  /// Whether the field expands vertically.
  final bool expands;

  /// The maximum character length.
  final int? maxLength;

  /// How to enforce the maximum length.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Called when the form is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Called for app private commands.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// The input formatters to apply.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is enabled.
  final bool enabled;

  /// Cursor visuals
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final bool? cursorOpacityAnimates;
  final Color? cursorColor;

  /// Selection visuals
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;

  /// Keyboard appearance (iOS).
  final Brightness? keyboardAppearance;

  /// Scrolling
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;

  /// Clipping behavior for the underlying [EditableText].
  final Clip clipBehavior;

  /// Selection and context menu
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Taps, hover, and outside taps
  final GestureTapCallback? onTap;
  final bool onTapAlwaysCalled;
  final ValueChanged<bool>? onTapChange;
  final TapRegionCallback? onTapOutside;
  final TapRegionUpCallback? onTapUpOutside;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onPressChange;

  /// Autofill and content insertion
  final Iterable<String>? autofillHints;
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// Focus management
  final bool canRequestFocus;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Restoration
  final String? restorationId;

  /// IME and stylus features
  final bool stylusHandwritingEnabled;
  final bool enableIMEPersonalizedLearning;

  /// Spell check
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Grouping for IME (matches [EditableText]).
  final Object groupId;

  /// Text style override (else derives from [DefaultTextStyle]).
  final TextStyle? style;

  /// Whether to ignore pointers.
  final bool? ignorePointers;

  /// Builds the visual wrapper around the underlying [EditableText].
  final NakedTextFieldBuilder? builder;

  /// Semantics
  final String? semanticLabel;
  final String? semanticHint;

  @override
  State<NakedTextField> createState() => _NakedTextFieldState();
}

class _NakedTextFieldState extends State<NakedTextField>
    with RestorationMixin, WidgetStatesMixin<NakedTextField>
    implements TextSelectionGestureDetectorBuilderDelegate, AutofillClient {
  // Neutral base colors that don't imply a design system.
  static const Color _defaultTextColor = Color(0xFF000000);
  static const Color _defaultDisabledColor = Color(0xFF9E9E9E);
  static const Color _neutralBgCursor = Color(0xFFBDBDBD);

  // iOS cursor horizontal offset (native-looking nudge).
  static const int _iOSHorizontalOffset = -2;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  // State management and lifecycle methods

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _NakedSelectionGestureDetectorBuilder(
      state: this,
    );

    if (widget.controller == null) {
      _createLocalController();
    }

    // Set initial focus capabilities based on widget properties.
    // MediaQuery access is deferred to didChangeDependencies.
    _effectiveFocusNode.canRequestFocus =
        widget.canRequestFocus && widget.enabled;
    _effectiveFocusNode.addListener(_handleFocusChange);
    // Attach controller listener via unified handler.
    if (widget.controller != null) {
      _updateAttachedController(widget.controller);
    } else if (_controller != null && !restorePending) {
      _updateAttachedController(_controller!.value);
    }
  }

  // Determines if focus can be requested based on navigation mode.
  bool _canRequestFocusFor(NavigationMode? mode) {
    switch (mode) {
      case NavigationMode.directional:
        return true; // TV/gamepad mode can always request focus
      case NavigationMode.traditional:
      case null:
        return widget.canRequestFocus && widget.enabled;
    }
  }

  void _createLocalController([TextEditingValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);
    if (!restorePending) {
      registerForRestoration(_controller!, 'controller');
    }
  }

  // Centralized attach/detach to the current effective controller.
  void _updateAttachedController(TextEditingController? newController) {
    // Detach from any previously attached controller.
    _detachControllerListener?.call();
    _detachControllerListener = null;

    // Attach to the new controller if provided.
    if (newController != null) {
      newController.addListener(_handleControllerChanged);
      _detachControllerListener = () {
        newController.removeListener(_handleControllerChanged);
      };
    }
  }

  void _requestKeyboard() => _editableText?.requestKeyboard();

  // Rebuild on text changes to keep Semantics and NakedTextFieldState in sync.
  void _handleControllerChanged() {
    if (!mounted) return;
    // ignore: no-empty-block
    setState(() {});
  }

  void _handleFocusChange() {
    final focused = _effectiveFocusNode.hasFocus;
    // Keep WidgetStates in sync and fire callback only when changed.
    updateFocusState(focused, widget.onFocusChange);
    if (!mounted) return;
    // Rebuild for selection highlight & semantics updates tied to focus.
    // ignore: no-empty-block
    setState(() {});
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }
    if (cause == SelectionChangedCause.keyboard) return false;
    if (!widget.enabled) return false;
    if (widget.readOnly && _effectiveController.selection.isCollapsed) {
      return false;
    }
    switch (cause) {
      case SelectionChangedCause.longPress:
      case SelectionChangedCause.stylusHandwriting:
        return true;
      case SelectionChangedCause.doubleTap:
      case SelectionChangedCause.drag:
      case SelectionChangedCause.forcePress:
      case SelectionChangedCause.toolbar:
      case SelectionChangedCause.keyboard:
      case SelectionChangedCause.tap:
      case null:
        break;
    }

    return _effectiveController.text.isNotEmpty;
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final willShow = _shouldShowSelectionHandles(cause);
    if (willShow != _showSelectionHandles) {
      setState(() => _showSelectionHandles = willShow);
    }

    // Bring caret into view on long press to match native behavior.
    if (cause == SelectionChangedCause.longPress) {
      _editableText?.bringIntoView(selection.extent);
    }

    // Desktop UX: hide toolbar while dragging.
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) {
          _editableText?.hideToolbar();
        }
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        break;
    }
  }

  void _handleSelectionHandleTapped() {
    if (_effectiveController.selection.isCollapsed) {
      _editableText?.toggleToolbar();
    }
  }

  void _handleMouseEnter(PointerEnterEvent _) =>
      updateHoverState(true, widget.onHoverChange);

  void _handleMouseExit(PointerExitEvent _) =>
      updateHoverState(false, widget.onHoverChange);

  @override
  void initializeWidgetStates() {
    updateDisabledState(!widget.enabled);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read navigation mode from MediaQuery after dependencies are available.
    _navMode = MediaQuery.maybeNavigationModeOf(context);
    _effectiveFocusNode.canRequestFocus = _canRequestFocusFor(_navMode);
  }

  @override
  void didUpdateWidget(NakedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller ownership swap while preserving state/restoration.
    if (widget.controller == null && oldWidget.controller != null) {
      _createLocalController(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      // Detach listener before unregistering/disposal to avoid accessing
      // RestorableListenable.value while unregistered.
      _controller!.value.removeListener(_handleControllerChanged);
      unregisterFromRestoration(_controller!);
      _controller!.dispose();
      _controller = null;
    }

    // After potential swap, attach listener to the current effective controller.
    final TextEditingController? nextController =
        widget.controller ?? (!restorePending ? _controller?.value : null);
    _updateAttachedController(nextController);

    // Focus node swap: keep our listener correct.
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _focusNode)?.removeListener(_handleFocusChange);
      (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChange);
    }

    // Use cached navigation mode to avoid MediaQuery access during widget updates.
    _effectiveFocusNode.canRequestFocus = _canRequestFocusFor(_navMode);

    // If readOnly changed while focused, recompute handle visibility.
    if (_effectiveFocusNode.hasFocus &&
        widget.readOnly != oldWidget.readOnly &&
        widget.enabled) {
      final willShow = _shouldShowSelectionHandles(
        SelectionChangedCause.longPress,
      );
      if (willShow != _showSelectionHandles) {
        // In didUpdateWidget, a rebuild is already scheduled; no setState needed.
        _showSelectionHandles = willShow;
      }
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_controller != null) {
      registerForRestoration(_controller!, 'controller');
      // Attach listener after restoration registration for local controller.
      _updateAttachedController(_controller!.value);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    // Detach controller listener to avoid leaks.
    _detachControllerListener?.call();
    _detachControllerListener = null;
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void autofill(TextEditingValue newEditingValue) =>
      _editableText?.autofill(newEditingValue);

  RestorableTextEditingController? _controller;

  VoidCallback? _detachControllerListener;

  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!.value;

  FocusNode? _focusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement(
        defaultTargetPlatform,
      );

  late TextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  bool _showSelectionHandles = false;

  // Track the current navigation mode from MediaQuery.
  NavigationMode? _navMode;

  // TextSelectionGestureDetectorBuilderDelegate
  @override
  late bool forcePressEnabled;

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

  EditableTextState? get _editableText => editableTextKey.currentState;

  // AutofillClient implementation

  @override
  String get autofillId => _editableText!.autofillId;

  @override
  TextInputConfiguration get textInputConfiguration {
    final List<String>? hints = widget.autofillHints?.toList(growable: false);
    final AutofillConfiguration ac = hints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: hints,
            currentEditingValue: _effectiveController.value,
            hintText: null,
          )
        : AutofillConfiguration.disabled;

    return _editableText!.textInputConfiguration.copyWith(
      autofillConfiguration: ac,
    );
  }

  @override
  String? get restorationId => widget.restorationId;

  // Widget building and rendering

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    // Derive text style from ambient DefaultTextStyle unless overridden.
    final TextStyle baseStyle =
        (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
          color: widget.enabled ? _defaultTextColor : _defaultDisabledColor,
        );

    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? Brightness.light;

    final controller = _effectiveController;
    final focusNode = _effectiveFocusNode;

    // Input formatters including length limiting.
    final formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(
          widget.maxLength,
          maxLengthEnforcement: _effectiveMaxLengthEnforcement,
        ),
    ];

    // Caller-controlled or default disabled (consistent across platforms by default).
    final SpellCheckConfiguration effectiveSpellCheck =
        widget.spellCheckConfiguration ??
        const SpellCheckConfiguration.disabled();

    // Resolve adaptive platform visuals & behavior in one place.
    final _PlatformDefaults p = _PlatformDefaults.resolve(
      context: context,
      cursorColorOverride: widget.cursorColor,
      cursorRadiusOverride: widget.cursorRadius,
      cursorOpacityAnimatesOverride: widget.cursorOpacityAnimates,
    );
    forcePressEnabled = p.forcePressEnabled;

    // Selection controls: caller override or adaptive default.
    final TextSelectionControls? controls = widget.enableInteractiveSelection
        ? (widget.selectionControls ?? p.platformSelectionControls)
        : null;

    // Magnifier: caller override or adaptive.
    final TextMagnifierConfiguration magnifier =
        widget.magnifierConfiguration ??
        TextMagnifier.adaptiveMagnifierConfiguration;

    Widget editable = EditableText(
      key: editableTextKey,
      controller: controller,
      focusNode: focusNode,
      readOnly: widget.readOnly || !widget.enabled,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      style: baseStyle,
      cursorColor: p.cursorColor,
      backgroundCursorColor: _neutralBgCursor,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      autofocus: widget.autofocus,
      showCursor: widget.showCursor,
      showSelectionHandles: _showSelectionHandles,
      selectionColor: focusNode.hasFocus ? p.selectionColor : null,
      selectionControls: controls,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onAppPrivateCommand: widget.onAppPrivateCommand,
      onSelectionChanged: _handleSelectionChanged,
      onSelectionHandleTapped: _handleSelectionHandleTapped,
      groupId: widget.groupId,
      onTapOutside: widget.onTapOutside,
      onTapUpOutside: widget.onTapUpOutside,
      inputFormatters: formatters,
      rendererIgnoresPointer: true,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: p.cursorRadius,
      cursorOpacityAnimates: p.cursorOpacityAnimates,
      cursorOffset: p.cursorOffset,
      paintCursorAboveText: p.paintCursorAboveText,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      scrollPadding: widget.scrollPadding,
      keyboardAppearance: keyboardAppearance,
      dragStartBehavior: widget.dragStartBehavior,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillClient: this,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId == null
          ? null
          : '${widget.restorationId!}.editable',
      stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      contentInsertionConfiguration: widget.contentInsertionConfiguration,
      contextMenuBuilder: widget.contextMenuBuilder,
      spellCheckConfiguration: effectiveSpellCheck,
      magnifierConfiguration: magnifier,
      undoController: widget.undoController,
    );

    // Tap region & restoration scoping; keep pointer-ignoring atop EditableText.
    editable = TextFieldTapRegion(
      child: IgnorePointer(
        ignoring: widget.ignorePointers ?? !widget.enabled,
        child: RepaintBoundary(
          child: UnmanagedRestorationScope(bucket: bucket, child: editable),
        ),
      ),
    );

    // Semantics: mirror tap, hide obscured values, expose state.
    void _semanticTap() {
      widget.onTap?.call();
      if (!widget.readOnly) {
        final c = controller;
        if (!c.selection.isValid) {
          c.selection = TextSelection.collapsed(offset: c.text.length);
        }
        _requestKeyboard();
      }
    }

    Widget withSemantics(Widget child) {
      return Semantics(
        container: true,
        enabled: widget.enabled,
        textField: true,
        readOnly: widget.readOnly || !widget.enabled,
        focusable: widget.enabled,
        focused: focusNode.hasFocus,
        obscured: widget.obscureText,
        multiline: (widget.maxLines ?? 1) > 1,
        maxValueLength: widget.maxLength,
        currentValueLength: controller.text.length,
        label: widget.semanticLabel,
        value: widget.obscureText ? null : controller.text,
        hint: widget.semanticHint,
        onTap: (widget.enabled && !widget.readOnly) ? _semanticTap : null,
        child: child,
      );
    }

    // Create the text field state
    final textFieldState = NakedTextFieldState(
      states: widgetStates,
      text: controller.text,
      isFocused: focusNode.hasFocus,
      hasText: controller.text.isNotEmpty,
      isReadOnly: widget.readOnly,
      isEnabled: widget.enabled,
    );

    // Build content using the builder and always provide state via scope
    final Widget content = widget.builder!(context, editable);

    final Widget composed = withSemantics(content);
    final Widget wrappedContent = NakedStateScope(
      value: textFieldState,
      child: composed,
    );

    // Ensure a focus action is exposed in semantics parity with Material.
    final Widget composedWithFocusSemantics = NakedFocusableDetector(
      enabled: widget.enabled,
      includeSemantics: true,
      child: wrappedContent,
    );

    // Selection/gesture plumbing
    final Widget detector = _selectionGestureDetectorBuilder
        .buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: composedWithFocusSemantics,
        );

    // Hover affordance only when enabled.
    final Widget maybeMouseRegion = widget.enabled
        ? MouseRegion(
            onEnter: _handleMouseEnter,
            onExit: _handleMouseExit,
            cursor: SystemMouseCursors.text,
            child: detector,
          )
        : detector;

    return maybeMouseRegion;
  }
}

// Text selection gesture handling

class _NakedSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  final _NakedTextFieldState _state;

  _NakedSelectionGestureDetectorBuilder({required _NakedTextFieldState state})
    : _state = state,
      super(delegate: state);

  @override
  void onUserTap() {
    _state.widget.onTap?.call();

    if (!_state.widget.readOnly) {
      final c = _state._effectiveController;
      if (!c.selection.isValid) {
        c.selection = TextSelection.collapsed(offset: c.text.length);
      }
      _state._requestKeyboard();
    }
  }

  @override
  void onTapDown(TapDragDownDetails details) {
    super.onTapDown(details);
    _state.widget.onTapChange?.call(true);
    _state.widget.onPressChange?.call(true);
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state.widget.onTapChange?.call(false);
    _state.widget.onPressChange?.call(false);
  }

  @override
  bool get onUserTapAlwaysCalled => _state.widget.onTapAlwaysCalled;
}

// Platform-specific styling and behavior defaults

class _PlatformDefaults {
  final bool forcePressEnabled;
  final bool paintCursorAboveText;
  final bool cursorOpacityAnimates;
  final Color cursorColor;
  final Color selectionColor;
  final Radius? cursorRadius;
  final Offset? cursorOffset;
  final TextSelectionControls? platformSelectionControls;

  static const Color _androidBlue = Color(0xFF2196F3);

  const _PlatformDefaults({
    required this.forcePressEnabled,
    required this.paintCursorAboveText,
    required this.cursorOpacityAnimates,
    required this.cursorColor,
    required this.selectionColor,
    this.cursorRadius,
    this.cursorOffset,
    this.platformSelectionControls,
  });

  static _PlatformDefaults resolve({
    required BuildContext context,
    Color? cursorColorOverride,
    Radius? cursorRadiusOverride,
    bool? cursorOpacityAnimatesOverride,
  }) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _PlatformDefaults(
          forcePressEnabled: true,
          paintCursorAboveText: true,
          cursorOpacityAnimates: cursorOpacityAnimatesOverride ?? true,
          cursorColor: cursorColorOverride ?? const Color(0xFF007AFF),
          selectionColor: const Color(0x66007AFF), // ~40% alpha
          cursorRadius: cursorRadiusOverride ?? const Radius.circular(2),
          cursorOffset: Offset(
            _NakedTextFieldState._iOSHorizontalOffset /
                MediaQuery.devicePixelRatioOf(context),
            0,
          ),
          platformSelectionControls: cupertinoTextSelectionHandleControls,
        );
      case TargetPlatform.macOS:
        return _PlatformDefaults(
          forcePressEnabled: false,
          paintCursorAboveText: true,
          cursorOpacityAnimates: cursorOpacityAnimatesOverride ?? false,
          cursorColor: cursorColorOverride ?? const Color(0xFF007AFF),
          selectionColor: const Color(0x66007AFF),
          cursorRadius: cursorRadiusOverride ?? const Radius.circular(2),
          cursorOffset: Offset(
            _NakedTextFieldState._iOSHorizontalOffset /
                MediaQuery.devicePixelRatioOf(context),
            0,
          ),
          platformSelectionControls:
              cupertinoDesktopTextSelectionHandleControls,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return _PlatformDefaults(
          forcePressEnabled: false,
          paintCursorAboveText: false,
          cursorOpacityAnimates: cursorOpacityAnimatesOverride ?? false,
          cursorColor: cursorColorOverride ?? _androidBlue,
          selectionColor: _androidBlue.withValues(alpha: 0.40),
          cursorRadius: cursorRadiusOverride,
          cursorOffset: null,
          platformSelectionControls: materialTextSelectionHandleControls,
        );
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _PlatformDefaults(
          forcePressEnabled: false,
          paintCursorAboveText: false,
          cursorOpacityAnimates: cursorOpacityAnimatesOverride ?? false,
          cursorColor: cursorColorOverride ?? _androidBlue,
          selectionColor: _androidBlue.withValues(alpha: 0.40),
          cursorRadius: cursorRadiusOverride,
          cursorOffset: null,
          platformSelectionControls: desktopTextSelectionHandleControls,
        );
    }
  }
}
