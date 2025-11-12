# Phase 2 Medium-Priority Issues - Architectural Plan

**Codebase:** `/home/user/naked_ui/packages/naked_ui`
**Prepared:** 2025-11-12
**Total Component Files Analyzed:** 15 files
**Issues Addressed:** 4 medium-priority consistency issues

---

## Table of Contents

1. [Issue 1: Inconsistent Enabled State Property Naming](#issue-1-inconsistent-enabled-state-property-naming)
2. [Issue 2: FocusNode Management Inconsistency](#issue-2-focusnode-management-inconsistency)
3. [Issue 3: MouseCursor Default Value Inconsistency](#issue-3-mousecursor-default-value-inconsistency)
4. [Issue 4: MenuController Disposal Issues](#issue-4-menucontroller-disposal-issues)
5. [Implementation Order](#implementation-order)
6. [Testing Strategy](#testing-strategy)

---

## Issue 1: Inconsistent Enabled State Property Naming

### 1.1 Current State Audit

#### Components WITH `enabled` property:
| Component | File | Property Type | Default | Line |
|-----------|------|---------------|---------|------|
| NakedButton | naked_button.dart | `bool enabled` | `true` | 47 |
| NakedCheckbox | naked_checkbox.dart | `bool enabled` | `true` | 81 |
| NakedRadio | naked_radio.dart | `bool enabled` | `true` | 61 |
| NakedToggle | naked_toggle.dart | `bool enabled` | `true` | 105 |
| NakedToggleOption | naked_toggle.dart | `bool enabled` | `true` | 363 |
| NakedSlider | naked_slider.dart | `bool enabled` | `true` | 110 |
| NakedSelect | naked_select.dart | `bool enabled` | `true` | 202 |
| NakedTextField | naked_textfield.dart | `bool enabled` | `true` | 135 |
| NakedTabs | naked_tabs.dart | `bool enabled` | `true` | 118 |
| NakedTab | naked_tabs.dart | `bool enabled` | `true` | 306 |
| NakedAccordion | naked_accordion.dart | `bool enabled` | `true` | 402 |

#### Components WITHOUT `enabled` property:
| Component | File | Reason | Should Have? |
|-----------|------|--------|--------------|
| NakedMenu | naked_menu.dart | Uses NakedButton internally (has its own enabled) | **YES** ⚠️ |
| NakedPopover | naked_popover.dart | No enable/disable concept | NO ✓ |
| NakedTooltip | naked_tooltip.dart | No enable/disable concept | NO ✓ |
| NakedDialog | naked_dialog.dart | Modal pattern, no interaction | NO ✓ |
| NakedAccordionGroup | naked_accordion.dart | Container only, items control enabled | NO ✓ |

#### Internal Enabled Computation Patterns:

**Pattern 1: Simple property usage (Direct)**
```dart
// NakedButton (line 122)
bool get _isInteractive =>
    widget.enabled && (widget.onPressed != null || widget.onLongPress != null);

// Used in: NakedButton
```

**Pattern 2: Effective enabled with callback check**
```dart
// NakedCheckbox (line 149)
bool get _effectiveEnabled => enabled && onChanged != null;

// Used in: NakedCheckbox, NakedToggle, NakedToggleOption
```

**Pattern 3: Late initialization field**
```dart
// NakedTab (line 334)
late bool _isEnabled;

void _applyFocusability() {
  final node = effectiveFocusNode;
  node
    ..canRequestFocus = _isEnabled
    ..skipTraversal = !_isEnabled;
}

// Used in: NakedTab
```

**Pattern 4: Direct usage in build**
```dart
// NakedTextField, NakedSlider, NakedAccordion, etc.
// Just use widget.enabled directly without a getter
```

### 1.2 Consistency Analysis

#### Current Variations:

1. **Property naming**: All use `enabled` (consistent ✓)
2. **Property type**: All use `bool` (consistent ✓)
3. **Default value**: All use `true` (consistent ✓)
4. **Coverage**: NakedMenu is missing this property (inconsistent ✗)

#### Computation Pattern Variations:

| Pattern | Components | Pros | Cons |
|---------|-----------|------|------|
| `_isInteractive` getter | Button | Clear intent, considers both enabled AND callbacks | Component-specific naming |
| `_effectiveEnabled` getter | Checkbox, Toggle, ToggleOption | Standard name, cached | Recomputed on each access |
| `_isEnabled` field | Tab | Cached, efficient | Requires manual sync in lifecycle |
| Direct `widget.enabled` | TextField, Slider, Accordion | Simple, no overhead | No caching, repeated property access |

### 1.3 Recommended Standard

#### For Components with User Callbacks:
```dart
/// Whether the widget is interactive (enabled with callbacks).
bool get _effectiveEnabled => widget.enabled && widget.onChanged != null;
// Or for buttons: widget.enabled && (widget.onPressed != null || widget.onLongPress != null)
```

**Reasoning:**
- Standard naming across codebase (`_effectiveEnabled` used by 3 components already)
- Clear semantic meaning
- Combines enabled property with callback presence
- Minimal performance impact (getter recomputation negligible)

#### For Components without User Callbacks:
```dart
// Just use widget.enabled directly - no need for a getter
final cursor = widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic;
```

### 1.4 Complete Migration Plan

#### Step 1: Add `enabled` property to NakedMenu
- Add property to NakedMenu widget constructor
- Pass through to internal NakedButton
- Update semantics
- Document breaking change

#### Step 2: Standardize computation patterns
- Keep `_effectiveEnabled` where appropriate
- Rename `_isInteractive` → `_effectiveEnabled` in NakedButton
- Convert `_isEnabled` field to getter in NakedTab
- Keep direct usage where no callbacks exist

### 1.5 Exact Before/After Code

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_menu.dart`

**BEFORE (Lines 198-217):**
```dart
class NakedMenu<T> extends StatefulWidget {
  const NakedMenu({
    super.key,
    this.child,
    this.builder,
    required this.overlayBuilder,
    required this.controller,
    this.onSelected,
    this.onOpen,
    this.onClose,
    this.onCanceled,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.triggerFocusNode,
    this.positioning = const OverlayPositionConfig(),
    this.excludeSemantics = false,
  });
```

**AFTER:**
```dart
class NakedMenu<T> extends StatefulWidget {
  const NakedMenu({
    super.key,
    this.child,
    this.builder,
    required this.overlayBuilder,
    required this.controller,
    this.onSelected,
    this.onOpen,
    this.onClose,
    this.onCanceled,
    this.onOpenRequested,
    this.onCloseRequested,
    this.consumeOutsideTaps = true,
    this.useRootOverlay = false,
    this.closeOnClickOutside = true,
    this.triggerFocusNode,
    this.positioning = const OverlayPositionConfig(),
    this.excludeSemantics = false,
    this.enabled = true,  // ← ADD THIS
  });
```

**BEFORE (Lines 219-269):**
```dart
  /// Type alias for [NakedMenuItem] for cleaner API access.
  static final Item = NakedMenuItem.new;

  /// The static trigger widget.
  final Widget? child;

  /// Builds the trigger surface.
  final ValueWidgetBuilder<NakedMenuState>? builder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Controls show/hide of the underlying [RawMenuAnchor] and manages selection state.
  final MenuController controller;

  /// Called when an item is selected.
  ///
  /// Note: You can also use [controller.select] to update selection state directly.
  final ValueChanged<T>? onSelected;

  /// Lifecycle callbacks.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when the menu closes without a selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors (for example, to drive animations).
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether taps outside the overlay close the menu.
  final bool closeOnClickOutside;

  /// Whether outside taps on the trigger are consumed.
  final bool consumeOutsideTaps;

  /// Whether to target the root overlay instead of the nearest ancestor.
  final bool useRootOverlay;

  /// Optional focus node for the trigger.
  final FocusNode? triggerFocusNode;

  /// Overlay positioning configuration.
  final OverlayPositionConfig positioning;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;
```

**AFTER:**
```dart
  /// Type alias for [NakedMenuItem] for cleaner API access.
  static final Item = NakedMenuItem.new;

  /// The static trigger widget.
  final Widget? child;

  /// Builds the trigger surface.
  final ValueWidgetBuilder<NakedMenuState>? builder;

  /// Builds the overlay panel.
  final RawMenuAnchorOverlayBuilder overlayBuilder;

  /// Controls show/hide of the underlying [RawMenuAnchor] and manages selection state.
  final MenuController controller;

  /// Called when an item is selected.
  ///
  /// Note: You can also use [controller.select] to update selection state directly.
  final ValueChanged<T>? onSelected;

  /// Lifecycle callbacks.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Called when the menu closes without a selection.
  final VoidCallback? onCanceled;

  /// Open/close interceptors (for example, to drive animations).
  final RawMenuAnchorOpenRequestedCallback? onOpenRequested;

  final RawMenuAnchorCloseRequestedCallback? onCloseRequested;

  /// Whether taps outside the overlay close the menu.
  final bool closeOnClickOutside;

  /// Whether outside taps on the trigger are consumed.
  final bool consumeOutsideTaps;

  /// Whether to target the root overlay instead of the nearest ancestor.
  final bool useRootOverlay;

  /// Optional focus node for the trigger.
  final FocusNode? triggerFocusNode;

  /// Overlay positioning configuration.
  final OverlayPositionConfig positioning;

  /// Whether to exclude this widget from the semantic tree.
  ///
  /// When true, the widget and its children are hidden from accessibility services.
  final bool excludeSemantics;

  /// Whether the menu trigger is interactive.  // ← ADD THIS
  ///  // ← ADD THIS
  /// When false, the trigger button is disabled and cannot be pressed.  // ← ADD THIS
  final bool enabled;  // ← ADD THIS
```

**BEFORE (Lines 300-318):**
```dart
  @override
  Widget build(BuildContext context) {
    Widget button = NakedButton(
      onPressed: _toggle,
      focusNode: widget.triggerFocusNode,
      child: widget.child,
      builder: (context, buttonState, child) {
        final menuState = NakedMenuState(
          states: buttonState.states,
          isOpen: _isOpen,
        );

        return NakedStateScopeBuilder(
          value: menuState,
          child: widget.child,
          builder: widget.builder,
        );
      },
    );
```

**AFTER:**
```dart
  @override
  Widget build(BuildContext context) {
    Widget button = NakedButton(
      onPressed: _toggle,
      enabled: widget.enabled,  // ← ADD THIS
      focusNode: widget.triggerFocusNode,
      child: widget.child,
      builder: (context, buttonState, child) {
        final menuState = NakedMenuState(
          states: buttonState.states,
          isOpen: _isOpen,
        );

        return NakedStateScopeBuilder(
          value: menuState,
          child: widget.child,
          builder: widget.builder,
        );
      },
    );
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_button.dart`

**BEFORE (Line 121):**
```dart
  bool get _isInteractive =>
      widget.enabled &&
      (widget.onPressed != null || widget.onLongPress != null);
```

**AFTER:**
```dart
  bool get _effectiveEnabled =>
      widget.enabled &&
      (widget.onPressed != null || widget.onLongPress != null);
```

**Then replace all uses of `_isInteractive` with `_effectiveEnabled` (10 occurrences in lines 134, 155, 164, 175, 188, 201, 204, 223-231, 244, 254, 263):**

Examples:
- Line 134: `if (!widget.enabled || widget.onPressed == null) return;` → Keep as is (direct property check is fine here)
- Line 155: `if (!widget.enabled || widget.onPressed == null) return;` → Keep as is
- Line 188: `updateDisabledState(!_isInteractive);` → `updateDisabledState(!_effectiveEnabled);`
- Line 201: `if (wasInteractive != _isInteractive) {` → `if (wasInteractive != _effectiveEnabled) {`
- Line 204: `if (!_isInteractive) {` → `if (!_effectiveEnabled) {`
- Lines 223-231: Replace all `_isInteractive` → `_effectiveEnabled`
- Line 244: `enabled: _isInteractive,` → `enabled: _effectiveEnabled,`
- Line 254: `enabled: _isInteractive,` → `enabled: _effectiveEnabled,`
- Line 263: `? widget.mouseCursor : SystemMouseCursors.basic,` → Keep logic, just use `_effectiveEnabled`

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_tabs.dart`

**BEFORE (Lines 334-342):**
```dart
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  late bool _isEnabled;
  late NakedTabsScope _scope;

  void _applyFocusability() {
    final node = effectiveFocusNode;
    node
      ..canRequestFocus = _isEnabled
      ..skipTraversal = !_isEnabled;
  }
```

**AFTER:**
```dart
  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;

  late NakedTabsScope _scope;

  bool get _effectiveEnabled => widget.enabled && _scope.enabled;

  void _applyFocusability() {
    final node = effectiveFocusNode;
    final enabled = _effectiveEnabled;
    node
      ..canRequestFocus = enabled
      ..skipTraversal = !enabled;
  }
```

**BEFORE (Lines 396-411):**
```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _isEnabled = widget.enabled && _scope.enabled;
    _applyFocusability();
  }

  @override
  void didUpdateWidget(covariant NakedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEnabled = widget.enabled && _scope.enabled;
    if (newEnabled != _isEnabled) {
      _isEnabled = newEnabled;
      _applyFocusability();
    }
  }
```

**AFTER:**
```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = NakedTabsScope.of(context);
    _applyFocusability();
  }

  @override
  void didUpdateWidget(covariant NakedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _applyFocusability();
    }
  }
```

**Replace all remaining `_isEnabled` occurrences with `_effectiveEnabled`:**
- Line 344: `if (!_isEnabled) return;` → `if (!_effectiveEnabled) return;`
- Line 354: `if (!_isEnabled) return;` → `if (!_effectiveEnabled) return;`
- Line 418: `updateDisabledState(!_isEnabled);` → `updateDisabledState(!_effectiveEnabled);`
- Line 430-443: Replace all uses
- Line 458: `enabled: _isEnabled,` → `enabled: _effectiveEnabled,`
- Line 462: `if (f && _isEnabled) {` → `if (f && _effectiveEnabled) {`
- Line 469: `mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,` → Use `_effectiveEnabled`

### 1.6 Ripple Effects

#### Breaking Changes:
- **NakedMenu**: Adding `enabled` property is technically breaking, but has sensible default (`true`)
  - **Migration**: Users can add `enabled: true` explicitly if needed, but default maintains current behavior

#### Documentation Updates Required:
- Update API docs for NakedMenu to describe `enabled` property
- Update migration guide with this change
- Add example showing enabled/disabled menu

#### Files Affected:
| File | Type | Changes |
|------|------|---------|
| `naked_menu.dart` | Source | Add `enabled` property, pass to button |
| `naked_button.dart` | Source | Rename `_isInteractive` → `_effectiveEnabled` |
| `naked_tabs.dart` | Source | Convert `_isEnabled` field → `_effectiveEnabled` getter |

#### Example/Test Files (if they exist):
- Update any examples using NakedMenu
- Add test cases for NakedMenu enabled/disabled states
- Update button tests to use new naming

### 1.7 Task Breakdown

| Task | Estimated Time | Dependencies | Priority |
|------|----------------|--------------|----------|
| Add `enabled` to NakedMenu | 30 min | None | High |
| Rename `_isInteractive` in NakedButton | 15 min | None | Medium |
| Refactor `_isEnabled` in NakedTab | 30 min | None | Medium |
| Update documentation | 45 min | Above tasks | Medium |
| Update examples | 30 min | Above tasks | Low |
| Write/update tests | 60 min | Above tasks | High |
| Code review | 30 min | All above | High |

**Total Estimated Time:** 4 hours

### 1.8 Validation Checklist

- [ ] All interactive components have `enabled` property
- [ ] All components using enabled+callbacks use `_effectiveEnabled` getter pattern
- [ ] No components use field-based enabled tracking (use getters instead)
- [ ] Button renaming complete and all references updated
- [ ] Tab refactoring complete and lifecycle methods simplified
- [ ] All tests pass
- [ ] Manual testing of enabled/disabled states for:
  - [ ] NakedMenu trigger button
  - [ ] NakedButton (verify no behavior changes)
  - [ ] NakedTab (verify focus management still works)
- [ ] Documentation updated
- [ ] Examples updated
- [ ] No regressions in existing functionality

---

## Issue 2: FocusNode Management Inconsistency

### 2.1 Current State Audit

#### Components USING FocusNodeMixin:
| Component | File | Lines | Mixin Declaration |
|-----------|------|-------|-------------------|
| NakedButton | naked_button.dart | 116-117 | `with WidgetStatesMixin<NakedButton>, FocusNodeMixin<NakedButton>` |
| NakedSlider | naked_slider.dart | 199-200 | `with WidgetStatesMixin<NakedSlider>, FocusNodeMixin<NakedSlider>` |
| NakedRadio | naked_radio.dart | 118-119 | `with FocusNodeMixin<NakedRadio<T>>` |
| NakedTab | naked_tabs.dart | 329-330 | `with WidgetStatesMixin<NakedTab>, FocusNodeMixin<NakedTab>` |

#### Components NOT USING FocusNodeMixin (but have focusNode property):
| Component | File | FocusNode Property | Internal Implementation |
|-----------|------|-------------------|------------------------|
| NakedCheckbox | naked_checkbox.dart | Line 84 | Uses `widget.focusNode` directly, no management |
| NakedToggle | naked_toggle.dart | Line 108 | Uses `widget.focusNode` directly, no management |
| NakedToggleOption | naked_toggle.dart | Line 366 | Uses `widget.focusNode` directly, no management |
| NakedAccordion | naked_accordion.dart | Line 410 | Uses `widget.focusNode` directly, no management |
| NakedTextField | naked_textfield.dart | Line 109 | Custom implementation (lines 389-598) |
| NakedPopover | naked_popover.dart | Line 74 | Custom implementation (lines 139-165) |

#### Components with NO FocusNode concept:
| Component | File | Reason |
|-----------|------|--------|
| NakedSelect | naked_select.dart | Uses NakedButton internally (which has FocusNodeMixin) |
| NakedMenu | naked_menu.dart | Uses NakedButton internally (which has FocusNodeMixin) |
| NakedTooltip | naked_tooltip.dart | Hover-only, no keyboard interaction |
| NakedDialog | naked_dialog.dart | Focus managed by route/navigator |
| NakedAccordionGroup | naked_accordion.dart | Container, items handle focus |
| NakedTabs | naked_tabs.dart | Container, individual tabs handle focus |
| NakedTabView | naked_tabs.dart | Content container, not focusable |

### 2.2 Consistency Analysis

#### FocusNodeMixin Implementation (from naked_mixins.dart, lines 167-274):

**Features provided by the mixin:**
1. ✓ Internal focus node creation when widget doesn't provide one
2. ✓ Safe swapping between external and internal nodes
3. ✓ Focus preservation during node swaps
4. ✓ Single source of truth via `effectiveFocusNode`
5. ✓ Automatic listener management
6. ✓ Proper disposal

**Required from host State:**
```dart
mixin FocusNodeMixin<T extends StatefulWidget> on State<T> {
  @protected
  FocusNode? get widgetProvidedNode;  // Must implement

  @protected
  ValueChanged<bool>? get onFocusChange => null;  // Optional override

  @protected
  String get focusNodeDebugLabel => '${widget.runtimeType} (internal)';  // Optional override
}
```

#### Current Patterns in Non-Mixin Components:

**Pattern A: Direct pass-through (No internal creation)**
```dart
// NakedCheckbox, NakedToggle, NakedToggleOption, NakedAccordion
NakedFocusableDetector(
  focusNode: widget.focusNode,  // Can be null!
  // ...
)
```
**Issues**:
- No internal fallback if user doesn't provide one
- NakedFocusableDetector must handle null
- No focus change callbacks integrated

**Pattern B: Custom elaborate management (TextField)**
```dart
// NakedTextField (lines 389-598)
FocusNode? _focusNode;

FocusNode get _effectiveFocusNode =>
    widget.focusNode ?? (_focusNode ??= FocusNode());

@override
void initState() {
  super.initState();
  _effectiveFocusNode.canRequestFocus = widget.canRequestFocus && widget.enabled;
  _effectiveFocusNode.addListener(_handleFocusChange);
}

@override
void didUpdateWidget(NakedTextField oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.focusNode != oldWidget.focusNode) {
    (oldWidget.focusNode ?? _focusNode)?.removeListener(_handleFocusChange);
    (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChange);
  }
  _effectiveFocusNode.canRequestFocus = _canRequestFocusFor(_navMode);
}

@override
void dispose() {
  _effectiveFocusNode.removeListener(_handleFocusChange);
  _focusNode?.dispose();
  super.dispose();
}
```
**Issues**:
- Duplicates FocusNodeMixin logic (80+ lines)
- Doesn't handle focus preservation during swaps
- More complex lifecycle management

**Pattern C: Custom simple management (Popover)**
```dart
// NakedPopover (lines 139-165)
final _internalTriggerNode = FocusNode(debugLabel: 'NakedPopover trigger (internal)');

FocusNode? _extractChildFocusNode() {
  final c = widget.child;
  if (c is Focus) return c.focusNode;
  return null;
}

Widget _buildTrigger(FocusNode returnNode) {
  if (identical(returnNode, _internalTriggerNode)) {
    return Focus(focusNode: _internalTriggerNode, child: child);
  }
  return GestureDetector(onTap: widget.openOnTap ? _toggle : null, child: child);
}

@override
void dispose() {
  _internalTriggerNode.dispose();
  super.dispose();
}
```
**Issues**:
- No listener management
- No focus change callbacks
- Manual node extraction from child tree

### 2.3 Recommended Standard

**Use FocusNodeMixin for ALL components that:**
1. Accept a `FocusNode? focusNode` property
2. Need keyboard interaction
3. Need to track focus state

**Exception cases (don't use mixin):**
1. Components that delegate focus to children (Select, Menu, Tabs, AccordionGroup)
2. Components with no focus concept (Tooltip, Dialog)
3. Components with highly specialized focus needs (keep TextField as is)

### 2.4 Complete Migration Plan

#### Step 1: Migrate simple components to FocusNodeMixin
- NakedCheckbox
- NakedToggle
- NakedToggleOption
- NakedAccordion

#### Step 2: Evaluate TextField
- Keep custom implementation (too specialized, already works well)
- Document why it's different

#### Step 3: Evaluate Popover
- Migrate to FocusNodeMixin OR simplify further
- Current implementation is unusual (extracts child focus node)

### 2.5 Exact Before/After Code

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_checkbox.dart`

**BEFORE (Line 155-156):**
```dart
class _NakedCheckboxState extends State<NakedCheckbox>
    with WidgetStatesMixin<NakedCheckbox> {
```

**AFTER:**
```dart
class _NakedCheckboxState extends State<NakedCheckbox>
    with WidgetStatesMixin<NakedCheckbox>, FocusNodeMixin<NakedCheckbox> {

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;
```

**BEFORE (Lines 260-279):**
```dart
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: NakedFocusableDetector(
        enabled: widget._effectiveEnabled,
        autofocus: widget.autofocus,
        onFocusChange: (focused) {
          updateFocusState(focused, widget.onFocusChange);
        },
        onHoverChange: (hovered) {
          updateHoverState(hovered, widget.onHoverChange);
        },
        focusNode: widget.focusNode,
        mouseCursor: _effectiveCursor,
        shortcuts: NakedIntentActions.checkbox.shortcuts,
        actions: NakedIntentActions.checkbox.actions(
          onToggle: () => _handleKeyboardActivation(),
        ),
        child: _buildCheckbox(),
      ),
    );
  }
```

**AFTER:**
```dart
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: NakedFocusableDetector(
        enabled: widget._effectiveEnabled,
        autofocus: widget.autofocus,
        onFocusChange: (focused) {
          updateFocusState(focused, widget.onFocusChange);
        },
        onHoverChange: (hovered) {
          updateHoverState(hovered, widget.onHoverChange);
        },
        focusNode: effectiveFocusNode,  // ← CHANGE: use mixin's effectiveFocusNode
        mouseCursor: _effectiveCursor,
        shortcuts: NakedIntentActions.checkbox.shortcuts,
        actions: NakedIntentActions.checkbox.actions(
          onToggle: () => _handleKeyboardActivation(),
        ),
        child: _buildCheckbox(),
      ),
    );
  }
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_toggle.dart`

**BEFORE (Line 175-176):**
```dart
class _NakedToggleState extends State<NakedToggle>
    with WidgetStatesMixin<NakedToggle> {
```

**AFTER:**
```dart
class _NakedToggleState extends State<NakedToggle>
    with WidgetStatesMixin<NakedToggle>, FocusNodeMixin<NakedToggle> {

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;
```

**BEFORE (Line 269):**
```dart
        focusNode: widget.focusNode,
```

**AFTER:**
```dart
        focusNode: effectiveFocusNode,  // ← CHANGE
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_toggle.dart` (NakedToggleOption)

**BEFORE (Line 401-402):**
```dart
class _NakedToggleOptionState<T> extends State<NakedToggleOption<T>>
    with WidgetStatesMixin<NakedToggleOption<T>> {
```

**AFTER:**
```dart
class _NakedToggleOptionState<T> extends State<NakedToggleOption<T>>
    with WidgetStatesMixin<NakedToggleOption<T>>, FocusNodeMixin<NakedToggleOption<T>> {

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;
```

**BEFORE (Line 487):**
```dart
        focusNode: widget.focusNode,
```

**AFTER:**
```dart
        focusNode: effectiveFocusNode,  // ← CHANGE
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_accordion.dart`

**BEFORE (Line 462-463):**
```dart
class _NakedAccordionState<T> extends State<NakedAccordion<T>>
    with WidgetStatesMixin<NakedAccordion<T>> {
```

**AFTER:**
```dart
class _NakedAccordionState<T> extends State<NakedAccordion<T>>
    with WidgetStatesMixin<NakedAccordion<T>>, FocusNodeMixin<NakedAccordion<T>> {

  @override
  FocusNode? get widgetProvidedNode => widget.focusNode;
```

**BEFORE (Line 556):**
```dart
              focusNode: widget.focusNode,
```

**AFTER:**
```dart
              focusNode: effectiveFocusNode,  // ← CHANGE
```

### 2.6 Ripple Effects

#### Benefits:
- **Code reduction**: Remove duplicate focus node management logic
- **Consistency**: All focusable components use same pattern
- **Robustness**: Automatic focus preservation during prop changes
- **Maintainability**: Single source of truth for focus node lifecycle

#### Breaking Changes:
- **NONE** - All changes are internal implementation details
- Public API remains identical
- Behavior remains identical (but more robust)

#### Files Affected:
| File | Component | Lines Changed | Type |
|------|-----------|---------------|------|
| `naked_checkbox.dart` | _NakedCheckboxState | ~5 | Add mixin, use effectiveFocusNode |
| `naked_toggle.dart` | _NakedToggleState | ~5 | Add mixin, use effectiveFocusNode |
| `naked_toggle.dart` | _NakedToggleOptionState | ~5 | Add mixin, use effectiveFocusNode |
| `naked_accordion.dart` | _NakedAccordionState | ~5 | Add mixin, use effectiveFocusNode |

### 2.7 Task Breakdown

| Task | Estimated Time | Dependencies | Priority |
|------|----------------|--------------|----------|
| Add FocusNodeMixin to NakedCheckbox | 15 min | None | High |
| Add FocusNodeMixin to NakedToggle | 15 min | None | High |
| Add FocusNodeMixin to NakedToggleOption | 15 min | None | High |
| Add FocusNodeMixin to NakedAccordion | 15 min | None | High |
| Document TextField exception | 15 min | None | Medium |
| Update component architecture docs | 30 min | Above tasks | Medium |
| Write tests for focus node swapping | 60 min | Above tasks | High |
| Manual testing of focus behavior | 45 min | Above tasks | High |
| Code review | 30 min | All above | High |

**Total Estimated Time:** 4 hours

### 2.8 Validation Checklist

- [ ] All appropriate components use FocusNodeMixin
- [ ] No component duplicates FocusNodeMixin logic
- [ ] Focus node disposal is automatic and consistent
- [ ] Focus is preserved when switching between external/internal nodes
- [ ] All tests pass
- [ ] Manual testing of focus behavior for:
  - [ ] NakedCheckbox - focus with/without external node
  - [ ] NakedToggle - focus with/without external node
  - [ ] NakedToggleOption - focus in group context
  - [ ] NakedAccordion - focus on trigger
- [ ] Test focus node swapping (change focusNode prop at runtime)
- [ ] Test focus listeners fire correctly
- [ ] Test autofocus behavior unchanged
- [ ] Documentation updated for architecture
- [ ] No regressions in existing functionality

---

## Issue 3: MouseCursor Default Value Inconsistency

### 3.1 Current State Audit

#### Components with MouseCursor property:

| Component | File | Property Type | Default Value | Line |
|-----------|------|---------------|---------------|------|
| NakedButton | naked_button.dart | `MouseCursor` | `SystemMouseCursors.click` | 48 |
| NakedCheckbox | naked_checkbox.dart | `MouseCursor?` | `null` | 82 |
| NakedRadio | naked_radio.dart | `MouseCursor?` | `null` | 62 |
| NakedToggle | naked_toggle.dart | `MouseCursor?` | `null` | 106 |
| NakedToggleOption | naked_toggle.dart | `MouseCursor?` | `null` | 365 |
| NakedSlider | naked_slider.dart | `MouseCursor` | `SystemMouseCursors.click` | 111 |
| NakedTab | naked_tabs.dart | `MouseCursor` | `SystemMouseCursors.click` | 272 |
| NakedAccordion | naked_accordion.dart | `MouseCursor` | `SystemMouseCursors.click` | 404 |

#### Components WITHOUT MouseCursor property:
| Component | File | Reason |
|-----------|------|--------|
| NakedSelect | naked_select.dart | Uses NakedButton internally |
| NakedMenu | naked_menu.dart | Uses NakedButton internally |
| NakedTextField | naked_textfield.dart | Always uses `SystemMouseCursors.text` (line 827) |
| NakedPopover | naked_popover.dart | Simple tap target, no cursor customization |
| NakedTooltip | naked_tooltip.dart | Hover-only, no cursor customization |
| NakedDialog | naked_dialog.dart | Modal, no direct cursor control |
| NakedTabs | naked_tabs.dart | Container, items control cursor |
| NakedAccordionGroup | naked_accordion.dart | Container, items control cursor |

#### Current Resolution Patterns:

**Pattern A: Non-nullable with default (Button, Slider, Tab, Accordion)**
```dart
final MouseCursor mouseCursor = SystemMouseCursors.click;

// Usage in build:
mouseCursor: widget.enabled ? widget.mouseCursor : SystemMouseCursors.basic,
```

**Pattern B: Nullable with fallback (Checkbox, Radio, Toggle, ToggleOption)**
```dart
final MouseCursor? mouseCursor;

// Usage in build:
MouseCursor get _effectiveCursor => widget.enabled
    ? (widget.mouseCursor ?? SystemMouseCursors.click)
    : SystemMouseCursors.basic;
```

**Pattern C: Hardcoded (TextField)**
```dart
// No property, always uses SystemMouseCursors.text
final Widget maybeMouseRegion = widget.enabled
    ? MouseRegion(
        cursor: SystemMouseCursors.text,
        child: detector,
      )
    : detector;
```

### 3.2 Consistency Analysis

#### Current State Matrix:

| Component | Nullable? | Default | Fallback when null | Disabled cursor |
|-----------|-----------|---------|-------------------|-----------------|
| NakedButton | No | `.click` | N/A | `.basic` |
| NakedCheckbox | Yes | null | `.click` | `.basic` |
| NakedRadio | Yes | null | `.click` | `.basic` |
| NakedToggle | Yes | null | `.click` | `.basic` |
| NakedToggleOption | Yes | null | `.click` | `.basic` |
| NakedSlider | No | `.click` | N/A | `.basic` |
| NakedTab | No | `.click` | N/A | `.basic` |
| NakedAccordion | No | `.click` | N/A | `.basic` |
| NakedTextField | N/A | `.text` | N/A | Hidden |

#### Issues Identified:

1. **Inconsistent nullability**: 5 components use nullable, 4 use non-nullable
2. **Default value variation**: All interactive use `.click` or fallback to it (except TextField which correctly uses `.text`)
3. **Pattern complexity**: Nullable pattern requires getter/fallback logic
4. **Semantic clarity**: "Click" cursor is correct for buttons/toggles/tabs but less clear for sliders

### 3.3 Recommended Standard

#### For Button-like Components (tap activation):
```dart
/// The mouse cursor for pointer devices.
///
/// Defaults to [SystemMouseCursors.click] when enabled.
final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**Components**: Button, Checkbox, Radio, Toggle, ToggleOption, Tab, Accordion

**Reasoning**:
- Non-nullable is simpler (no null checks needed)
- Explicit default is clear and documented
- Less code than nullable + fallback pattern
- Users can still override if needed

#### For Drag/Slider Components:
```dart
/// The mouse cursor for pointer devices.
///
/// Defaults to [SystemMouseCursors.click] when enabled.
final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**Components**: Slider

**Reasoning**:
- Keep as is - `.click` is reasonable for draggable handles
- Alternatively could use `.grab`/`.grabbing` but that's more complex
- Consistency with button-like components is valuable

#### For Text Input:
```dart
// No property - always SystemMouseCursors.text (hardcoded)
```

**Components**: TextField

**Reasoning**:
- Text fields should always show text cursor
- No need for customization property
- Keep current implementation

### 3.4 Complete Migration Plan

#### Step 1: Convert nullable → non-nullable with default
- NakedCheckbox: Change `MouseCursor?` → `MouseCursor`, add default `.click`
- NakedRadio: Change `MouseCursor?` → `MouseCursor`, add default `.click`
- NakedToggle: Change `MouseCursor?` → `MouseCursor`, add default `.click`
- NakedToggleOption: Change `MouseCursor?` → `MouseCursor`, add default `.click`

#### Step 2: Remove fallback getters
- Remove `_effectiveCursor` getters in above components
- Use `widget.mouseCursor` directly with enabled check

#### Step 3: Update documentation
- Document cursor behavior when enabled/disabled
- Add examples showing cursor customization

### 3.5 Exact Before/After Code

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_checkbox.dart`

**BEFORE (Lines 82, 126-127):**
```dart
  /// The mouse cursor for the checkbox.
  final MouseCursor? mouseCursor;
```

**AFTER:**
```dart
  /// The mouse cursor for pointer devices.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**BEFORE (Lines 237-239):**
```dart
  MouseCursor get _effectiveCursor => widget._effectiveEnabled
      ? (widget.mouseCursor ?? SystemMouseCursors.click)
      : SystemMouseCursors.basic;
```

**AFTER (remove this getter entirely):**
```dart
// Remove getter - use inline logic instead
```

**BEFORE (Line 272):**
```dart
        mouseCursor: _effectiveCursor,
```

**AFTER:**
```dart
        mouseCursor: widget._effectiveEnabled
            ? widget.mouseCursor
            : SystemMouseCursors.basic,
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_radio.dart`

**BEFORE (Lines 62, 85-86):**
```dart
  /// The mouse cursor when hovering.
  final MouseCursor? mouseCursor;
```

**AFTER:**
```dart
  /// The mouse cursor for pointer devices.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**BEFORE (Lines 151-153):**
```dart
    final effectiveCursor =
        widget.mouseCursor ??
        (widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic);
```

**AFTER:**
```dart
    final effectiveCursor = widget.enabled
        ? widget.mouseCursor
        : SystemMouseCursors.basic;
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_toggle.dart`

**BEFORE (Lines 106, 133-135):**
```dart
  /// The mouse cursor when interactive.
  final MouseCursor? mouseCursor;
```

**AFTER:**
```dart
  /// The mouse cursor for pointer devices.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**BEFORE (Lines 233-235):**
```dart
  MouseCursor get _effectiveCursor => widget._effectiveEnabled
      ? (widget.mouseCursor ?? SystemMouseCursors.click)
      : SystemMouseCursors.basic;
```

**AFTER (remove this getter entirely):**
```dart
// Remove getter - use inline logic instead
```

**BEFORE (Line 270):**
```dart
      mouseCursor: _effectiveCursor,
```

**AFTER:**
```dart
      mouseCursor: widget._effectiveEnabled
          ? widget.mouseCursor
          : SystemMouseCursors.basic,
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_toggle.dart` (NakedToggleOption)

**BEFORE (Lines 365, 382):**
```dart
  final MouseCursor? mouseCursor;
```

**AFTER:**
```dart
  /// The mouse cursor for pointer devices.
  ///
  /// Defaults to [SystemMouseCursors.click] when enabled.
  final MouseCursor mouseCursor = SystemMouseCursors.click;
```

**BEFORE (Lines 450-452):**
```dart
    final cursor = isEnabled
        ? (widget.mouseCursor ?? SystemMouseCursors.click)
        : SystemMouseCursors.basic;
```

**AFTER:**
```dart
    final cursor = isEnabled
        ? widget.mouseCursor
        : SystemMouseCursors.basic;
```

### 3.6 Ripple Effects

#### Breaking Changes:
- **MINOR BREAKING**: Changing `MouseCursor?` to `MouseCursor` with default
  - Previous code: `mouseCursor: null` (explicit) will now be an error
  - Previous code: no property specified (default null) now defaults to `.click`

  **Migration**:
  ```dart
  // Before (explicit null):
  NakedCheckbox(mouseCursor: null)

  // After (use default or specify):
  NakedCheckbox() // Uses .click by default
  // OR
  NakedCheckbox(mouseCursor: SystemMouseCursors.basic) // Custom
  ```

#### Benefits:
- Simpler API - no need to handle null
- More explicit defaults in documentation
- Less code (no fallback getters)
- Consistent pattern across all components

#### Files Affected:
| File | Component | Lines Changed | Type |
|------|-----------|---------------|------|
| `naked_checkbox.dart` | NakedCheckbox | ~10 | Property type, remove getter, update usage |
| `naked_radio.dart` | NakedRadio | ~5 | Property type, update usage |
| `naked_toggle.dart` | NakedToggle | ~10 | Property type, remove getter, update usage |
| `naked_toggle.dart` | NakedToggleOption | ~5 | Property type, update usage |

### 3.7 Task Breakdown

| Task | Estimated Time | Dependencies | Priority |
|------|----------------|--------------|----------|
| Convert NakedCheckbox | 15 min | None | High |
| Convert NakedRadio | 10 min | None | High |
| Convert NakedToggle | 15 min | None | High |
| Convert NakedToggleOption | 10 min | None | High |
| Update API documentation | 30 min | Above tasks | High |
| Update migration guide | 30 min | Above tasks | High |
| Update examples | 30 min | Above tasks | Medium |
| Write cursor tests | 45 min | Above tasks | High |
| Manual testing | 30 min | Above tasks | High |
| Code review | 30 min | All above | High |

**Total Estimated Time:** 4 hours

### 3.8 Validation Checklist

- [ ] All interactive components use non-nullable `MouseCursor` with `.click` default
- [ ] No components use nullable `MouseCursor?`
- [ ] No fallback getters exist (e.g., `_effectiveCursor`)
- [ ] TextField still uses `.text` cursor (unchanged)
- [ ] All components show `.basic` cursor when disabled
- [ ] All tests pass
- [ ] Manual testing of cursor changes for:
  - [ ] NakedCheckbox - hover shows click cursor
  - [ ] NakedRadio - hover shows click cursor
  - [ ] NakedToggle - hover shows click cursor
  - [ ] NakedToggleOption - hover shows click cursor
  - [ ] All above - disabled shows basic cursor
- [ ] Custom cursor values work (e.g., `mouseCursor: SystemMouseCursors.help`)
- [ ] Migration guide includes cursor changes
- [ ] API docs updated for all affected components
- [ ] No regressions in existing functionality

---

## Issue 4: MenuController Disposal Issues

### 4.1 Current State Audit

#### MenuController Usage Across Components:

| Component | File | Lines | Creation | Disposal | Issue? |
|-----------|------|-------|----------|----------|--------|
| **NakedSelect** | naked_select.dart | 287 | `late final MenuController _menuController;` | ❌ **NOT disposed** | ⚠️ **MEMORY LEAK** |
| **NakedMenu** | naked_menu.dart | 204 | `required this.controller` (widget prop) | ✅ User-owned | ✓ Correct |
| **NakedPopover** | naked_popover.dart | 135 | `late final _menuController = widget.controller ?? MenuController();` | ❌ **NOT disposed** | ⚠️ **MEMORY LEAK** |
| **NakedTooltip** | naked_tooltip.dart | 157 | `final _menuController = MenuController();` | ❌ **NOT disposed** | ⚠️ **MEMORY LEAK** |

#### Detailed Analysis:

**1. NakedSelect (naked_select.dart, line 287)**
```dart
class _NakedSelectState<T> extends State<NakedSelect<T>>
    with OverlayStateMixin<NakedSelect<T>> {
  // ignore: dispose-fields
  late final MenuController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();  // Created
    // ...
  }

  // NO DISPOSE METHOD! ❌
}
```

**Issue**: `MenuController` is created but never disposed. The `// ignore: dispose-fields` comment suppresses the lint warning but doesn't fix the leak.

**2. NakedMenu (naked_menu.dart, line 204)**
```dart
class NakedMenu<T> extends StatefulWidget {
  const NakedMenu({
    // ...
    required this.controller,  // User provides controller
  });

  /// Controls show/hide of the underlying [RawMenuAnchor]
  final MenuController controller;
}
```

**Status**: ✅ Correct - Controller is owned by user, they dispose it.

**3. NakedPopover (naked_popover.dart, line 135)**
```dart
class _NakedPopoverState extends State<NakedPopover> {
  // ignore: dispose-fields
  late final _menuController = widget.controller ?? MenuController();

  // ...

  @override
  void dispose() {
    _statesController.dispose();
    _internalTriggerNode.dispose();
    super.dispose();  // ❌ _menuController NOT disposed!
  }
}
```

**Issue**: Creates controller conditionally, but never disposes it. If `widget.controller` is null, we create one and leak it.

**4. NakedTooltip (naked_tooltip.dart, line 157)**
```dart
class _NakedTooltipState extends State<NakedTooltip>
    with WidgetStatesMixin<NakedTooltip> {
  // ignore: dispose-fields
  final _menuController = MenuController();

  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();  // ❌ _menuController NOT disposed!
  }
}
```

**Issue**: Creates controller but never disposes it.

#### MenuController Implementation (from Flutter):

```dart
// From flutter/lib/src/material/menu_anchor.dart
class MenuController extends ChangeNotifier {
  bool _isOpen = false;

  void open() {
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Disposes listeners
    super.dispose();
  }
}
```

Since `MenuController extends ChangeNotifier`, it **MUST** be disposed to:
1. Remove all listeners (prevents listener leaks)
2. Prevent notifications after disposal (avoids crashes)
3. Free resources

### 4.2 Consistency Analysis

#### Disposal Patterns:

**Pattern A: Always create, always dispose (Correct pattern)**
```dart
late final _controller = SomeController();

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```
✅ Used by: NakedTextField (`_controller`), NakedPopover (`_statesController`, `_internalTriggerNode`)

**Pattern B: User-provided, never dispose (Correct pattern)**
```dart
final SomeController controller; // From widget props

// No disposal - user owns it
```
✅ Used by: NakedMenu

**Pattern C: Conditionally create, conditionally dispose (Needed pattern)**
```dart
late final _controller = widget.controller ?? SomeController();

@override
void dispose() {
  // Only dispose if we created it
  if (widget.controller == null) {
    _controller.dispose();
  }
  super.dispose();
}
```
❌ **MISSING**: Should be used by NakedPopover but isn't!

**Pattern D: Always create, never dispose (WRONG - current state)**
```dart
late final _controller = SomeController();

// NO dispose() ❌
```
❌ Used by: NakedSelect, NakedTooltip
❌ Partially used by: NakedPopover (creates conditionally but never disposes)

### 4.3 Recommended Standard

#### For Components That Create Controllers:

**Rule 1**: If you create it, you dispose it.
```dart
late final _internalController = MenuController();

@override
void dispose() {
  _internalController.dispose();
  super.dispose();
}
```

**Rule 2**: If user can provide it optionally, track ownership.
```dart
MenuController? _internalController;

MenuController get _effectiveController =>
    widget.controller ?? _internalController!;

@override
void initState() {
  super.initState();
  if (widget.controller == null) {
    _internalController = MenuController();
  }
}

@override
void dispose() {
  _internalController?.dispose(); // Only dispose if we created it
  super.dispose();
}
```

**Rule 3**: If user always provides it, never dispose it.
```dart
final MenuController controller; // From widget

// No disposal
```

### 4.4 Complete Migration Plan

#### Step 1: Add disposal to NakedSelect
- Create `dispose()` method
- Call `_menuController.dispose()`

#### Step 2: Add conditional disposal to NakedPopover
- Track whether we created the controller
- Only dispose if we created it

#### Step 3: Add disposal to NakedTooltip
- Create `dispose()` method (already exists, just add controller disposal)
- Call `_menuController.dispose()`

#### Step 4: Remove lint ignore comments
- Remove all `// ignore: dispose-fields` comments
- Fix should silence the warnings naturally

### 4.5 Exact Before/After Code

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_select.dart`

**BEFORE (Lines 284-295):**
```dart
class _NakedSelectState<T> extends State<NakedSelect<T>>
    with OverlayStateMixin<NakedSelect<T>> {
  // ignore: dispose-fields
  late final MenuController _menuController;
  T? _internalValue;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _internalValue = widget.value;
  }
```

**AFTER:**
```dart
class _NakedSelectState<T> extends State<NakedSelect<T>>
    with OverlayStateMixin<NakedSelect<T>> {
  late final MenuController _menuController;  // ← REMOVE ignore comment
  T? _internalValue;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _internalValue = widget.value;
  }
```

**BEFORE (no dispose method exists):**
```dart
  // No dispose() method ❌
}
```

**AFTER (add after didUpdateWidget, around line 328):**
```dart
  @override
  void didUpdateWidget(covariant NakedSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _internalValue = widget.value;
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  bool get _isOpen => _menuController.isOpen;
```

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_popover.dart`

**BEFORE (Lines 133-136):**
```dart
class _NakedPopoverState extends State<NakedPopover> {
  // ignore: dispose-fields
  late final _menuController = widget.controller ?? MenuController();
  late final _statesController = WidgetStatesController();
```

**AFTER:**
```dart
class _NakedPopoverState extends State<NakedPopover> {
  MenuController? _internalMenuController;
  late final _statesController = WidgetStatesController();

  MenuController get _menuController =>
      widget.controller ?? _internalMenuController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }
  }
```

**BEFORE (Lines 206-211):**
```dart
  @override
  void dispose() {
    _statesController.dispose();
    _internalTriggerNode.dispose();
    super.dispose();
  }
```

**AFTER:**
```dart
  @override
  void dispose() {
    _internalMenuController?.dispose();
    _statesController.dispose();
    _internalTriggerNode.dispose();
    super.dispose();
  }
```

**Also update all references to use `_menuController` (getter) instead of direct field access:**
- Line 144: `if (_menuController.isOpen) {` ← Already uses `_menuController`, no change
- Line 147: `_menuController.open();` ← Already uses `_menuController`, no change
- Line 168: `isOpen: _menuController.isOpen,` ← Already uses `_menuController`, no change
- Line 228: `controller: _menuController,` ← Already uses `_menuController`, no change
- Line 234: `onTapOutside: (event) => _menuController.close(),` ← Already uses `_menuController`, no change
- Line 241: `onDismiss: () => _menuController.close(),` ← Already uses `_menuController`, no change

Good news: All references already use `_menuController` so they'll automatically work with the getter!

#### File: `/home/user/naked_ui/packages/naked_ui/lib/src/naked_tooltip.dart`

**BEFORE (Lines 154-160):**
```dart
class _NakedTooltipState extends State<NakedTooltip>
    with WidgetStatesMixin<NakedTooltip> {
  // ignore: dispose-fields
  final _menuController = MenuController();
  Timer? _showTimer;
  Timer? _waitTimer;
```

**AFTER:**
```dart
class _NakedTooltipState extends State<NakedTooltip>
    with WidgetStatesMixin<NakedTooltip> {
  final _menuController = MenuController();  // ← REMOVE ignore comment
  Timer? _showTimer;
  Timer? _waitTimer;
```

**BEFORE (Lines 185-190):**
```dart
  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }
```

**AFTER:**
```dart
  @override
  void dispose() {
    _showTimer?.cancel();
    _waitTimer?.cancel();
    _menuController.dispose();  // ← ADD THIS
    super.dispose();
  }
```

### 4.6 Ripple Effects

#### Breaking Changes:
- **NONE** - All changes are internal implementation details
- Public API remains identical
- Behavior remains identical

#### Benefits:
- **Memory leak fix**: Controllers are properly disposed
- **Crash prevention**: No notifications after disposal
- **Resource cleanup**: Listeners are properly removed
- **Lint compliance**: No more ignore comments needed

#### Files Affected:
| File | Component | Lines Changed | Type |
|------|-----------|---------------|------|
| `naked_select.dart` | _NakedSelectState | ~8 | Remove ignore, add dispose() |
| `naked_popover.dart` | _NakedPopoverState | ~15 | Conditional creation + disposal |
| `naked_tooltip.dart` | _NakedTooltipState | ~3 | Remove ignore, add disposal |

### 4.7 Task Breakdown

| Task | Estimated Time | Dependencies | Priority |
|------|----------------|--------------|----------|
| Fix NakedSelect disposal | 15 min | None | **CRITICAL** |
| Fix NakedPopover disposal | 30 min | None | **CRITICAL** |
| Fix NakedTooltip disposal | 10 min | None | **CRITICAL** |
| Remove all ignore comments | 5 min | Above tasks | High |
| Write disposal tests | 60 min | Above tasks | High |
| Memory leak testing | 30 min | Above tasks | High |
| Code review | 20 min | All above | High |

**Total Estimated Time:** 2.5 hours

### 4.8 Validation Checklist

- [ ] All created MenuControllers are disposed
- [ ] No `// ignore: dispose-fields` comments remain
- [ ] Conditional creation (Popover) properly tracks ownership
- [ ] All tests pass
- [ ] Memory leak testing:
  - [ ] Create/dispose NakedSelect 1000x - no memory growth
  - [ ] Create/dispose NakedPopover 1000x - no memory growth (both with and without controller prop)
  - [ ] Create/dispose NakedTooltip 1000x - no memory growth
- [ ] No crashes when widgets are disposed
- [ ] Overlays properly close when widgets are disposed
- [ ] Flutter DevTools shows no leaked controllers
- [ ] Lint passes with no warnings
- [ ] No regressions in existing functionality

---

## Implementation Order

The four issues can be addressed in parallel or in this suggested sequence:

### Phase 1: Critical Fixes (Week 1)
1. **Issue 4: MenuController Disposal** (CRITICAL - memory leaks)
   - Estimated: 2.5 hours
   - Risk: Low (internal only)
   - Impact: High (prevents memory leaks)

### Phase 2: Robustness Improvements (Week 1-2)
2. **Issue 2: FocusNode Management Consistency**
   - Estimated: 4 hours
   - Risk: Low (internal only)
   - Impact: High (reduces code duplication, improves robustness)

### Phase 3: API Consistency (Week 2)
3. **Issue 3: MouseCursor Default Values**
   - Estimated: 4 hours
   - Risk: Low (minor breaking change)
   - Impact: Medium (improved API consistency)

4. **Issue 1: Enabled State Property Naming**
   - Estimated: 4 hours
   - Risk: Low (one minor API addition)
   - Impact: Medium (improved consistency)

**Total Estimated Time:** 14.5 hours (~2 weeks part-time)

---

## Testing Strategy

### Unit Tests

#### Issue 1 (Enabled State):
```dart
testWidgets('NakedMenu respects enabled property', (tester) async {
  final controller = MenuController();
  var tapCount = 0;

  await tester.pumpWidget(
    NakedMenu(
      controller: controller,
      enabled: false,
      onSelected: (_) => tapCount++,
      overlayBuilder: (context, info) => Text('Items'),
      child: Text('Trigger'),
    ),
  );

  await tester.tap(find.text('Trigger'));
  await tester.pump();

  expect(controller.isOpen, false); // Should not open when disabled
  expect(tapCount, 0);
});
```

#### Issue 2 (FocusNode Mixin):
```dart
testWidgets('NakedCheckbox creates internal focus node', (tester) async {
  await tester.pumpWidget(
    NakedCheckbox(
      value: false,
      onChanged: (_) {},
      child: Text('Checkbox'),
    ),
  );

  final element = tester.element(find.byType(NakedCheckbox));
  final state = element as _NakedCheckboxState;

  expect(state.effectiveFocusNode, isNotNull);
});

testWidgets('NakedCheckbox uses provided focus node', (tester) async {
  final focusNode = FocusNode();

  await tester.pumpWidget(
    NakedCheckbox(
      value: false,
      focusNode: focusNode,
      onChanged: (_) {},
      child: Text('Checkbox'),
    ),
  );

  final element = tester.element(find.byType(NakedCheckbox));
  final state = element as _NakedCheckboxState;

  expect(state.effectiveFocusNode, same(focusNode));
});

testWidgets('NakedCheckbox preserves focus during node swap', (tester) async {
  FocusNode? focusNode;

  await tester.pumpWidget(
    StatefulBuilder(
      builder: (context, setState) {
        return NakedCheckbox(
          value: false,
          focusNode: focusNode,
          onChanged: (_) {},
          child: GestureDetector(
            onTap: () => setState(() {
              focusNode = FocusNode();
            }),
            child: Text('Checkbox'),
          ),
        );
      },
    ),
  );

  // Focus the checkbox
  await tester.tap(find.text('Checkbox'));
  await tester.pump();

  final element = tester.element(find.byType(NakedCheckbox));
  final state = element as _NakedCheckboxState;

  expect(state.effectiveFocusNode.hasFocus, true);

  // Trigger focus node swap
  await tester.tap(find.text('Checkbox'));
  await tester.pump();
  await tester.pump(); // Wait for post-frame callback

  expect(state.effectiveFocusNode.hasFocus, true); // Focus preserved!
});
```

#### Issue 3 (MouseCursor):
```dart
testWidgets('NakedCheckbox shows click cursor by default', (tester) async {
  await tester.pumpWidget(
    NakedCheckbox(
      value: false,
      onChanged: (_) {},
      child: Text('Checkbox'),
    ),
  );

  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);

  await tester.pump();

  expect(
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
    SystemMouseCursors.click,
  );
});

testWidgets('NakedCheckbox shows basic cursor when disabled', (tester) async {
  await tester.pumpWidget(
    NakedCheckbox(
      value: false,
      enabled: false,
      child: Text('Checkbox'),
    ),
  );

  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);

  await tester.pump();

  expect(
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
    SystemMouseCursors.basic,
  );
});
```

#### Issue 4 (MenuController Disposal):
```dart
testWidgets('NakedSelect disposes internal controller', (tester) async {
  late MenuController controller;

  await tester.pumpWidget(
    StatefulBuilder(
      builder: (context, setState) {
        return NakedSelect<String>(
          overlayBuilder: (context, info) => Text('Items'),
          child: Builder(
            builder: (context) {
              controller = context
                  .findAncestorStateOfType<_NakedSelectState>()!
                  ._menuController;
              return Text('Trigger');
            },
          ),
        );
      },
    ),
  );

  await tester.pumpWidget(Container()); // Dispose widget

  expect(() => controller.isOpen, throwsFlutterError); // Should be disposed
});

testWidgets('NakedPopover does not dispose external controller', (tester) async {
  final controller = MenuController();

  await tester.pumpWidget(
    NakedPopover(
      controller: controller,
      popoverBuilder: (context, info) => Text('Content'),
      child: Text('Trigger'),
    ),
  );

  await tester.pumpWidget(Container()); // Dispose widget

  expect(() => controller.isOpen, returnsNormally); // Still valid
  controller.dispose(); // User cleans up
});

testWidgets('NakedTooltip disposes internal controller', (tester) async {
  late MenuController controller;

  await tester.pumpWidget(
    NakedTooltip(
      overlayBuilder: (context, info) => Text('Tooltip'),
      child: Builder(
        builder: (context) {
          controller = context
              .findAncestorStateOfType<_NakedTooltipState>()!
              ._menuController;
          return Text('Hover me');
        },
      ),
    ),
  );

  await tester.pumpWidget(Container()); // Dispose widget

  expect(() => controller.isOpen, throwsFlutterError); // Should be disposed
});
```

### Memory Leak Tests

```dart
// Run with: flutter test --track-widget-creation
testWidgets('NakedSelect does not leak memory', (tester) async {
  for (int i = 0; i < 1000; i++) {
    await tester.pumpWidget(
      NakedSelect<String>(
        overlayBuilder: (context, info) => Text('Items'),
        child: Text('Select $i'),
      ),
    );

    await tester.pumpWidget(Container());
  }

  // Use DevTools or memory profiler to verify no MenuController leaks
});
```

### Integration Tests

```dart
testWidgets('Full workflow: enabled, focus, cursor, disposal', (tester) async {
  final focusNode = FocusNode();
  var checked = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return NakedCheckbox(
              value: checked,
              enabled: true,
              focusNode: focusNode,
              mouseCursor: SystemMouseCursors.help,
              onChanged: (value) => setState(() => checked = value!),
              child: Text('Checkbox'),
            );
          },
        ),
      ),
    ),
  );

  // Test cursor
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: tester.getCenter(find.text('Checkbox')));
  await tester.pump();
  expect(
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
    SystemMouseCursors.help, // Custom cursor works
  );

  // Test focus
  focusNode.requestFocus();
  await tester.pump();
  expect(focusNode.hasFocus, true);

  // Test interaction
  await tester.tap(find.text('Checkbox'));
  await tester.pump();
  expect(checked, true);

  // Dispose and verify cleanup
  await tester.pumpWidget(Container());
  expect(() => focusNode.hasFocus, throwsFlutterError); // Disposed

  await gesture.removePointer();
});
```

---

## Summary

This architectural plan provides a comprehensive roadmap for addressing all four Phase 2 medium-priority issues:

1. **Enabled State Consistency**: Standardize on `enabled` property and `_effectiveEnabled` pattern
2. **FocusNode Management**: Adopt FocusNodeMixin for all appropriate components
3. **MouseCursor Defaults**: Standardize on non-nullable with explicit `.click` default
4. **MenuController Disposal**: Fix critical memory leaks in 3 components

**Total effort**: ~14.5 hours over 2 weeks
**Risk level**: Low (mostly internal changes)
**Impact**: High (improved consistency, robustness, and resource management)

All issues have detailed migration plans, exact code changes, and comprehensive testing strategies to ensure a smooth transition with no regressions.
