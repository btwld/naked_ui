# HeadlessSemantics Helper Methods Research & Validation

## Overview
This document validates the semantic helper methods for the HeadlessSemantics utility class against Flutter's official Semantics widget API.

## Flutter Semantics Widget Properties Reference

### Core Properties Used Across All Helpers
- `enabled`: bool? - Whether the widget is enabled/interactive
- `label`: String? - Textual description for accessibility
- `hint`: String? - Brief description of action result
- `excludeSemantics`: bool - Whether to exclude child semantics
- `focusable`: bool? - Whether the node can hold input focus
- `onTap`: VoidCallback? - Tap action handler

## Semantic Helper Methods Validation

### 1. `button` Helper Method

**Purpose**: Creates semantics for button widgets

**Flutter Properties for Buttons**:
- `button: true` - Marks as button widget
- `enabled: bool?` - Interactive state
- `label: String?` - Button text/description
- `hint: String?` - Action description
- `onTap: VoidCallback?` - Tap handler
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget button({
  Key? key,
  required Widget child,
  bool? enabled,
  String? label,
  String? hint,
  VoidCallback? onTap,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    button: true, // ✅ Correct
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 2. `checkbox` Helper Method

**Purpose**: Creates semantics for checkbox widgets

**Flutter Properties for Checkboxes**:
- `checked: bool?` - Checked state (NOT `value`)
- `mixed: bool?` - Tristate/indeterminate
- `enabled: bool?` - Interactive state
- `label: String?` - Checkbox label
- `hint: String?` - Action description
- `onTap: VoidCallback?` - Toggle handler
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget checkbox({
  Key? key,
  required Widget child,
  bool? checked, // ✅ Correct property name
  bool? mixed,
  bool? enabled,
  String? label,
  String? hint,
  VoidCallback? onTap,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    checked: checked,
    mixed: mixed,
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 3. `switchWidget` Helper Method (renamed from `switch`)

**Purpose**: Creates semantics for switch/toggle widgets

**Flutter Properties for Switches**:
- `toggled: bool?` - Toggle state (NOT `checked` or `value`)
- `enabled: bool?` - Interactive state
- `label: String?` - Switch label
- `hint: String?` - Action description
- `onTap: VoidCallback?` - Toggle handler
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget switchWidget({
  Key? key,
  required Widget child,
  bool? toggled, // ✅ Correct property name for switches
  bool? enabled,
  String? label,
  String? hint,
  VoidCallback? onTap,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    toggled: toggled,
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 4. `radio` Helper Method

**Purpose**: Creates semantics for radio button widgets

**Flutter Properties for Radio Buttons**:
- `checked: bool?` - Selected state
- `inMutuallyExclusiveGroup: true` - Radio button specific
- `enabled: bool?` - Interactive state
- `label: String?` - Radio label
- `hint: String?` - Action description
- `onTap: VoidCallback?` - Selection handler
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget radio({
  Key? key,
  required Widget child,
  bool? checked, // ✅ Correct property name
  bool? enabled,
  String? label,
  String? hint,
  VoidCallback? onTap,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    checked: checked,
    inMutuallyExclusiveGroup: true, // ✅ Required for radio
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 5. `slider` Helper Method

**Purpose**: Creates semantics for slider widgets

**Flutter Properties for Sliders**:
- `slider: true` - Marks as slider widget
- `enabled: bool?` - Interactive state
- `label: String?` - Slider label
- `value: String?` - Current value description
- `increasedValue: String?` - Value after increase
- `decreasedValue: String?` - Value after decrease
- `onIncrease: VoidCallback?` - Increase action
- `onDecrease: VoidCallback?` - Decrease action
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget slider({
  Key? key,
  required Widget child,
  bool? enabled,
  String? label,
  String? value,
  String? increasedValue,
  String? decreasedValue,
  VoidCallback? onIncrease,
  VoidCallback? onDecrease,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    slider: true, // ✅ Correct
    enabled: enabled,
    label: label,
    value: value,
    increasedValue: increasedValue,
    decreasedValue: decreasedValue,
    onIncrease: onIncrease,
    onDecrease: onDecrease,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 6. `textField` Helper Method

**Purpose**: Creates semantics for text field widgets

**Flutter Properties for Text Fields**:
- `textField: true` - Marks as text field widget
- `enabled: bool?` - Interactive state
- `label: String?` - Field label
- `hint: String?` - Placeholder/hint text
- `value: String?` - Current text value
- `multiline: bool?` - Multi-line support
- `obscured: bool?` - Password field
- `maxValueLength: int?` - Maximum characters
- `currentValueLength: int?` - Current character count
- `onTap: VoidCallback?` - Focus handler
- `onSetText: SetTextHandler?` - Text change handler
- `focusable: bool?` - Can receive focus

**Validated Implementation**:
```dart
static Widget textField({
  Key? key,
  required Widget child,
  bool? enabled,
  String? label,
  String? hint,
  String? value,
  bool? multiline,
  bool? obscured,
  int? maxValueLength,
  int? currentValueLength,
  VoidCallback? onTap,
  SetTextHandler? onSetText,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    textField: true, // ✅ Correct
    enabled: enabled,
    label: label,
    hint: hint,
    value: value,
    multiline: multiline,
    obscured: obscured,
    maxValueLength: maxValueLength,
    currentValueLength: currentValueLength,
    onTap: onTap,
    onSetText: onSetText,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

## Additional Semantic Helpers to Consider

Based on Flutter's Semantics API, these additional helpers could be useful:

### 7. `link` Helper Method
```dart
static Widget link({
  Key? key,
  required Widget child,
  bool? enabled,
  String? label,
  String? hint,
  Uri? linkUrl,
  VoidCallback? onTap,
  bool excludeSemantics = false,
  bool? focusable,
}) {
  return Semantics(
    key: key,
    link: true,
    linkUrl: linkUrl,
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    focusable: focusable ?? enabled,
    child: child,
  );
}
```

### 8. `image` Helper Method
```dart
static Widget image({
  Key? key,
  required Widget child,
  required String label, // Alt text is required for images
  bool excludeSemantics = false,
}) {
  return Semantics(
    key: key,
    image: true,
    label: label,
    excludeSemantics: excludeSemantics,
    child: child,
  );
}
```

### 9. `header` Helper Method
```dart
static Widget header({
  Key? key,
  required Widget child,
  required String label,
  int? headingLevel,
  bool excludeSemantics = false,
}) {
  return Semantics(
    key: key,
    header: true,
    headingLevel: headingLevel,
    label: label,
    excludeSemantics: excludeSemantics,
    child: child,
  );
}
```

### 10. `container` Helper Method
```dart
static Widget container({
  Key? key,
  required Widget child,
  String? label,
  bool explicitChildNodes = false,
  bool excludeSemantics = false,
}) {
  return Semantics(
    key: key,
    container: true,
    explicitChildNodes: explicitChildNodes,
    label: label,
    excludeSemantics: excludeSemantics,
    child: child,
  );
}
```

## Common Issues Found in Research

1. **Property Name Confusion**:
   - Checkboxes use `checked`, NOT `value`
   - Switches use `toggled`, NOT `checked`
   - Radio buttons use `checked` with `inMutuallyExclusiveGroup: true`

2. **Missing Properties**:
   - Radio buttons MUST have `inMutuallyExclusiveGroup: true`
   - Sliders need `onIncrease`/`onDecrease` not just `onTap`
   - Text fields benefit from `onSetText` handler

3. **Default Values**:
   - `focusable` should default to `enabled` value for interactive widgets
   - `excludeSemantics` should default to `false`

## Implementation Notes

1. **Switch Naming**: The method should be named `switchWidget` since `switch` is a reserved keyword in Dart

2. **Type Safety**: Use proper type definitions:
   - `SetTextHandler` = `void Function(String)`
   - `MoveCursorHandler` = `void Function(bool)`
   - `SetSelectionHandler` = `void Function(TextSelection)`

3. **Null Safety**: All semantic properties should be nullable to allow Flutter to use defaults

4. **Consistency**: All helper methods should follow the same parameter order:
   1. `key`
   2. `child` (required)
   3. State properties (checked, toggled, value, etc.)
   4. `enabled`
   5. `label`
   6. `hint`
   7. Action callbacks
   8. `excludeSemantics`
   9. `focusable`

## Testing Recommendations

Each helper method should be tested with:
1. Screen reader compatibility (TalkBack/VoiceOver)
2. Keyboard navigation
3. Focus management
4. Semantic tree inspection using Flutter Inspector

## Conclusion

The HeadlessSemantics helper methods provide a clean, type-safe way to add proper accessibility semantics to custom widgets. By validating against Flutter's official Semantics API, we ensure compatibility and correctness for assistive technologies.