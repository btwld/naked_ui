## NakedTextField — API Parity Plan

- Material counterpart: EditableText (low-level) / TextField (high-level)
- API completeness: Complete (by headless design)

### Current API Summary
- Broad surface that mirrors EditableText: controller, focusNode, undoController, keyboardType, textInputAction, capitalization, textAlign/direction, readOnly/showCursor/autofocus, obscuringCharacter/obscureText, autocorrect, smartDashes/smartQuotes, enableSuggestions, maxLines/minLines/expands, maxLength/enforcement, onChanged/onEditingComplete/onSubmitted/onAppPrivateCommand, inputFormatters, enabled, cursorWidth/height/radius/opacity/color, selection height/width, keyboardAppearance, scrollPadding, dragStartBehavior, enableInteractiveSelection, selectionControls, onPressed/onTapAlwaysCalled/onPressChange/onTapOutside/onPressUpOutside, scrollController/physics, autofillHints, contentInsertionConfiguration, clipBehavior, restorationId, stylusHandwritingEnabled, enableIMEPersonalizedLearning, contextMenuBuilder, canRequestFocus, spellCheckConfiguration, magnifierConfiguration, onHoverChange/onFocusChange, groupId, style, ignorePointers, builder
- Internals: wraps EditableText; correct platform-specific controls/colors; semantics via Semantics on wrapper; gesture/focus wiring for interaction

### Gaps vs Material
- Visual decoration intentionally omitted; consumer provides via builder

### Recommendations
- Keep as-is; optional examples for common headless compositions

### Test Plan
- EditableText delegation (selection, keyboard, platform controls)
- Semantics for readOnly/obscured/multiline and length values

### Task Checklist
- [ ] Add documentation/examples showing common headless patterns
- [ ] Add unit tests for semantics and platform-specific behavior toggles



### State Controller Naming
- Not applicable (uses EditableText/Focus/gestures rather than WidgetStatesController). If adding interactive wrappers, use stateController naming
