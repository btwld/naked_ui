## NakedTooltip — API Parity Plan

- Material counterpart: Tooltip
- API completeness: Partial

### Current API Summary
- Props: child (target), tooltipBuilder, showDuration, waitDuration, position, fallbackPositions, tooltipSemantics, excludeFromSemantics, overlay lifecycle onStateChange/removalDelay
- Behavior: shows after waitDuration on hover; hides after showDuration on exit; positioned with fallback alignment

### Gaps vs Material
- No trigger configuration beyond hover; lacks focus-trigger and long-press activation options
- No explicit controller for programmatic show/hide (currently via internal ShowNotifier + MenuAnchor controller pattern)

### Recommendations
- Introduce triggerMode enum: hover, focus, longPress, tap (combination supported)
- Add focus-triggered show and Escape-to-dismiss; optionally respect platform accessibility settings
- Consider exposing a simple TooltipController API (wrapping existing lifecycle) for imperative control

### Migration Notes
- Backward compatible; default trigger remains hover

### Test Plan
- Trigger mode matrix: hover, focus, longPress, tap behaviors; Escape dismissal when focus-triggered
- Positioning fallback correctness and semantics.tooltip propagation

### Task Checklist
- [ ] Implement triggerMode and wire behaviors
- [ ] Add optional TooltipController (programmatic)
- [ ] Write tests for triggers/semantics/positioning
- [ ] Update docs with a11y patterns and animated examples


### State Controller Naming
- If interaction states are exposed in future (e.g., focus/hover for target), standardize parameter name to stateController (WidgetStatesController)
- Update NakedInteractable/NakedFocusable usage accordingly in examples


### Removal Note
- If any onStateChange-like callback was introduced for interaction states, remove it from the public API (use stateController/per-event callbacks instead)
