import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show
        materialTextSelectionHandleControls,
        desktopTextSelectionHandleControls,
        TextMagnifier;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Provides text editing functionality without visual styling.
///
/// Uses a builder pattern for complete customization of appearance.
class NakedTextField extends StatefulWidget {
  /// Creates a naked text field.
  const NakedTextField({
    super.key,
    this.groupId = EditableText,
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
    this.cursorColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onPressed,
    this.onTapAlwaysCalled = false,
    this.onPressChange,
    this.onTapOutside,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.contentInsertionConfiguration,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.onPressUpOutside,
    this.stylusHandwritingEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.onHoverChange,
    this.onFocusChange,
    this.style,
    required this.builder,
    this.ignorePointers,
    this.addSemantics = true,
    this.excludeChildSemantics = false,
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

  /// Magnifier configuration for this text field.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// Controller for undo/redo history.
  final UndoHistoryController? undoController;

  /// Keyboard type for editing the text.
  final TextInputType? keyboardType;

  /// Action button type for the keyboard.
  final TextInputAction? textInputAction;

  /// How the platform keyboard selects uppercase or lowercase.
  final TextCapitalization textCapitalization;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Text directionality.
  final TextDirection? textDirection;

  /// Whether the text can be changed.
  final bool readOnly;

  /// Whether to show the cursor.
  final bool? showCursor;

  /// Whether to autofocus if nothing else is focused.
  final bool autofocus;

  /// Character used for obscuring text.
  final String obscuringCharacter;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Smart dashes behavior configuration.
  final SmartDashesType smartDashesType;

  /// Smart quotes behavior configuration.
  final SmartQuotesType smartQuotesType;

  /// Whether to show input suggestions as the user types.
  final bool enableSuggestions;

  /// Maximum number of lines for the text.
  final int? maxLines;

  /// Minimum number of lines to occupy.
  final int? minLines;

  /// Whether to size height to fill parent.
  final bool expands;

  /// Maximum number of characters allowed.
  final int? maxLength;

  /// How the maxLength limit is enforced.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Called when text field value changes.
  final ValueChanged<String>? onChanged;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Called when content is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Platform-specific customization API.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Input validation and formatting overrides.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Cursor width.
  final double cursorWidth;

  /// Cursor height.
  final double? cursorHeight;

  /// Cursor radius.
  final Radius? cursorRadius;

  /// Whether cursor opacity animates.
  final bool? cursorOpacityAnimates;

  /// Cursor color.
  final Color? cursorColor;

  /// How tall selection highlight boxes are computed.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// How wide selection highlight boxes are computed.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// Keyboard appearance.
  final Brightness? keyboardAppearance;

  /// Scrollable content padding.
  final EdgeInsets scrollPadding;

  /// Whether the value can be selected.
  final bool enableInteractiveSelection;

  /// Selection handles and contextual toolbar controls.
  final TextSelectionControls? selectionControls;

  /// Called when the field is tapped.
  final GestureTapCallback? onPressed;

  /// Whether to call onPressed for every tap.
  final bool onTapAlwaysCalled;

  /// Called when pressed state changes.
  final ValueChanged<bool>? onPressChange;

  /// Called when tapping outside the field.
  final TapRegionCallback? onTapOutside;

  /// Called when tap up occurs outside the field.
  final TapRegionUpCallback? onPressUpOutside;

  /// Behavior when drag starts.
  final DragStartBehavior dragStartBehavior;

  /// Controls text field scrolling.
  final ScrollController? scrollController;

  /// Scroll physics for scrollable content.
  final ScrollPhysics? scrollPhysics;

  /// Autofill hint information.
  final Iterable<String>? autofillHints;

  /// Content insertion handling configuration.
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// Clip behavior for content inside the field.
  final Clip clipBehavior;

  /// Widget restoration ID.
  final String? restorationId;

  final bool stylusHandwritingEnabled;

  /// Whether to enable IME personalized learning.
  final bool enableIMEPersonalizedLearning;

  /// Context menu builder (right-click or long press).
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Whether the field can request focus.
  final bool canRequestFocus;

  /// Spell check behavior configuration.
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Called when hover state changes.
  final ValueChanged<bool>? onHoverChange;

  /// Called when focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// Group ID for the text field.
  final Object groupId;

  /// Text field style.
  final TextStyle? style;

  /// Whether to ignore pointers.
  final bool? ignorePointers;

  /// Required builder for complete text field customization.
  ///
  /// Receives context and the core EditableText widget.
  final Widget Function(BuildContext context, Widget editableText) builder;

  /// Whether to add semantics to this text field.
  final bool addSemantics;

  /// Whether to exclude child semantics.
  final bool excludeChildSemantics;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Semantic hint for accessibility.
  final String? semanticHint;

  @override
  State<NakedTextField> createState() => _NakedTextFieldState();
}

class _NakedTextFieldState extends State<NakedTextField>
    with RestorationMixin
    implements TextSelectionGestureDetectorBuilderDelegate, AutofillClient {
  // Color constants to avoid Material dependency
  static const Color _defaultTextColor = Color(0xFF000000);
  static const Color _defaultDisabledColor = Color(0xFF9E9E9E);
  static const Color _androidCursorColor = Color(0xFF2196F3);

  // iOS cursor offset constant (from Material library)
  static const int _iOSHorizontalOffset = -2;

  RestorableTextEditingController? _controller;
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

  bool _showSelectionHandles = false;

  late TextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  late bool forcePressEnabled;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;

  // End of API for TextSelectionGestureDetectorBuilderDelegate.

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _TextFieldSelectionGestureDetectorBuilder(state: this);
    if (widget.controller == null) {
      _createLocalController();
    }
    _effectiveFocusNode.canRequestFocus =
        widget.canRequestFocus && widget.enabled;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  bool get _canRequestFocus {
    final NavigationMode mode =
        MediaQuery.maybeNavigationModeOf(context) ?? NavigationMode.traditional;

    return switch (mode) {
      NavigationMode.traditional => widget.canRequestFocus && widget.enabled,
      NavigationMode.directional => true,
    };
  }

  void _registerController() {
    assert(_controller != null);
    registerForRestoration(_controller!, 'controller');
  }

  void _createLocalController([TextEditingValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);

    if (!restorePending) {
      _registerController();
    }
  }

  void _requestKeyboard() {
    _editableText?.requestKeyboard();
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }

    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (widget.readOnly && _effectiveController.selection.isCollapsed) {
      return false;
    }

    if (!widget.enabled) {
      return false;
    }

    // ignore: prefer-switch-with-enums
    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.stylusHandwriting) {
      return true;
    }

    if (_effectiveController.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  void _handleFocusChange() {
    final hasFocus = _effectiveFocusNode.hasFocus;
    // Rebuild only if selection handles visibility could change
    // or if there is an external listener.
    if (widget.onFocusChange != null || _showSelectionHandles != hasFocus) {
      // Use addPostFrameCallback to avoid setState during build
      // This follows Flutter's official recommendation for listener callbacks
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ignore: avoid-empty-setstate, no-empty-block
          setState(() {
            // Rebuild the widget on focus change to show/hide the text selection highlight.
          });
        }
      });
    }
    widget.onFocusChange?.call(hasFocus);
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        if (cause == SelectionChangedCause.longPress) {
          _editableText?.bringIntoView(selection.extent);
        }
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) {
          _editableText?.hideToolbar();
        }
    }
  }

  /// Toggle the toolbar when a selection handle is tapped.
  void _handleSelectionHandleTapped() {
    if (_effectiveController.selection.isCollapsed) {
      _editableText!.toggleToolbar();
    }
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    widget.onHoverChange?.call(true);
  }

  void _handleMouseExit(PointerExitEvent event) {
    widget.onHoverChange?.call(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveFocusNode.canRequestFocus = _canRequestFocus;
  }

  @override
  void didUpdateWidget(NakedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _createLocalController(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      unregisterFromRestoration(_controller!);
      _controller!.dispose();
      _controller = null;
    }

    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _focusNode)?.removeListener(_handleFocusChange);
      (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChange);
    }

    _effectiveFocusNode.canRequestFocus = _canRequestFocus;

    if (_effectiveFocusNode.hasFocus &&
        widget.readOnly != oldWidget.readOnly &&
        widget.enabled) {
      if (_effectiveController.selection.isCollapsed) {
        _showSelectionHandles = !widget.readOnly;
      }
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_controller != null) {
      _registerController();
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void autofill(TextEditingValue newEditingValue) =>
      _editableText!.autofill(newEditingValue);

  @override
  String? get restorationId => widget.restorationId;

  EditableTextState? get _editableText => editableTextKey.currentState;

  // AutofillClient implementation start.
  @override
  String get autofillId => _editableText!.autofillId;
  @override
  TextInputConfiguration get textInputConfiguration {
    final List<String>? autofillHints = widget.autofillHints?.toList(
      growable: false,
    );
    final AutofillConfiguration autofillConfiguration = autofillHints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: autofillHints,
            currentEditingValue: _effectiveController.value,
            hintText: null,
          )
        : AutofillConfiguration.disabled;

    return _editableText!.textInputConfiguration.copyWith(
      autofillConfiguration: autofillConfiguration,
    );
  }

  // AutofillClient implementation end.

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextStyle style =
        widget.style ??
        TextStyle(
          color: widget.enabled ? _defaultTextColor : _defaultDisabledColor,
          fontSize: 16.0,
        );
    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? Brightness.light;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    final List<TextInputFormatter> formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(
          widget.maxLength,
          maxLengthEnforcement: _effectiveMaxLengthEnforcement,
        ),
    ];

    // Configure platform-specific spell check
    final SpellCheckConfiguration spellCheckConfiguration;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        spellCheckConfiguration = const SpellCheckConfiguration.disabled();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        spellCheckConfiguration =
            widget.spellCheckConfiguration ??
            const SpellCheckConfiguration.disabled();
    }

    TextSelectionControls? textSelectionControls = widget.selectionControls;
    final bool paintCursorAboveText;
    bool? cursorOpacityAnimates = widget.cursorOpacityAnimates;
    Offset? cursorOffset;
    Color cursorColor;
    Color selectionColor;
    Radius? cursorRadius = widget.cursorRadius;

    // Configure platform-specific properties
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        forcePressEnabled = true;
        textSelectionControls ??= cupertinoTextSelectionHandleControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates ??= true;
        cursorColor = widget.cursorColor ?? CupertinoColors.activeBlue;
        selectionColor = CupertinoColors.activeBlue.withValues(alpha: 0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
          _iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context),
          0,
        );
      case TargetPlatform.macOS:
        forcePressEnabled = false;
        textSelectionControls ??= cupertinoDesktopTextSelectionHandleControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates ??= false;
        cursorColor = widget.cursorColor ?? CupertinoColors.activeBlue;
        selectionColor = CupertinoColors.activeBlue.withValues(alpha: 0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
          _iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context),
          0,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        textSelectionControls ??= materialTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = widget.cursorColor ?? _androidCursorColor;
        selectionColor = _androidCursorColor.withValues(alpha: 0.40);
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        textSelectionControls ??= desktopTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = widget.cursorColor ?? _androidCursorColor;
        selectionColor = _androidCursorColor.withValues(alpha: 0.40);
    }

    Widget child = TextFieldTapRegion(
      child: IgnorePointer(
        ignoring: widget.ignorePointers ?? !widget.enabled,
        child: RepaintBoundary(
          child: UnmanagedRestorationScope(
            bucket: bucket,
            child: EditableText(
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
              style: widget.style ?? style,
              cursorColor: cursorColor,
              backgroundCursorColor: CupertinoColors.inactiveGray,
              textAlign: widget.textAlign,
              textDirection: widget.textDirection,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              expands: widget.expands,
              autofocus: widget.autofocus,
              showCursor: widget.showCursor,
              showSelectionHandles: _showSelectionHandles,
              selectionColor: focusNode.hasFocus ? selectionColor : null,
              selectionControls: widget.enableInteractiveSelection
                  ? textSelectionControls
                  : null,
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
              onTapUpOutside: widget.onPressUpOutside,
              inputFormatters: formatters,
              rendererIgnoresPointer: true,
              cursorWidth: widget.cursorWidth,
              cursorHeight: widget.cursorHeight,
              cursorRadius: cursorRadius,
              cursorOpacityAnimates: cursorOpacityAnimates,
              cursorOffset: cursorOffset,
              paintCursorAboveText: paintCursorAboveText,
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
              restorationId: 'editable',
              stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
              enableIMEPersonalizedLearning:
                  widget.enableIMEPersonalizedLearning,
              contentInsertionConfiguration:
                  widget.contentInsertionConfiguration,
              contextMenuBuilder: widget.contextMenuBuilder,
              spellCheckConfiguration: spellCheckConfiguration,
              magnifierConfiguration:
                  widget.magnifierConfiguration ??
                  TextMagnifier.adaptiveMagnifierConfiguration,
              undoController: widget.undoController,
            ),
          ),
        ),
      ),
    );

    Widget _wrapWithSemantics(Widget textField) {
      if (!widget.addSemantics) return textField;

      return Semantics(
        excludeSemantics: widget.excludeChildSemantics,
        textField: true,
        readOnly: widget.readOnly,
        obscured: widget.obscureText,
        multiline: (widget.maxLines ?? 1) > 1,
        maxValueLength: widget.maxLength,
        currentValueLength: _effectiveController.text.length,
        label: widget.semanticLabel,
        value: _effectiveController.text,
        hint: widget.semanticHint,
        child: textField,
      );
    }

    return widget.enabled
        ? MouseRegion(
            onEnter: _handleMouseEnter,
            onExit: _handleMouseExit,
            cursor: SystemMouseCursors.text,
            child: _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: _wrapWithSemantics(widget.builder(context, child)),
            ),
          )
        : _selectionGestureDetectorBuilder.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: _wrapWithSemantics(widget.builder(context, child)),
          );
  }
}

class _TextFieldSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  final _NakedTextFieldState _state;

  _TextFieldSelectionGestureDetectorBuilder({
    required _NakedTextFieldState state,
  }) : _state = state,
       super(delegate: state);

  @override
  void onUserTap() {
    _state.widget.onPressed?.call();

    // Handle keyboard request for accessibility and functionality
    if (!_state.widget.readOnly) {
      final controller = _state._effectiveController;
      if (!controller.selection.isValid) {
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      }
      _state._requestKeyboard();
    }
  }

  @override
  void onTapDown(TapDragDownDetails details) {
    super.onTapDown(details);
    _state.widget.onPressChange?.call(true);
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state.widget.onPressChange?.call(false);
  }

  @override
  bool get onUserTapAlwaysCalled => _state.widget.onTapAlwaysCalled;
}
