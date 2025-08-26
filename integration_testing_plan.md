# Integration Testing Plan for Remaining Naked UI Components

## Current Status

### ✅ Components Already Tested
- **NakedButton** - Complete (8 tests) with focusOnPress functionality
- **NakedCheckbox** - Complete (8 tests) with focusOnPress functionality  
- **NakedRadio** - Complete (6 tests) - focusOnPress removed due to complexity
- **NakedTabs** - Complete (5 tests) with tab selection and navigation

### 📋 Components Remaining for Integration Tests

## 1. NakedTextField (HIGH PRIORITY)
**Location:** `/lib/src/naked_textfield.dart`  
**Example:** `/example/lib/api/naked_textfield.0.dart`

**Component Features:**
- Text input with focus management
- Hover, press, and focus state callbacks
- Keyboard interaction and text editing
- State management with hover/focus visual feedback

**Proposed Tests:**
1. **Text input and editing** - Type text, verify value changes
2. **Focus management** - Test focus/blur, autofocus behavior
3. **State callbacks** - Hover, focus, press state changes
4. **Keyboard navigation** - Tab navigation, Enter/Escape keys
5. **Disabled state** - Verify no interaction when disabled
6. **Selection and cursor management** - Text selection behavior
7. **Placeholder and validation** - If applicable
8. **Clear/reset functionality** - If present in component

**Complexity:** Medium (text input + state management)
**Estimated Time:** 30-40 minutes

## 2. NakedSlider (HIGH PRIORITY)
**Location:** `/lib/src/naked_slider.dart`  
**Example:** `/example/lib/api/naked_slider.0.dart`

**Component Features:**
- Drag-based value selection
- Keyboard arrow key navigation  
- Min/max bounds enforcement
- Custom visual painting with SliderThumbPainter

**Proposed Tests:**
1. **Value changes via drag** - Simulate drag gestures, verify value updates
2. **Keyboard navigation** - Arrow keys increment/decrement value
3. **Bounds enforcement** - Test min/max value constraints
4. **State callbacks** - Hover, focus, press, value change callbacks
5. **Disabled state** - No interaction when disabled
6. **Precision and step values** - If component supports stepped values
7. **Continuous vs discrete** - Different slider modes
8. **Focus management** - Tab navigation and focus indicators

**Complexity:** Medium (gesture handling + custom painting)
**Estimated Time:** 35-45 minutes

## 3. NakedSelect (MEDIUM PRIORITY)
**Location:** `/lib/src/naked_select.dart`  
**Example:** `/example/lib/api/naked_select.0.dart`

**Component Features:**
- Single and multiple selection modes
- Overlay-based dropdown menu
- Type-ahead search functionality
- Keyboard navigation (Arrow keys, Enter, Escape)
- Position fallbacks for overlay
- Close on select/outside click behavior

**Proposed Tests:**
1. **Open/close dropdown** - Click to open, escape/outside click to close
2. **Single selection** - Select item, verify selectedValue changes
3. **Multiple selection mode** - Test multiple item selection
4. **Keyboard navigation** - Arrow keys through options, Enter to select
5. **Type-ahead search** - Type to filter/navigate options
6. **State callbacks** - Open, close, selection callbacks
7. **Disabled state** - No interaction when disabled
8. **Overlay positioning** - Verify dropdown appears correctly
9. **Close behaviors** - closeOnSelect, closeOnClickOutside
10. **Accessibility** - Screen reader support, semantic labels

**Complexity:** High (overlay management + multiple modes)
**Estimated Time:** 45-60 minutes

## 4. NakedMenu (MEDIUM PRIORITY)
**Location:** `/lib/src/naked_menu.dart`  
**Example:** `/example/lib/api/naked_menu.0.dart`

**Component Features:**
- MenuController-based visibility
- Overlay rendering with positioning
- Menu items with NakedMenuItem
- Automatic close on selection
- Keyboard navigation support
- Focus management and accessibility

**Proposed Tests:**
1. **Open/close via controller** - controller.open(), verify menu visibility
2. **Menu item selection** - Click items, verify callbacks
3. **Outside click closes** - Click outside menu, verify closes
4. **Keyboard navigation** - Arrow keys through menu items
5. **Escape key closes** - Escape closes menu
6. **Menu positioning** - Verify overlay positioning
7. **State callbacks** - onClose callback functionality
8. **Disabled menu items** - If supported
9. **Focus management** - Focus returns to trigger after close
10. **Accessibility** - Screen reader navigation

**Complexity:** High (controller + overlay + navigation)  
**Estimated Time:** 45-55 minutes

## 5. NakedAccordion (LOW PRIORITY)
**Location:** `/lib/src/naked_accordion.dart`  
**Example:** `/example/lib/api/naked_accordion.0.dart`

**Component Features:**
- NakedAccordionController with min/max constraints
- Expand/collapse sections
- Multiple sections support
- Initial expanded values
- Animation support

**Proposed Tests:**
1. **Expand/collapse sections** - Click headers, verify content visibility
2. **Controller behavior** - Programmatic expand/collapse
3. **Min/max constraints** - Test controller limits (min: 1, max: 1 in example)
4. **Initial expanded state** - Verify initialExpandedValues works
5. **Multiple section handling** - If min/max allows multiple
6. **State callbacks** - Expansion state change callbacks
7. **Keyboard navigation** - Enter/Space to toggle sections
8. **Disabled sections** - If supported
9. **Animation behavior** - Smooth expand/collapse

**Complexity:** Medium (controller + animations)
**Estimated Time:** 25-35 minutes

## 6. NakedTooltip (LOW PRIORITY)  
**Location:** `/lib/src/naked_tooltip.dart`
**Example:** `/example/lib/api/naked_tooltip.0.dart`

**Component Features:**
- Hover-triggered tooltip display
- NakedMenuPosition positioning
- Animation controller integration
- Focus-based tooltip (accessibility)

**Proposed Tests:**
1. **Show on hover** - Hover trigger, verify tooltip appears
2. **Hide on hover out** - Move away, tooltip disappears  
3. **Show on focus** - Focus trigger for accessibility
4. **Positioning** - Verify tooltip position relative to target
5. **Animation behavior** - Smooth fade in/out
6. **Multiple tooltip handling** - If applicable
7. **Delay behavior** - Show/hide delays
8. **Content updates** - Dynamic tooltip content changes

**Complexity:** Low (mostly hover + positioning)
**Estimated Time:** 20-30 minutes

## Implementation Strategy

### Phase 1: High Priority (TextField + Slider)
- Most common UI patterns
- Foundation for other complex components
- Critical for user input workflows

### Phase 2: Medium Priority (Select + Menu)  
- Complex overlay behavior
- Advanced interaction patterns
- Important for navigation and selection workflows

### Phase 3: Low Priority (Accordion + Tooltip)
- Less critical for core functionality
- Can be deferred if time constraints exist
- Good for completeness

## Testing Patterns to Reuse

### From Existing Tests:
- **Focus management** - createManagedFocusNode() pattern
- **State callbacks** - expectWidgetStates() helper
- **Hover simulation** - simulateHover() helper  
- **Keyboard testing** - testKeyboardActivation() helper
- **Disabled state** - Consistent pattern across components

### New Patterns Needed:
- **Text input simulation** - For TextField
- **Drag gesture simulation** - For Slider
- **Overlay verification** - For Select/Menu positioning
- **Animation testing** - For Accordion/Tooltip
- **Controller testing** - For Menu/Accordion

## File Structure

```
example/integration_test/components/
├── naked_button_test.dart      ✅ (8 tests)
├── naked_checkbox_test.dart    ✅ (8 tests) 
├── naked_radio_test.dart       ✅ (6 tests)
├── naked_tabs_test.dart        ✅ (5 tests)
├── naked_textfield_test.dart   📝 (planned)
├── naked_slider_test.dart      📝 (planned)  
├── naked_select_test.dart      📝 (planned)
├── naked_menu_test.dart        📝 (planned)
├── naked_accordion_test.dart   📝 (planned)
└── naked_tooltip_test.dart     📝 (planned)
```

## Success Criteria

- All tests follow KISS/YAGNI principles (no over-engineering)
- Each component has 6-10 focused tests covering core functionality
- Tests use existing helper patterns where applicable  
- New helpers are minimal and reusable
- All tests pass consistently
- Code coverage for critical user interaction paths

## Total Estimated Time: 3-4 hours
- High Priority: ~1.5 hours
- Medium Priority: ~1.5 hours  
- Low Priority: ~1 hour