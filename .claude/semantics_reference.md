# Flutter Headless Widgets — Complete Semantics Guide (v2)

A production-ready, API-accurate reference for implementing accessibility semantics in headless Flutter component libraries. This guide provides correct, tested patterns for all common UI components.

> **Version 2 Updates:**
> - Added FocusableActionDetector patterns
> - Critical GestureDetector exclusion rule
> - Dual implementation variants (basic & focusable)
> - Expanded testing and debugging sections

## Table of Contents
- [Critical Rules](#critical-rules)
- [Core Principles](#core-principles)
- [Focus Management Strategies](#focus-management-strategies)
- [Component Implementations](#component-implementations)
- [Testing & Debugging](#testing--debugging)
- [Common Pitfalls](#common-pitfalls)
- [References](#references)

---

## Critical Rules

### 🚨 Rule 1: Always Exclude GestureDetectors from Semantics

**Whenever you provide explicit Semantics with action handlers, ALWAYS set `excludeFromSemantics: true` on GestureDetector, InkWell, or similar widgets.**

```dart
// ✅ CORRECT
Semantics(
  onTap: onPressed,
  child: GestureDetector(
    onTap: onPressed,
    excludeFromSemantics: true,  // CRITICAL!
    child: child,
  ),
)

// ❌ WRONG - Creates duplicate semantic actions
Semantics(
  onTap: onPressed,
  child: GestureDetector(
    onTap: onPressed,  // Missing excludeFromSemantics!
    child: child,
  ),
)
```

### 🚨 Rule 2: Semantics Inside FocusableActionDetector

When using FocusableActionDetector, place Semantics INSIDE it, not around it.

```dart
// ✅ CORRECT
FocusableActionDetector(
  includeFocusSemantics: true,
  child: Semantics(
    button: true,
    label: label,
    child: child,
  ),
)

// ❌ WRONG
Semantics(
  child: FocusableActionDetector(  // Focus semantics get buried
    child: child,
  ),
)
```

### 🚨 Rule 3: Prefer MergeSemantics Over excludeSemantics

Use `MergeSemantics` to combine label + control semantics rather than excluding child semantics entirely.

### 🚨 Rule 4: Never Expose Obscured Values

For password fields, set `obscured: true` AND `value: null` to prevent leaking sensitive text.

---

## Core Principles

### Semantic Properties Reference

| Property | Use Case | Mutually Exclusive With |
|----------|----------|-------------------------|
| `checked` | Checkbox state | `toggled`, `mixed` (when null) |
| `toggled` | Switch state | `checked`, `mixed` |
| `mixed` | Tristate checkbox (null state) | - |
| `button` | Clickable elements | - |
| `focused` | Current focus state | - |
| `focusable` | Can receive focus | - |
| `enabled` | Interactive state | - |
| `container` | Semantic boundary | - |
| `scopesRoute` | Dialog/modal scope | - |
| `namesRoute` | Route naming | - |

### Container Semantics

Use `container: true` to create a dedicated node in the semantics tree:
- Prevents odd merges with parent/sibling semantics
- Improves hit testing for assistive technologies
- Required for composite widgets (e.g., button with icon + label)

---

## Focus Management Strategies

### When to Use FocusableActionDetector

Use FocusableActionDetector when you need:
- ✅ Keyboard shortcuts and actions
- ✅ Hover detection and visual feedback
- ✅ Focus highlight visualization
- ✅ Complex interaction patterns
- ✅ Mouse cursor changes

### When to Use Basic Focus Widget

Use basic Focus widget when you need:
- ✅ Simple focus management only
- ✅ Minimal overhead
- ✅ No hover or keyboard shortcuts
- ✅ Just focus traversal

### FocusableActionDetector Semantics

```dart
FocusableActionDetector(
  includeFocusSemantics: true,    // Default, provides focusable/focused
  includeFocusSemantics: false,   // When you want full control
)
```

With `includeFocusSemantics: true` (default), it automatically provides:
- `focusable` property based on enabled state
- `focused` property based on current focus state

---

## Component Implementations

For each component, we provide two variants:
1. **Basic**: Using Focus widget or no focus management
2. **With FocusableActionDetector**: For rich keyboard/hover interactions

---

### Button

#### Basic Implementation
```dart
return Semantics(
  container: true,
  button: true,
  enabled: onPressed != null,
  label: semanticLabel,
  tooltip: tooltip,
  focusable: onPressed != null,
  focused: focusNode?.hasFocus == true,
  onTap: onPressed,
  onLongPress: onLongPress,
  child: GestureDetector(
    onTap: onPressed,
    onLongPress: onLongPress,
    excludeFromSemantics: true,  // Critical!
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

#### With FocusableActionDetector
```dart
return FocusableActionDetector(
  focusNode: focusNode,
  enabled: onPressed != null,
  onShowFocusHighlight: (highlight) => // Update visual state
  onShowHoverHighlight: (highlight) => // Update visual state
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
  },
  actions: {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => onPressed?.call(),
    ),
  },
  child: Semantics(
    container: true,
    button: true,
    enabled: onPressed != null,
    label: semanticLabel,
    tooltip: tooltip,
    onTap: onPressed,
    onLongPress: onLongPress,
    child: GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      excludeFromSemantics: true,
      child: child,
    ),
  ),
);
```

**Key Points:**
- `container: true` for composite buttons
- FocusableActionDetector handles `focusable`/`focused` automatically
- GestureDetector always excluded from semantics

---

### Checkbox (Tristate Aware)

#### Basic Implementation
```dart
return MergeSemantics(
  child: Semantics(
    container: true,
    checked: value == true,  // false when null for tristate
    mixed: tristate && value == null,  // true only for indeterminate
    enabled: onChanged != null,
    label: semanticLabel,
    onTap: onChanged != null ? () => _toggleValue() : null,
    focusable: onChanged != null,
    focused: focusNode?.hasFocus == true,
    child: GestureDetector(
      onTap: onChanged != null ? () => _toggleValue() : null,
      excludeFromSemantics: true,
      child: Focus(
        focusNode: focusNode,
        child: child,
      ),
    ),
  ),
);

void _toggleValue() {
  if (tristate) {
    // false -> true -> null -> false
    final newValue = value == false ? true : 
                     value == true ? null : false;
    onChanged?.call(newValue);
  } else {
    onChanged?.call(!value);
  }
}
```

#### With FocusableActionDetector
```dart
return MergeSemantics(
  child: FocusableActionDetector(
    focusNode: focusNode,
    enabled: onChanged != null,
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          _toggleValue();
          return null;
        },
      ),
    },
    child: Semantics(
      container: true,
      checked: value == true,
      mixed: tristate && value == null,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged != null ? () => _toggleValue() : null,
      child: GestureDetector(
        onTap: onChanged != null ? () => _toggleValue() : null,
        excludeFromSemantics: true,
        child: child,
      ),
    ),
  ),
);
```

**Key Points:**
- `checked: value == true` (not just `value` which could be null)
- `mixed` only true when tristate checkbox is null
- MergeSemantics combines with label text

---

### Radio Button

> **Note:** If you're using Flutter's built-in `Radio` widget or extending `RawRadio`, it already handles ALL necessary semantics correctly. The patterns below are only needed when building a radio button completely from scratch.

#### Basic Implementation
```dart
return Semantics(
  container: true,
  checked: isSelected,
  inMutuallyExclusiveGroup: true,
  enabled: onChanged != null,
  label: semanticLabel,
  onTap: onChanged != null ? () => onChanged!(value) : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onChanged != null ? () => onChanged!(value) : null,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

**Key Points:**
- `inMutuallyExclusiveGroup: true` for radio button semantics
- `checked` indicates selection state
- Consider using `Radio` or extending `RawRadio` instead of implementing from scratch

---

### Switch

#### Basic Implementation
```dart
return Semantics(
  container: true,
  toggled: value,  // Use toggled, not checked!
  enabled: onChanged != null,
  label: semanticLabel,
  onTap: onChanged != null ? () => onChanged!(!value) : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onChanged != null ? () => onChanged!(!value) : null,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

**Key Points:**
- Use `toggled` for switches, not `checked`
- `toggled` is mutually exclusive with `checked`/`mixed`

---

### Slider

#### Basic Implementation
```dart
return Semantics(
  container: true,
  slider: true,
  label: semanticLabel,
  value: _localizeValue(value),  // e.g., "45%", "Volume 7 of 10"
  enabled: onChanged != null,
  onIncrease: (onChanged != null && value < max)
      ? () => _adjustValue(true)
      : null,
  onDecrease: (onChanged != null && value > min)
      ? () => _adjustValue(false)
      : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onHorizontalDragUpdate: onChanged != null 
        ? (details) => _handleDrag(details)
        : null,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);

String _localizeValue(double value) {
  // Return human-readable value
  if (divisions != null) {
    final int position = ((value - min) / (max - min) * divisions!).round();
    return '$position of $divisions';
  }
  final percent = ((value - min) / (max - min) * 100).round();
  return '$percent%';
}

void _adjustValue(bool increase) {
  final step = (max - min) / (divisions ?? 100);
  final newValue = increase 
      ? (value + step).clamp(min, max)
      : (value - step).clamp(min, max);
  onChanged?.call(newValue);
}
```

#### With FocusableActionDetector
```dart
return FocusableActionDetector(
  focusNode: focusNode,
  enabled: onChanged != null,
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const _IncreaseIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const _IncreaseIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _DecreaseIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const _DecreaseIntent(),
  },
  actions: {
    _IncreaseIntent: CallbackAction<_IncreaseIntent>(
      onInvoke: (_) => value < max ? _adjustValue(true) : null,
    ),
    _DecreaseIntent: CallbackAction<_DecreaseIntent>(
      onInvoke: (_) => value > min ? _adjustValue(false) : null,
    ),
  },
  child: Semantics(
    container: true,
    slider: true,
    label: semanticLabel,
    value: _localizeValue(value),
    enabled: onChanged != null,
    onIncrease: (onChanged != null && value < max)
        ? () => _adjustValue(true)
        : null,
    onDecrease: (onChanged != null && value > min)
        ? () => _adjustValue(false)
        : null,
    child: GestureDetector(
      onHorizontalDragUpdate: onChanged != null 
          ? (details) => _handleDrag(details)
          : null,
      excludeFromSemantics: true,
      child: child,
    ),
  ),
);
```

**Key Points:**
- Localized `value` string (not raw numbers)
- Guard `onIncrease`/`onDecrease` with min/max checks
- Keyboard navigation with arrow keys

---

### TextField

#### Basic Implementation
```dart
return Semantics(
  container: true,
  textField: true,
  multiline: (maxLines ?? 1) > 1,
  obscured: obscureText,
  readOnly: readOnly,
  maxValueLength: maxLength,
  currentValueLength: (maxLength != null && controller != null)
      ? controller!.text.characters.length
      : null,
  value: obscureText ? null : controller?.text,  // NEVER expose passwords!
  label: semanticLabel,
  hint: semanticHint,
  focusable: !readOnly,
  focused: focusNode?.hasFocus == true,
  child: EditableText(
    controller: controller,
    focusNode: focusNode,
    // ... other EditableText properties
  ),
);
```

**Key Points:**
- `value: null` when `obscured: true` (security!)
- Character count for length-limited fields
- `multiline` for text areas

---

### Dropdown / Select

#### Collapsed State
```dart
return Semantics(
  container: true,
  button: true,  // It's a button when collapsed
  enabled: onChanged != null,
  label: semanticLabel,
  value: selectedValue?.toString() ?? 'None selected',
  onTap: onChanged != null ? () => _openDropdown() : null,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onChanged != null ? () => _openDropdown() : null,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

#### Expanded State
```dart
return Semantics(
  container: true,
  expanded: true,  // Indicates expanded state
  enabled: onChanged != null,
  label: semanticLabel,
  focusable: onChanged != null,
  focused: focusNode?.hasFocus == true,
  child: ListView.builder(
    itemCount: options.length,
    itemBuilder: (context, index) {
      return Semantics(
        container: true,
        button: true,
        selected: options[index] == selectedValue,
        label: options[index].toString(),
        onTap: () => _selectOption(options[index]),
        child: GestureDetector(
          onTap: () => _selectOption(options[index]),
          excludeFromSemantics: true,
          child: _buildOption(options[index]),
        ),
      );
    },
  ),
);
```

**Key Points:**
- `button: true` when collapsed
- `expanded: true` when open
- Each option has `selected` state

---

### Tab

#### Basic Implementation
```dart
return Semantics(
  container: true,
  button: true,
  selected: isSelected,
  enabled: onTap != null,
  label: semanticLabel,
  onTap: onTap,
  focusable: onTap != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onTap,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

**Key Points:**
- Tabs are buttons with `selected` state
- Focus management for keyboard navigation

---

### Dialog

#### Basic Implementation
```dart
Widget dialog = Semantics(
  container: true,
  namesRoute: true,  // Always true for dialogs
  scopesRoute: true,  // Always true for dialogs
  explicitChildNodes: true,  // Required with scopesRoute
  label: semanticLabel ?? dialogTitle,
  child: child,
);

// Only use BlockSemantics for modal dialogs
if (modal) {
  dialog = BlockSemantics(
    child: dialog,
  );
}

return dialog;
```

**Key Points:**
- `namesRoute` and `scopesRoute` always true for dialogs
- `explicitChildNodes` required when using `scopesRoute`
- `BlockSemantics` ONLY for modal dialogs (not all dialogs)
- BlockSemantics prevents interaction with background

---

### Tooltip

```dart
return Semantics(
  tooltip: message,
  child: child,
);
```

**Key Points:**
- Tooltips augment, don't replace child semantics
- Don't use `excludeSemantics` on tooltips

---

### Progress Indicator

```dart
return Semantics(
  container: true,
  label: semanticLabel ?? (value == null ? 'Loading' : 'Progress'),
  value: value != null ? '${(value * 100).round()}%' : null,
  liveRegion: true,  // Announces updates
  child: child,
);
```

**Key Points:**
- `liveRegion: true` for polite announcements
- Localized value string

---

### Link

#### Basic Implementation
```dart
return Semantics(
  container: true,
  link: true,
  enabled: onTap != null,
  label: semanticLabel,
  onTap: onTap,
  focusable: onTap != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onTap,
    excludeFromSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Focus(
        focusNode: focusNode,
        child: child,
      ),
    ),
  ),
);
```

---

### List Item

#### Basic Implementation
```dart
return Semantics(
  container: true,
  button: onTap != null,
  enabled: onTap != null,
  label: label,
  selected: isSelected,
  onTap: onTap,
  focusable: onTap != null,
  focused: focusNode?.hasFocus == true,
  child: onTap != null
      ? GestureDetector(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Focus(
            focusNode: focusNode,
            child: child,
          ),
        )
      : child,
);
```

**Key Points:**
- Only `button: true` if tappable
- Don't manually inject "Item 1 of 5" - let the framework handle it

---

### Toggle / Collapsible

```dart
return Semantics(
  container: true,
  button: true,
  expanded: expanded,
  enabled: onToggle != null,
  label: semanticLabel,
  onTap: onToggle,
  focusable: onToggle != null,
  focused: focusNode?.hasFocus == true,
  child: GestureDetector(
    onTap: onToggle,
    excludeFromSemantics: true,
    child: Focus(
      focusNode: focusNode,
      child: child,
    ),
  ),
);
```

---

## Testing & Debugging

### Enable Semantics Debugger
```dart
MaterialApp(
  showSemanticsDebugger: true,  // Shows semantic overlay
  // ...
)
```

### Test Semantics with SemanticsTester
```dart
testWidgets('button has correct semantics', (tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  
  await tester.pumpWidget(
    MyButton(
      onPressed: () {},
      label: 'Submit',
    ),
  );
  
  expect(
    tester.getSemantics(find.byType(MyButton)),
    matchesSemantics(
      label: 'Submit',
      isButton: true,
      isEnabled: true,
      isFocusable: true,
      hasEnabledState: true,
      hasTapAction: true,
    ),
  );
  
  handle.dispose();
});
```

### Verify No Duplicate Semantics
```dart
testWidgets('no duplicate tap actions', (tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  
  await tester.pumpWidget(MyButton());
  
  // Get the semantics tree
  final SemanticsNode root = tester.getSemantics(find.byType(MyButton));
  
  // Count tap actions in tree
  int tapActionCount = 0;
  void countTapActions(SemanticsNode node) {
    if (node.hasAction(SemanticsAction.tap)) {
      tapActionCount++;
    }
    node.visitChildren(countTapActions);
  }
  
  countTapActions(root);
  expect(tapActionCount, 1);  // Should only have one tap action
  
  handle.dispose();
});
```

### Test Focus Semantics
```dart
testWidgets('focus updates semantics', (tester) async {
  final focusNode = FocusNode();
  
  await tester.pumpWidget(
    MaterialApp(
      home: MyButton(
        focusNode: focusNode,
        label: 'Test',
      ),
    ),
  );
  
  expect(tester.getSemantics(find.byType(MyButton)).isFocused, false);
  
  focusNode.requestFocus();
  await tester.pump();
  
  expect(tester.getSemantics(find.byType(MyButton)).isFocused, true);
  
  focusNode.dispose();
});
```

---

## Common Pitfalls

### ❌ Duplicate Semantic Actions
```dart
// WRONG - Two tap handlers in semantics tree
Semantics(
  onTap: onPressed,
  child: GestureDetector(
    onTap: onPressed,  // Missing excludeFromSemantics!
    child: child,
  ),
)
```

### ❌ Semantics Outside FocusableActionDetector
```dart
// WRONG - Focus semantics get buried
Semantics(
  button: true,
  child: FocusableActionDetector(
    child: child,
  ),
)
```

### ❌ Using Raw Values
```dart
// WRONG - Not human-readable
Semantics(
  value: value.toString(),  // "0.4523"
)

// CORRECT - Localized
Semantics(
  value: '${(value * 100).round()}%',  // "45%"
)
```

### ❌ Exposing Password Values
```dart
// WRONG - Security issue!
Semantics(
  obscured: true,
  value: passwordController.text,  // NEVER do this!
)

// CORRECT
Semantics(
  obscured: true,
  value: null,  // Don't expose
)
```

### ❌ Wrong Checkbox Semantics
```dart
// WRONG - value could be null
Semantics(
  checked: value,  // Bad if tristate!
)

// CORRECT
Semantics(
  checked: value == true,
  mixed: tristate && value == null,
)
```

### ❌ Missing Container
```dart
// WRONG - May merge oddly
Semantics(
  button: true,
  label: 'Click me',
  child: Row(children: [icon, text]),
)

// CORRECT - Clear boundary
Semantics(
  container: true,  // Creates dedicated node
  button: true,
  label: 'Click me',
  child: Row(children: [icon, text]),
)
```

---

## Platform Considerations

### iOS VoiceOver
- Swipe up/down triggers `onIncrease`/`onDecrease` for sliders
- Double-tap activates buttons
- Rotor navigation for different element types

### Android TalkBack
- Volume keys can trigger `onIncrease`/`onDecrease`
- Double-tap activates
- Reading order follows widget tree by default
- May require `namesRoute` + `label` for dialogs (Issue #53924)

### Desktop (Windows Narrator, NVDA, JAWS)
- Tab navigation follows focus order
- Space/Enter activate buttons
- Arrow keys for sliders and radio groups

### Web
- ARIA roles mapped from Flutter semantics
- `scopesRoute`/`namesRoute` map to `role="dialog"`
- Focus semantics critical for keyboard navigation

---

## Migration from v1

### Updating Existing Components

1. **Add `excludeFromSemantics: true` to all GestureDetectors**
```dart
// Before
GestureDetector(
  onTap: onPressed,
  child: child,
)

// After
GestureDetector(
  onTap: onPressed,
  excludeFromSemantics: true,  // ADD THIS
  child: child,
)
```

2. **Consider FocusableActionDetector for complex interactions**
```dart
// Before
Focus(
  focusNode: focusNode,
  child: Semantics(...)
)

// After (if you need hover/shortcuts)
FocusableActionDetector(
  focusNode: focusNode,
  child: Semantics(...)
)
```

3. **Fix tristate checkbox semantics**
```dart
// Before
checked: value

// After
checked: value == true,
mixed: tristate && value == null
```

---

## References

### Official Flutter Documentation
- [Semantics class](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [SemanticsProperties](https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html)
- [FocusableActionDetector](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)
- [Focus system](https://api.flutter.dev/flutter/widgets/Focus-class.html)
- [BlockSemantics](https://api.flutter.dev/flutter/widgets/BlockSemantics-class.html)
- [MergeSemantics](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)

### Key Flutter Issues
- [#110107](https://github.com/flutter/flutter/issues/110107) - Tristate checkbox semantics
- [#53924](https://github.com/flutter/flutter/issues/53924) - TalkBack scopesRoute behavior
- [#115831](https://github.com/flutter/flutter/issues/115831) - FocusableActionDetector semantics control
- [#96485](https://github.com/flutter/flutter/issues/96485) - Semantics enabled property with checked/toggled

### Accessibility Guidelines
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Material Design Accessibility](https://m3.material.io/foundations/accessibility)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## Changelog

### v2.0 (Current)
- Added FocusableActionDetector implementation patterns
- Critical rule: `excludeFromSemantics` on all GestureDetectors
- Dual variants (basic/focusable) for all interactive components
- Expanded platform-specific considerations
- Enhanced testing patterns and debugging section
- Added migration guide from v1

### v1.0
- Initial guide with correct semantics implementations
- Fixed tristate checkbox handling
- Proper Dialog semantics with BlockSemantics
- Security considerations for obscured text

---

## Contributing

Found an issue or have a suggestion? Please contribute:
1. Test your semantics with real assistive technologies
2. Verify against Flutter's latest stable API
3. Include platform-specific testing results
4. Document any edge cases discovered

---

*This guide is maintained by the Flutter community. Last updated with Flutter 3.x stable.*