# Implementation Checklist - Pragmatic Approach

**Total Time: ~9.75 hours (1-2 days)**
**Approach: Quick fixes, zero breaking changes**

Do these in order. Each fix is independent and can be tested immediately.

---

## ✅ Fix 1: Remove Unused Intent Classes (1 hour)

**Why:** Dead code that does nothing. Easy win.

### File: `/packages/naked_ui/lib/src/utilities/intents.dart`

#### Change 1: Remove intent class definitions (Lines 382-388)

**BEFORE:**
```dart
/// Intent: Move focus by page up (large jump backward).
class _PageUpIntent extends Intent {
  const _PageUpIntent();
}

/// Intent: Move focus by page down (large jump forward).
class _PageDownIntent extends Intent {
  const _PageDownIntent();
}
```

**AFTER:**
```dart
// Remove these lines completely
```

#### Change 2: Remove shortcuts (Lines 292-293)

**BEFORE:**
```dart
const Map<ShortcutActivator, Intent> _selectShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.home): _FirstFocusIntent(),
      SingleActivator(LogicalKeyboardKey.end): _LastFocusIntent(),
      SingleActivator(LogicalKeyboardKey.pageUp): _PageUpIntent(),        // ← DELETE
      SingleActivator(LogicalKeyboardKey.pageDown): _PageDownIntent(),    // ← DELETE
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          _OpenOverlayIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DismissIntent(),
    };
```

**AFTER:**
```dart
const Map<ShortcutActivator, Intent> _selectShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.home): _FirstFocusIntent(),
      SingleActivator(LogicalKeyboardKey.end): _LastFocusIntent(),
      // Removed PageUp/PageDown - no handlers existed
      SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          _OpenOverlayIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DismissIntent(),
    };
```

### How to Test:
```bash
cd packages/naked_ui
dart analyze                           # Should pass
flutter test                           # All tests should pass
grep -r "_PageUpIntent\|_PageDownIntent" lib/  # Should find nothing
```

### Time: 1 hour
- 15 min: Search codebase to verify no usage
- 10 min: Make changes
- 20 min: Run tests
- 15 min: Code review

---

## ✅ Fix 2: Timer Race Conditions (30 minutes)

**Why:** Rapid button presses or tooltip hovers can trigger race conditions. Simple fix.

### File 1: `/packages/naked_ui/lib/src/naked_button.dart`

#### Change: Ensure timer is cancelled before creating new one (Lines 145-151)

**BEFORE:**
```dart
void _handleKeyboardActivation() {
  if (!widget.enabled || widget.onPressed == null) return;

  if (widget.enableFeedback) {
    Feedback.forTap(context);
  }

  widget.onPressed!();

  // Visual feedback for keyboard activation
  updatePressState(true, widget.onPressChange);

  _cleanupKeyboardTimer();                                    // ← Calls cancel
  _keyboardPressTimer = Timer(const Duration(milliseconds: 100), () {  // ← But immediately creates new timer
    if (mounted) {
      updatePressState(false, widget.onPressChange);
    }
    _keyboardPressTimer = null;
  });
}
```

**AFTER:**
```dart
void _handleKeyboardActivation() {
  if (!widget.enabled || widget.onPressed == null) return;

  if (widget.enableFeedback) {
    Feedback.forTap(context);
  }

  widget.onPressed!();

  // Visual feedback for keyboard activation
  updatePressState(true, widget.onPressChange);

  // Cancel any existing timer before creating new one
  _keyboardPressTimer?.cancel();
  _keyboardPressTimer = Timer(const Duration(milliseconds: 100), () {
    if (!mounted) return;  // Early return pattern is cleaner
    updatePressState(false, widget.onPressChange);
    _keyboardPressTimer = null;
  });
}
```

**Note:** You can also remove the `_cleanupKeyboardTimer()` method (lines 128-131) since it's now unused, but that's optional.

### File 2: `/packages/naked_ui/lib/src/naked_tooltip.dart`

#### Change: Add mounted checks and ensure proper cancellation (Lines 161-174)

**BEFORE:**
```dart
void _handleMouseEnter(PointerEnterEvent _) {
  _showTimer?.cancel();
  _waitTimer?.cancel();
  _waitTimer = Timer(widget.waitDuration, () {
    _menuController.open();
  });
}

void _handleMouseExit(PointerExitEvent _) {
  _showTimer?.cancel();
  _waitTimer?.cancel();
  _showTimer = Timer(widget.showDuration, () {
    _menuController.close();
  });
}
```

**AFTER:**
```dart
void _handleMouseEnter(PointerEnterEvent _) {
  _showTimer?.cancel();
  _showTimer = null;  // Clear reference
  _waitTimer?.cancel();

  _waitTimer = Timer(widget.waitDuration, () {
    if (!mounted) return;  // Add safety check
    _menuController.open();
    _waitTimer = null;
  });
}

void _handleMouseExit(PointerExitEvent _) {
  _waitTimer?.cancel();
  _waitTimer = null;  // Clear reference
  _showTimer?.cancel();

  _showTimer = Timer(widget.showDuration, () {
    if (!mounted) return;  // Add safety check
    _menuController.close();
    _showTimer = null;
  });
}
```

### How to Test:
```bash
cd packages/naked_ui

# Run tests
flutter test test/naked_button_test.dart
flutter test test/naked_tooltip_test.dart

# Manual test: Create a test app and:
# 1. Rapidly press space bar on a focused button (should not error)
# 2. Quickly mouse in/out of tooltip (should not error)
# 3. Dispose widget while timer is active (should not crash)
```

### Time: 30 minutes
- 15 min: Make changes
- 10 min: Run tests
- 5 min: Manual testing

---

## ✅ Fix 3: Material Import Documentation (1 hour)

**Why:** NakedRadio currently requires Material's RadioGroup. We can't fix this easily (would take 15-25 hours), so document it honestly.

### File 1: `/packages/naked_ui/lib/src/naked_radio.dart`

#### Change: Add explanatory comment (After line 1)

**BEFORE:**
```dart
import 'package:flutter/material.dart';

import 'mixins/naked_mixins.dart';
```

**AFTER:**
```dart
import 'package:flutter/material.dart';

// NOTE: NakedRadio currently depends on Material's RadioGroup for
// group coordination (see line 144: RadioGroup.maybeOf<T>(context)).
// This is a known limitation and requires users to import Material.
// TODO: Implement headless RadioGroup in v1.0 to eliminate this dependency.

import 'mixins/naked_mixins.dart';
```

### File 2: `/packages/naked_ui/README.md`

Find the appropriate section (or create "Known Limitations" section) and add:

```markdown
## Known Limitations

### NakedRadio Material Dependency

**Current limitation:** `NakedRadio` currently requires Material's `RadioGroup` for coordinating radio button groups. This means:

- You must import `package:flutter/material.dart` to use `NakedRadio`
- Adds Material package to your bundle (~200KB)

**Why:** Radio buttons need a way to coordinate which button is selected in a group. We currently use Material's `RadioGroup.maybeOf<T>(context)` for this.

**Future:** We plan to implement a headless `RadioGroup` in v1.0 to eliminate this dependency.

**Workaround:** All other Naked UI components are fully headless. If bundle size is critical, consider using other components.
```

### File 3: `/packages/naked_ui/CONTRIBUTING.md`

Add or update the architecture section:

```markdown
## Architecture Principles

### Headless UI Philosophy

All Naked UI components should avoid dependencies on Material or Cupertino. We provide only:
- State management
- Keyboard/focus handling
- Accessibility hooks

**Exception:** `NakedRadio` currently depends on Material's `RadioGroup` (temporary limitation, to be fixed in v1.0).
```

### How to Test:
```bash
# Verify documentation is clear
cat packages/naked_ui/lib/src/naked_radio.dart | head -n 10
cat packages/naked_ui/README.md | grep -A 10 "Known Limitations"

# Verify the code still works
cd packages/naked_ui
flutter test test/naked_radio_test.dart
```

### Time: 1 hour
- 20 min: Write documentation
- 10 min: Review and polish
- 10 min: Test that radio still works
- 20 min: Get feedback/review

---

## ✅ Fix 4: setState During Build (2.5 hours)

**Why:** `setState()` in `onFocusChange` callback can be called during build phase, causing "setState during build" errors. Flutter's standard fix: use `addPostFrameCallback`.

### File: `/packages/naked_ui/lib/src/naked_tabs.dart`

#### Change: Defer setState to next frame (Lines 460-466)

**BEFORE:**
```dart
return NakedFocusableDetector(
  enabled: _isEnabled,
  autofocus: widget.autofocus,
  onFocusChange: (f) {
    updateFocusState(f, widget.onFocusChange);
    if (f && _isEnabled) {
      _scope.selectTab(widget.tabId);
    }
    setState(() {});  // ❌ Can cause "setState during build" error
  },
  onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
  focusNode: effectiveFocusNode,
  mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
```

**AFTER:**
```dart
return NakedFocusableDetector(
  enabled: _isEnabled,
  autofocus: widget.autofocus,
  onFocusChange: (f) {
    updateFocusState(f, widget.onFocusChange);
    if (f && _isEnabled) {
      _scope.selectTab(widget.tabId);
    }

    // Defer setState to next frame to avoid "setState during build" error
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  },
  onHoverChange: (h) => updateHoverState(h, widget.onHoverChange),
  focusNode: effectiveFocusNode,
  mouseCursor: _isEnabled ? widget.mouseCursor : SystemMouseCursors.basic,
```

### How to Test:

**Unit Test:** Create a test that triggers focus during build phase

```dart
// Add to test/naked_tabs_test.dart
testWidgets('Tab handles focus change during build phase', (tester) async {
  bool focusChanged = false;

  await tester.pumpWidget(
    MaterialApp(
      home: NakedTabs(
        value: 'tab1',
        onChanged: (_) {},
        children: [
          NakedTab(
            tabId: 'tab1',
            autofocus: true,  // This triggers focus during build
            onFocusChange: (_) => focusChanged = true,
            child: Text('Tab 1'),
          ),
        ],
      ),
    ),
  );

  await tester.pumpAndSettle();
  expect(focusChanged, true);
  // Should not throw "setState during build" error
});
```

**Manual Test:**
```bash
cd packages/naked_ui
flutter test test/naked_tabs_test.dart

# Check for "setState during build" warnings
flutter test 2>&1 | grep -i "setstate"  # Should be empty

# Manual UI test: Create app with autofocus tabs and verify no errors
```

### Time: 2.5 hours
- 15 min: Apply fix
- 45 min: Write regression test
- 30 min: Test with multiple tabs scenarios
- 30 min: Integration testing
- 30 min: Code review

---

## ✅ Fix 5: Infinite Loop Risk (4.5 hours)

**Why:** `_focusFirstTab()` and `_focusLastTab()` have while loops with no safety limit. If focus is circular (uncommon but possible), the app freezes forever.

### File: `/packages/naked_ui/lib/src/naked_tabs.dart`

#### Change: Add safety counters to prevent infinite loops (Lines 375-393)

**BEFORE:**
```dart
void _focusFirstTab() {
  // Find the first tab in the current tab group
  final scope = FocusScope.of(context);
  scope.focusInDirection(TraversalDirection.left);
  // Move left until we cannot go further (reaching the first tab).
  while (scope.focusInDirection(TraversalDirection.left)) {
    // Continue until we reach the first tab.
  }
}

void _focusLastTab() {
  // Find the last tab in the current tab group
  final scope = FocusScope.of(context);
  scope.focusInDirection(TraversalDirection.right);
  // Move right until we cannot go further (reaching the last tab).
  while (scope.focusInDirection(TraversalDirection.right)) {
    // Continue until we reach the last tab.
  }
}
```

**AFTER:**
```dart
void _focusFirstTab() {
  // Find the first tab in the current tab group
  final scope = FocusScope.of(context);
  int attempts = 0;
  const maxAttempts = 100; // Safety limit for circular traversal

  scope.focusInDirection(TraversalDirection.left);
  while (scope.focusInDirection(TraversalDirection.left) && attempts < maxAttempts) {
    attempts++;
  }

  assert(
    attempts < maxAttempts,
    'Focus traversal exceeded safety limit ($maxAttempts attempts). '
    'This may indicate a circular focus configuration in the tab group.',
  );
}

void _focusLastTab() {
  // Find the last tab in the current tab group
  final scope = FocusScope.of(context);
  int attempts = 0;
  const maxAttempts = 100; // Safety limit for circular traversal

  scope.focusInDirection(TraversalDirection.right);
  while (scope.focusInDirection(TraversalDirection.right) && attempts < maxAttempts) {
    attempts++;
  }

  assert(
    attempts < maxAttempts,
    'Focus traversal exceeded safety limit ($maxAttempts attempts). '
    'This may indicate a circular focus configuration in the tab group.',
  );
}
```

### How to Test:

**Create comprehensive test file:**

```dart
// Add to test/naked_tabs_test.dart or create test/naked_tabs_focus_test.dart

testWidgets('Focus first/last with single tab', (tester) async {
  // Test with 1 tab - should not loop
  await tester.pumpWidget(
    MaterialApp(
      home: NakedTabs(
        value: 'tab1',
        onChanged: (_) {},
        children: [
          NakedTab(tabId: 'tab1', child: Text('Tab 1')),
        ],
      ),
    ),
  );

  // Should complete without hanging
  await tester.sendKeyEvent(LogicalKeyboardKey.home);
  await tester.pumpAndSettle();

  await tester.sendKeyEvent(LogicalKeyboardKey.end);
  await tester.pumpAndSettle();

  // If we get here, no infinite loop occurred
});

testWidgets('Focus first/last with many tabs', (tester) async {
  // Test with 100 tabs - should not exceed safety limit
  final tabs = List.generate(
    100,
    (i) => NakedTab(
      tabId: 'tab$i',
      child: Text('Tab $i'),
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: NakedTabs(
        value: 'tab50',
        onChanged: (_) {},
        children: tabs,
      ),
    ),
  );

  // Should complete without hanging or hitting assertion
  await tester.sendKeyEvent(LogicalKeyboardKey.home);
  await tester.pumpAndSettle();

  await tester.sendKeyEvent(LogicalKeyboardKey.end);
  await tester.pumpAndSettle();
});

testWidgets('Focus traversal with nested focus scopes', (tester) async {
  // Test with nested FocusScope to ensure safety limit works
  await tester.pumpWidget(
    MaterialApp(
      home: FocusScope(  // Extra focus scope
        child: NakedTabs(
          value: 'tab1',
          onChanged: (_) {},
          children: [
            NakedTab(tabId: 'tab1', child: Text('Tab 1')),
            NakedTab(tabId: 'tab2', child: Text('Tab 2')),
            NakedTab(tabId: 'tab3', child: Text('Tab 3')),
          ],
        ),
      ),
    ),
  );

  await tester.sendKeyEvent(LogicalKeyboardKey.home);
  await tester.pumpAndSettle();

  await tester.sendKeyEvent(LogicalKeyboardKey.end);
  await tester.pumpAndSettle();

  // Should complete without issues
});
```

**Manual Testing Script:**

```bash
cd packages/naked_ui

# Run all tab tests
flutter test test/naked_tabs_test.dart

# Run with verbose to see if assertions trigger
flutter test test/naked_tabs_test.dart --verbose

# Create a test app with extreme cases:
# 1. Single tab (should not loop)
# 2. 100+ tabs (should not hit limit)
# 3. Tabs with custom FocusTraversalPolicy
# 4. Disabled tabs mixed with enabled tabs
```

**Integration Test:**
Create `test_driver/tabs_integration_test.dart`:

```dart
// Test real keyboard navigation
testWidgets('Real keyboard Home/End navigation', (tester) async {
  await tester.pumpWidget(MyTestApp());

  // Focus a tab in the middle
  await tester.tap(find.text('Tab 5'));
  await tester.pumpAndSettle();

  // Press Home - should go to first tab without hanging
  await tester.sendKeyEvent(LogicalKeyboardKey.home);
  await tester.pumpAndSettle(timeout: Duration(seconds: 2));

  // Press End - should go to last tab without hanging
  await tester.sendKeyEvent(LogicalKeyboardKey.end);
  await tester.pumpAndSettle(timeout: Duration(seconds: 2));

  // If timeout occurs, infinite loop is present
});
```

### How to Test (Step-by-Step):

```bash
# 1. Run unit tests (1 hour)
cd packages/naked_ui
flutter test test/naked_tabs_test.dart
flutter test --coverage

# 2. Run integration tests (1 hour)
flutter drive --target=test_driver/tabs_integration_test.dart

# 3. Manual testing (1 hour)
# Create example app and test:
# - Home/End keys with 1, 10, 100 tabs
# - Verify focus moves correctly
# - Check debug console for assertion messages
# - Profile performance (should be fast)

# 4. Code review (30 min)
# - Review changes
# - Verify comments are clear
# - Check test coverage
```

### Time: 4.5 hours
- 30 min: Apply fix and add comments
- 1.5 hours: Write comprehensive unit tests
- 1 hour: Integration testing
- 1 hour: Manual testing and edge cases
- 30 min: Code review

---

## Summary

| Fix | Time | Complexity | Risk |
|-----|------|------------|------|
| 1. Unused Intents | 1h | Easy | None |
| 2. Timer Races | 0.5h | Easy | Low |
| 3. Material Import Docs | 1h | Easy | None |
| 4. setState Build | 2.5h | Medium | Low |
| 5. Infinite Loop | 4.5h | Medium | Low |
| **TOTAL** | **9.5h** | **1-2 days** | **Low** |

## Order of Implementation

**Day 1 Morning (2 hours):**
1. Fix 1: Unused Intents → Easy win, builds confidence
2. Fix 2: Timer Races → Quick, minimal code
3. Fix 3: Material Docs → No code changes

**Day 1 Afternoon (2.5 hours):**
4. Fix 4: setState Build → Need focus for testing

**Day 2 (4.5 hours):**
5. Fix 5: Infinite Loop → Most complex, needs comprehensive testing

## Final Verification

After all fixes:

```bash
cd packages/naked_ui

# Clean build
flutter clean
flutter pub get

# Run all tests
flutter test

# Analyze code
dart analyze

# Format code
dart format lib/ test/

# Check coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Manual smoke test in example app
cd example
flutter run
# Test keyboard navigation, tooltips, buttons, radios, tabs
```

## Success Criteria

- ✅ All tests pass
- ✅ No analyzer warnings
- ✅ No "setState during build" errors
- ✅ No infinite loops possible
- ✅ Timer race conditions eliminated
- ✅ Dead code removed
- ✅ Material dependency documented
- ✅ Code coverage ≥80% for changed files

---

**Note:** This is the PRAGMATIC approach. If you want to eliminate the Material dependency entirely (15-25 hours), see the PURIST approach in `VERIFIED_IMPLEMENTATION_PLAN.md`.
