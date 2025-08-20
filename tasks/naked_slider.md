## NakedSlider — API Parity Plan

- Material counterpart: Slider
- API completeness: Partial

### Current API Summary
- Props: child, value, min, max, onChanged, onDragStart, onDragEnd(value), onHoverChange, onDragChange(bool), onFocusChange, enabled, semanticLabel/hint, cursor, enableHapticFeedback, focusNode, autofocus, direction, divisions, keyboardStep, largeKeyboardStep, excludeSemantics, controller
- Keyboard: Arrow keys with RTL awareness; Shift for large steps; Home/End to min/max
- Semantics: NakedSemantics.slider with value/increasedValue/decreasedValue

### Gaps vs Material
- onDragStart signature lacks value; parity would pass value on start as well
- Missing PageUp/PageDown key handling (use larger steps)

### Recommendations
- Change onDragStart to ValueChanged<double> (current value) and wire at drag start; retain onDragEnd(value)
- Add PageUp/PageDown intents to adjust by largeKeyboardStep (or divisions if present)
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks

### Migration Notes
- Minor source change for onDragStart consumers; document update path

### Test Plan
- Divisions snapping and normalization
- RTL keyboard mapping correctness; Home/End set to min/max; PageUp/PageDown present
- Semantics values reflect min/max/value; onIncrease/onDecrease compute next values

### Task Checklist
- [ ] Update onDragStart signature and invocation timing
- [ ] Implement PageUp/PageDown keyboard support
- [ ] Write tests and update docs (no onStateChange)


### State Controller Naming
- Rename controller parameter to stateController
- Type: WidgetStatesController
- Update NakedInteractable/NakedFocusable plumbing and docs/examples


### Removal Note
- If this component currently exposes an onStateChange callback, remove it from the public API
