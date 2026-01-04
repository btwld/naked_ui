# NakedAccordion InheritedModel Pattern

This document explains the architectural decision to use `InheritedModel` for selective rebuilds in the `NakedAccordion` widget, following Flutter's official best practices.

## Problem Statement

### The Original Issue

When using a shared `ChangeNotifier` controller with multiple accordion items, every item would rebuild whenever **any** item's state changed:

```
NakedAccordionController (single ChangeNotifier)
         │
         ├── ListenableBuilder (Item 1) ──► ALL rebuild when ANY changes
         ├── ListenableBuilder (Item 2) ──►
         ├── ListenableBuilder (Item 3) ──►
         └── ... (100 items = 100 rebuilds for 1 change)
```

This resulted in **O(n) rebuilds** when only O(1) items actually changed state.

### Previous Solution: Manual Caching

The previous implementation used manual widget caching:

```dart
// OLD APPROACH - Manual caching
bool? _cachedIsExpanded;
bool? _cachedCanCollapse;
bool? _cachedCanExpand;
Set<WidgetState>? _cachedWidgetStates;
Widget? _cachedChild;

// Check if state changed, return cached widget if not
if (_cachedChild != null &&
    _cachedIsExpanded == isExpanded &&
    /* ... more comparisons */) {
  return _cachedChild!;
}
```

**Problems with manual caching:**
- Cognitive overhead for developers
- Cache invalidation complexity
- Memory overhead (storing entire widget trees)
- Symptom treatment rather than root cause fix

## Solution: InheritedModel Pattern

### Flutter's Recommended Approach

Flutter's own `MediaQuery` widget uses `InheritedModel` for selective rebuilds. When you call `MediaQuery.sizeOf(context)`, only widgets that depend on size rebuild when size changes—not widgets that only depend on padding or other properties.

This is the "Principle of Least Rebuild": widgets subscribe only to the aspects they care about.

### How It Works

1. **NakedAccordionScope extends InheritedModel<T>**
   - The accordion item's value type `T` serves as the "aspect"
   - Each item depends on its own value as an aspect

2. **Aspect-Based Dependencies**
   - `NakedAccordionScope.isExpandedOf<T>(context, value)` creates a dependency on that specific value
   - The `updateShouldNotifyDependent` method checks if that value's state changed

3. **Surgical Rebuilds**
   - When item "A" expands, only item "A" rebuilds
   - Items "B", "C", "D" don't rebuild because their aspect didn't change

### Code Architecture

```dart
// NakedAccordionScope uses InheritedModel for selective notifications
class NakedAccordionScope<T> extends InheritedModel<T> {
  @override
  bool updateShouldNotifyDependent(
    NakedAccordionScope<T> oldWidget,
    Set<T> dependencies,  // Aspects this widget depends on
  ) {
    // Only notify if THIS widget's aspect changed
    for (final value in dependencies) {
      if (oldWidget.snapshot.isExpanded(value) != snapshot.isExpanded(value)) {
        return true;
      }
      // Also check constraint changes (canCollapse, canExpand)
    }
    return false;
  }
}

// Each accordion item creates an aspect-based dependency
class _NakedAccordionState<T> extends State<NakedAccordion<T>> {
  @override
  Widget build(BuildContext context) {
    // This creates a dependency on THIS item's value only
    final isExpanded = NakedAccordionScope.isExpandedOf<T>(
      context,
      widget.value,  // Aspect = this item's value
    );
    // Widget only rebuilds when THIS value's state changes
  }
}
```

### Immutable Snapshots

The scope uses immutable snapshots for reliable comparison:

```dart
class _AccordionSnapshot<T> {
  final Set<T> expandedValues;  // Immutable copy
  final NakedAccordionController<T> controller;

  bool isExpanded(T value) => expandedValues.contains(value);
  bool canCollapse(T value) => /* constraint logic */;
  bool canExpand(T value) => /* constraint logic */;
}
```

## Performance Comparison

| Metric | Manual Caching | InheritedModel |
|--------|---------------|----------------|
| Rebuilds per change | O(n) calls, O(1) actual builds | O(1) calls, O(1) builds |
| Memory overhead | Caches entire widget trees | No widget caching needed |
| Framework integration | Works against framework | Works with framework |
| Maintenance burden | High (cache invalidation) | Low (declarative) |

## Research Sources

This implementation follows official Flutter guidance:

1. **Flutter API Documentation**: [InheritedModel class](https://api.flutter.dev/flutter/widgets/InheritedModel-class.html)
2. **MediaQuery Implementation**: Flutter's `MediaQuery` extends `InheritedModel<_MediaQueryAspect>` since Flutter 3.10
3. **Performance Best Practices**: [Flutter Performance docs](https://docs.flutter.dev/perf/best-practices)

## Key Principles Applied

1. **Principle of Least Rebuild**: Widgets only subscribe to what they need
2. **Declarative over Imperative**: Let the framework handle caching
3. **Immutable State Snapshots**: Enable reliable change detection
4. **Framework Alignment**: Use patterns Flutter itself uses

## Migration Notes

### Breaking Change

`NakedAccordionScope` constructor changed from:
```dart
// OLD
NakedAccordionScope(controller: controller, child: child)

// NEW
NakedAccordionScope(snapshot: snapshot, child: child)
```

This is an internal API change. Users should use `NakedAccordionGroup` which handles the scope internally.

### Type Constraint

`NakedAccordion<T>` now requires `T extends Object` to satisfy `InheritedModel` constraints. This matches common usage patterns (String, int, enum values).

## Conclusion

The InheritedModel pattern:
- Eliminates manual caching complexity
- Provides surgical O(1) rebuilds
- Follows Flutter's official patterns (MediaQuery, Theme, etc.)
- Reduces maintenance burden
- Improves code clarity

This is the recommended pattern for any widget that needs selective rebuilds based on shared state.
