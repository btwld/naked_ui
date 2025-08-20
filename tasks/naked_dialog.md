## showNakedDialog — API Parity Plan

- Material counterpart: showDialog/RawDialogRoute
- API completeness: Complete

### Current API Summary
- Params: context, builder, barrierColor (required), barrierDismissible, barrierLabel, useRootNavigator, routeSettings, anchorPoint, transitionDuration, transitionBuilder, requestFocus, traversalEdgeBehavior
- Uses RawDialogRoute with InheritedTheme.capture to keep theme context; explicit barrierColor provides headless control

### Differences vs Material
- barrierColor required (Material showDialog has default); acceptable for headless design

### Recommendations
- Keep as-is; document differences and provide examples

### Test Plan
- Route lifecycle and barrier interactions; traversalEdgeBehavior

### Task Checklist
- [ ] Document differences and examples (custom transitions, focus behavior)
- [ ] Add unit tests around barrier dismissible/label and traversalEdgeBehavior


### State Controller Naming
- Not applicable (no interaction controller in dialog API). If future interactive wrappers are added, standardize to stateController (WidgetStatesController)
