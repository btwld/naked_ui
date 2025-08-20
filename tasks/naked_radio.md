## NakedRadioGroup & NakedRadio — API Parity Plan

- Material counterpart: Radio, RadioListTile (grouping via groupValue), keyboard behavior specified by Material/WAI-ARIA
- API completeness: Partial

### Current API Summary
- Group: groupValue, onChanged(T?), enabled (on widget), provides Shortcuts for arrow navigation, custom ReadingOrderTraversalPolicy
- Radio: child, value, onSelectChange(bool), enabled, semanticLabel/hint, cursor, enableHapticFeedback, focusNode, autofocus, excludeSemantics, controller; per-event onFocusChange/onHoverChange/onHighlightChanged
- Semantics: NakedSemantics.radio (checked/inMutuallyExclusiveGroup)

### Gaps vs Material
- Selection occurs on focus change (focus → select) in _handleFocusChange; this deviates from expected behavior
- Missing toggleable option (Material Radio can be toggleable)
- Group keyboard: lacks Home/End to first/last radio; arrow mapping present
- Unified onStateChange missing

### Recommendations
- Remove select-on-focus; limit selection to activation (tap/Enter/Space) and arrow navigation only
- Add toggleable option at radio level (or group level default) to allow deselection when tapping selected radio
- Add Home/End shortcuts on group; maintain arrow navigation; consider orientation-specific mapping if relevant visually
- Do not introduce onStateChange; continue with stateController and/or per-event callbacks

### Migration Notes
- Behavior change: consumers relying on focus implying selection need to update; this aligns with Material/ARIA norms
- Toggleable is opt-in to maintain backward compatibility

### Test Plan
- Arrow navigation orders by reading order; Home/End go to first/last
- Focus change does not alter selection; activation does
- RTL navigation correctness
- Semantics: radio checked, inMutuallyExclusiveGroup, enabled/focusable states

### Task Checklist
- [ ] Remove selection-on-focus; migrate logic to activation only
- [ ] Add toggleable
- [ ] Add Home/End navigation
- [ ] Add unit tests; update docs and migration notes


### State Controller Naming
- Rename controller parameter to stateController across Radio and Group scopes where applicable
- Parameter type remains WidgetStatesController
- Update NakedInteractable/NakedFocusable plumbing with stateController naming
- Update docs and examples accordingly


### Removal Note
- If this component currently exposes an onStateChange callback, remove it from the public API
