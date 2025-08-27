# Migration Guide

## Migrating to v0.1.0

This guide helps you migrate your existing code from pre-v0.1.0 versions to v0.1.0.

### ⚠️ Breaking Changes

#### 1. State Callback Naming Convention

**What Changed:** All state callback parameters have been renamed for consistency across the API.

**Reason:** To establish a consistent naming convention where all callbacks that notify about state changes use the pattern `onXChange` instead of the inconsistent `onXedState`.

#### Affected Callbacks

The following callback names have changed:

| Old Name | New Name | Components |
|----------|----------|------------|
| `onStateHover` | `onHoverChange` | NakedButton, NakedCheckbox, NakedSelect*, NakedSlider, NakedTabs, NakedTextField, NakedRadio, NakedMenu*, NakedAccordion* |
| `onStatePressed` | `onPressChange` | NakedButton, NakedCheckbox, NakedTabs, NakedTextField, NakedRadio, NakedMenu*, NakedSelect* |
| `onStateFocus` | `onFocusChange` | NakedButton, NakedCheckbox, NakedSlider, NakedTabs, NakedTextField, NakedRadio, NakedMenu*, NakedSelect* |
| `onStateDragging` | `onDragChange` | NakedSlider |
| `onStateSelected` | `onSelectChange` | NakedRadio, NakedSelectItem |

*Note: Some components were already using the new naming convention.*

#### 2. Removed Callbacks

The following callbacks were **REMOVED entirely** (not renamed) to simplify the API:

| Removed Callback | Component | Replacement |
|------------------|-----------|-------------|
| `onDisabledState` | NakedButton, NakedMenu | Use `enabled` property to control disabled state |

**Reason:** The `enabled` property already controls the disabled state, making a callback redundant and following the YAGNI principle.

### Migration Steps

#### Automated Migration with Find & Replace

You can use your IDE's find and replace functionality to automatically update most occurrences:

1. **Find:** `onStateHover:`  
   **Replace with:** `onHoverChange:`

2. **Find:** `onStatePressed:`  
   **Replace with:** `onPressChange:`

3. **Find:** `onStateFocus:`  
   **Replace with:** `onFocusChange:`

4. **Find:** `onStateDragging:`  
   **Replace with:** `onDragChange:`

5. **Find:** `onStateSelected:`  
   **Replace with:** `onSelectChange:`

6. **Remove:** `onDisabledState:` (delete entire lines - this callback no longer exists)

#### Manual Migration Examples

**Before (pre-v0.1.0):**
```dart
NakedButton(
  onPressed: () => handlePress(),
  onStateHover: (isHovered) => setState(() => _isHovered = isHovered),
  onStatePressed: (isPressed) => setState(() => _isPressed = isPressed),
  onStateFocus: (isFocused) => setState(() => _isFocused = isFocused),
  onDisabledState: (isDisabled) => setState(() => _isDisabled = isDisabled), // This callback was removed
  child: Text('Button'),
)
```

**After (v0.1.0):**
```dart
NakedButton(
  onPressed: () => handlePress(),
  onHoverChange: (isHovered) => setState(() => _isHovered = isHovered),
  onPressChange: (isPressed) => setState(() => _isPressed = isPressed),
  onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
  // onDisabledState removed - use enabled property instead
  enabled: !_isDisabled, // Control disabled state via enabled property
  child: Text('Button'),
)
```

**Before (NakedSlider):**
```dart
NakedSlider(
  value: _sliderValue,
  onChanged: (value) => setState(() => _sliderValue = value),
  onStateHover: (isHovered) => setState(() => _isHovered = isHovered),
  onStateDragging: (isDragging) => setState(() => _isDragging = isDragging),
  child: CustomSliderDesign(),
)
```

**After (NakedSlider):**
```dart
NakedSlider(
  value: _sliderValue,
  onChanged: (value) => setState(() => _sliderValue = value),
  onHoverChange: (isHovered) => setState(() => _isHovered = isHovered),
  onDragChange: (isDragging) => setState(() => _isDragging = isDragging),
  child: CustomSliderDesign(),
)
```

**Before (NakedRadio):**
```dart
NakedRadio(
  value: _selectedValue,
  onChanged: (value) => setState(() => _selectedValue = value),
  onStateHover: (isHovered) => setState(() => _isHovered = isHovered),
  onStateSelected: (isSelected) => setState(() => _isSelected = isSelected),
  child: CustomRadioDesign(),
)
```

**After (NakedRadio):**
```dart
NakedRadio(
  value: _selectedValue,
  onChanged: (value) => setState(() => _selectedValue = value),
  onHoverChange: (isHovered) => setState(() => _isHovered = isHovered),
  onSelectChange: (isSelected) => setState(() => _isSelected = isSelected),
  child: CustomRadioDesign(),
)
```

### Component-Specific Migration

#### NakedButton
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`
- `onDisabledState` → **REMOVED** (use `enabled` property)

#### NakedCheckbox
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`

#### NakedSelect & NakedSelectTrigger & NakedSelectItem
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`
- `onStateSelected` → `onSelectChange` (NakedSelectItem only)

#### NakedSlider
- `onStateHover` → `onHoverChange`
- `onStateDragging` → `onDragChange`
- `onStateFocus` → `onFocusChange`

#### NakedTabs (NakedTab)
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`

#### NakedTextField
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`

#### NakedRadio
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateSelected` → `onSelectChange`
- `onStateFocus` → `onFocusChange`

#### NakedMenu (NakedMenuItem)
- `onStateHover` → `onHoverChange`
- `onStatePressed` → `onPressChange`
- `onStateFocus` → `onFocusChange`
- `onDisabledState` → **REMOVED** (use `enabled` property)

#### NakedAccordion
- `onStateHover` → `onHoverChange` (in nested NakedButton usage)

### Validation Steps

After migration, ensure your code:

1. **Compiles without errors** - The old callback names will cause compilation errors
2. **Maintains the same behavior** - All functionality should work identically
3. **Passes your tests** - Run your test suite to ensure nothing broke
4. **No references to removed callbacks** - Ensure `onDisabledState` is completely removed

### Regex Patterns for Advanced Users

If you prefer using regular expressions for migration:

```regex
# Find pattern:
onState(Hover|Pressed|Focus|Dragging|Selected):

# Replace pattern:
on$1Change:

# Special case for NakedSlider:
# onStateDragging → onDragChange (the 'State' and 'ging' are removed)
```

For removing the deleted callback:
```regex
# Find and DELETE these lines:
^\s*onDisabledState:.*$
```

### Note on Naming Conventions

The new `onXChange` pattern was chosen to:
- Distinguish state observation callbacks from action callbacks
- Align with Flutter's `Focus.onFocusChange` pattern
- Provide consistency across all components

Note the difference:
- `onPressed()` - Action callback when button is pressed
- `onPressChange(bool)` - State observation when press state changes

### Getting Help

If you encounter issues during migration:

1. **Check this guide** - Make sure you've applied all the changes
2. **Review the examples** - Look at the updated examples in `/example/lib/api/`
3. **Check the updated documentation** - All docs reflect the new API
4. **File an issue** - If you find problems, please report them on GitHub

### What's Not Changed

The following remain exactly the same:
- All widget functionality and behavior
- All non-callback parameters and properties
- Widget lifecycle and performance characteristics
- Accessibility features and semantics
- All `onPressed`, `onChanged`, and similar action callbacks

This is purely a naming consistency update with some callback removals for API simplification.