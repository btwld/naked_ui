## NakedButton — API Parity Plan

- Material counterpart: TextButton/ElevatedButton/OutlinedButton; InkWell for interaction behavior
- API completeness: Partial

### Current API Summary
- Props: child, onPressed, enabled, isSemanticButton, semanticLabel, semanticHint, cursor, enableHapticFeedback, focusNode, autofocus, excludeSemantics, controller
- Interaction callbacks: onFocusChange, onHoverChange, onHighlightChanged (pressed)
- Semantics: via NakedSemantics.button (or Semantics when isSemanticButton=false)
- Keyboard: ActivateIntent integration via NakedInteractable

### Gaps vs Material
- Missing onLongPress (and optional onDoubleTap) surface though NakedInteractable supports them
- Tests missing for Space/Enter activation parity and semantics on enabled/disabled states

### Recommendations
- Add: onLongPress (and optionally onDoubleTap) to NakedButton constructor and plumb into NakedInteractable
- Do not introduce onStateChange; continue using stateController and/or existing per-event callbacks
- Ensure keyboard activation parity (ActivateIntent already wired); add unit tests
- Verify cursor behavior (forbidden when disabled) and semantics exposure; add tests

### Migration Notes
- Existing usage continues to work; keep using stateController or per-event callbacks
- No onStateChange will be added; remove any experimental usage if present

### Test Plan
- Keyboard: Space/Enter triggers onPressed when enabled; does nothing when disabled
- Semantics: button role, label/hint set, focusable when enabled, not when disabled
- Pointer: cursor changes to forbidden when disabled

### Task Checklist
- [x] Add onLongPress and onDoubleTap (optional)
- [x] Update implementation to forward gestures to NakedInteractable
- [x] Add unit tests for keyboard and semantics
- [x] Update docs/examples demonstrating stateController usage (no onStateChange)


### State Controller Naming
- [x] Rename controller parameter to stateController across this component
- [x] Ensure parameter type is WidgetStatesController
- [x] Update NakedInteractable and NakedFocusable to use stateController naming consistently and plumb through
- [x] Update docs/examples to reference stateController


### Removal Note
- If this component currently exposes an onStateChange callback, remove it from the public API
