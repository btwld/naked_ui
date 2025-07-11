import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A fully customizable text field with no default styling or decoration.
///
/// NakedTextField provides all the core functionality of a TextField without imposing
/// any visual styling or decoration features of the standard Material TextField,
/// giving developers complete design freedom.
///
/// This component maintains all behavior including text editing, keyboard input,
/// selection, and accessibility features while allowing custom visual representation
/// through the required [builder] parameter.
///
/// The widget handles various interaction states and provides callbacks:
/// - [onHoverState]: Called when mouse hover state changes (true when hovered)
/// - [onPressedState]: Called when pressed state changes (true when pressed)
/// - [onFocusState]: Called when focus state changes (true when focused)
///
/// Example usage:
/// ```dart
/// class MyCustomTextField extends StatefulWidget {
///   final TextEditingController controller;
///   final String? hintText;
///   final ValueChanged<String>? onChanged;
///
///   const MyCustomTextField({
///     Key? key,
///     required this.controller,
///     this.hintText,
///     this.onChanged,
///   }) : super(key: key);
///
///   @override
///   _MyCustomTextFieldState createState() => _MyCustomTextFieldState();
/// }
///
/// class _MyCustomTextFieldState extends State<MyCustomTextField> {
///   bool _isHovered = false;
///   bool _isPressed = false;
///   bool _isFocused = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return NakedTextField(
///       controller: widget.controller,
///       onChanged: widget.onChanged,
///       onHoverState: (isHovered) => setState(() => _isHovered = isHovered),
///       onPressedState: (isPressed) => setState(() => _isPressed = isPressed),
///       onFocusState: (isFocused) => setState(() => _isFocused = isFocused),
///       builder: (context, child) {
///         return Container(
///           height: 40,
///           decoration: BoxDecoration(
///             border: Border.all(
///               color: _isFocused
///                   ? Colors.blue
///                   : _isHovered
///                       ? Colors.grey.shade400
///                       : Colors.grey.shade300,
///               width: _isFocused ? 2 : 1,
///             ),
///             borderRadius: BorderRadius.circular(4),
///           ),
///           padding: EdgeInsets.symmetric(horizontal: 12),
///           child: Stack(
///             alignment: Alignment.centerLeft,
///             children: [
///               if (widget.controller.text.isEmpty && widget.hintText != null)
///                 Text(
///                   widget.hintText!,
///                   style: TextStyle(color: Colors.grey.shade500),
///                 ),
///               child, // This is the EditableText from NakedTextField
///             ],
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
///
/// The widget provides a simplified text field that:
/// - Maintains all core text editing functionality
/// - Removes default Material styling and decoration
/// - Allows complete customization through the builder pattern
/// - Handles all standard text field interactions
/// - Supports accessibility features
/// - Provides state callbacks for hover, press and focus
class NakedTextField extends StatefulWidget {
  /// Creates a simplified text field.
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
    this.onPressedState,
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
    this.onHoverState,
    this.onFocusState,
    this.style,
    required this.builder,
    this.ignorePointers,
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

  /// The magnifier configuration to use for this text field.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// The controller for undo/redo history.
  final UndoHistoryController? undoController;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Configures how the platform keyboard will select an uppercase or lowercase keyboard.
  final TextCapitalization textCapitalization;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  final TextDirection? textDirection;

  /// Whether the text can be changed.
  final bool readOnly;

  /// Whether to show cursor.
  final bool? showCursor;

  /// Whether this text field should focus itself if nothing else is already focused.
  final bool autofocus;

  /// Character used for obscuring text if obscureText is true.
  final String obscuringCharacter;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Configuration of smart dashes behavior.
  final SmartDashesType smartDashesType;

  /// Configuration of smart quotes behavior.
  final SmartQuotesType smartQuotesType;

  /// Whether to show input suggestions as the user types.
  final bool enableSuggestions;

  /// The maximum number of lines for the text to span.
  final int? maxLines;

  /// The minimum number of lines to occupy when the content spans fewer lines.
  final int? minLines;

  /// Whether this widget's height will be sized to fill its parent.
  final bool expands;

  /// The maximum number of characters to allow in the text field.
  final int? maxLength;

  /// Determines how the maxLength limit should be enforced.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Called when the user initiates a change to the text field's value.
  final ValueChanged<String>? onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final VoidCallback? onEditingComplete;

  /// Called when the user submits editable content.
  final ValueChanged<String>? onSubmitted;

  /// Private API for platform-specific customization.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Optional input validation and formatting overrides.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Width of the cursor.
  final double cursorWidth;

  /// Height of the cursor.
  final double? cursorHeight;

  /// Radius of the cursor.
  final Radius? cursorRadius;

  /// Whether the cursor opacity animates.
  final bool? cursorOpacityAnimates;

  /// Color of the cursor.
  final Color? cursorColor;

  /// Controls how tall the selection highlight boxes are computed to be.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// The appearance of the keyboard.
  final Brightness? keyboardAppearance;

  /// Padding around the scrollable content.
  final EdgeInsets scrollPadding;

  /// Whether the value can be selected.
  final bool enableInteractiveSelection;

  /// Controls the selection handles and contextual toolbar.
  final TextSelectionControls? selectionControls;

  /// Triggered when the user taps on the field.
  final GestureTapCallback? onPressed;

  /// Whether onPressed should be called for every tap.
  final bool onTapAlwaysCalled;

  /// Called when the pressed state changes.
  ///
  /// The callback provides the current pressed state as a boolean parameter:
  /// - `true` when the text field is pressed
  /// - `false` when the text field is released
  final ValueChanged<bool>? onPressedState;

  /// Called when a tap is detected outside of the field.
  final TapRegionCallback? onTapOutside;

  /// Called when a tap up is detected outside of the field.
  final TapRegionUpCallback? onPressUpOutside;

  /// Drag start behavior.
  final DragStartBehavior dragStartBehavior;

  /// Controls scrolling of the text field.
  final ScrollController? scrollController;

  /// Scroll physics to apply to the scrollable content.
  final ScrollPhysics? scrollPhysics;

  /// Autofill hint information.
  final Iterable<String>? autofillHints;

  /// Configuration for handling content insertion.
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// Clip behavior for content inside the text field.
  final Clip clipBehavior;

  /// Restoration ID for this widget.
  final String? restorationId;

  final bool stylusHandwritingEnabled;

  /// Whether to enable IME personalized learning.
  final bool enableIMEPersonalizedLearning;

  /// Builder for the context (right-click or long press) menu.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Whether this text field can request focus.
  final bool canRequestFocus;

  /// Configuration for spell check behavior.
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Called when the hover state changes.
  ///
  /// The callback provides the current hover state as a boolean parameter:
  /// - `true` when the mouse pointer enters the text field
  /// - `false` when the mouse pointer exits the text field
  final ValueChanged<bool>? onHoverState;

  /// Called when the focus state changes.
  ///
  /// The callback provides the current focus state as a boolean parameter:
  /// - `true` when the text field gains focus
  /// - `false` when the text field loses focus
  final ValueChanged<bool>? onFocusState;

  /// The group ID for the text field.
  final Object groupId;

  /// The style of the text field.
  final TextStyle? style;

  /// Whether to ignore pointers.
  final bool? ignorePointers;

  /// Required builder function that allows complete customization of the text field's appearance.
  ///
  /// The builder receives:
  /// - [context] The build context
  /// - [editableText] The core EditableText widget that should be included in the custom layout
  final Widget Function(BuildContext context, Widget editableText) builder;

  @override
  State<NakedTextField> createState() => _NakedTextFieldState();
}

class _NakedTextFieldState extends State<NakedTextField>
    with RestorationMixin
    implements TextSelectionGestureDetectorBuilderDelegate, AutofillClient {
  RestorableTextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!.value;

  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement(
        Theme.of(context).platform,
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
    _effectiveFocusNode.addListener(_handleFocusChanged);
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

  void _handleFocusChanged() {
    // ignore: no-empty-block, avoid-empty-setstate
    setState(() {
      // Rebuild the widget on focus change to show/hide the text selection highlight.
    });
    widget.onFocusState?.call(_effectiveFocusNode.hasFocus);
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

    switch (Theme.of(context).platform) {
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

    switch (Theme.of(context).platform) {
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
      (oldWidget.focusNode ?? _focusNode)?.removeListener(_handleFocusChanged);
      (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChanged);
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
    _effectiveFocusNode.removeListener(_handleFocusChanged);
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

    final ThemeData theme = Theme.of(context);
    final TextStyle style =
        widget.style ??
        TextStyle(
          color: widget.enabled ? Colors.black : Colors.grey,
          fontSize: 16.0,
        );
    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? theme.brightness;
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
    switch (theme.platform) {
      case TargetPlatform.iOS:
        forcePressEnabled = true;
        textSelectionControls ??= cupertinoTextSelectionHandleControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates ??= true;
        cursorColor = widget.cursorColor ?? CupertinoColors.activeBlue;
        selectionColor = CupertinoColors.activeBlue.withValues(alpha: 0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
          iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context),
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
          iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context),
          0,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        textSelectionControls ??= materialTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = widget.cursorColor ?? theme.colorScheme.primary;
        selectionColor = theme.colorScheme.primary.withValues(alpha: 0.40);
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        textSelectionControls ??= desktopTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = widget.cursorColor ?? theme.colorScheme.primary;
        selectionColor = theme.colorScheme.primary.withValues(alpha: 0.40);
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

    return Semantics(
      enabled: widget.enabled,
      onTap: widget.readOnly
          ? null
          : () {
              if (!controller.selection.isValid) {
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
              }
              _requestKeyboard();
            },
      child: widget.enabled
          ? MouseRegion(
              onEnter: (PointerEnterEvent event) =>
                  widget.onHoverState?.call(true),
              onExit: (PointerExitEvent event) =>
                  widget.onHoverState?.call(false),
              cursor: SystemMouseCursors.text,
              child: _selectionGestureDetectorBuilder.buildGestureDetector(
                behavior: HitTestBehavior.translucent,
                child: widget.builder(context, child),
              ),
            )
          : _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: widget.builder(context, child),
            ),
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
  }

  @override
  void onTapDown(TapDragDownDetails details) {
    super.onTapDown(details);
    _state.widget.onPressedState?.call(true);
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state.widget.onPressedState?.call(false);
  }

  @override
  bool get onUserTapAlwaysCalled => _state.widget.onTapAlwaysCalled;
}
