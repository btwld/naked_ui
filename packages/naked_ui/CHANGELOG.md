## Unreleased

### Added

- Added explicit, test-backed semantics contracts across buttons, toggles,
  checkboxes, radios, sliders, menus, selects, tabs, accordions, dialogs,
  tooltips, popovers, and text fields, including roles, states, values,
  actions, labels, focus behavior, and `excludeSemantics` behavior.
- Added semantic value formatting for sliders and selects, dialog role
  selection, tab Home/End navigation, and regression coverage for public
  controller, focus, overlay, state-scope, and lifecycle contracts.

### Changed

- Raised the supported toolchain to Dart 3.11 and Flutter 3.41 so the package
  can use Flutter's current semantics roles and `RawTooltip` contract.
- Invalid runtime configurations now fail with descriptive errors in release
  builds. This includes dismissible dialogs without barrier labels, invalid
  accordion constraints, empty tab identifiers, orphan menu/select items, and
  invalid overlay item construction.
- State snapshots now expose immutable state sets, and component controller
  lookups skip unrelated nested state scopes.
- Simplified overlay hit testing, normalized focus/controller ownership, and
  removed obsolete integration wrappers and unused example dependencies.

### Fixed

- Fixed stale callbacks and generic scope lookup for inferred toggle groups,
  menus, and selects.
- Fixed controller replacement, externally owned focus-node handling, disabled
  state cleanup, and focus restoration across interactive controls.
- Fixed slider bounds, discrete-step rounding, duplicate emissions, RTL and
  vertical dragging, and semantic increment/decrement behavior.
- Fixed accordion FIFO constraints, tab selection double dispatch, roving
  focus, anchored-overlay Home/End navigation, Escape handling, and
  selected-panel semantics.
- Fixed dialog theme capture, barrier validation, dialog/alert-dialog roles,
  text-field controller ownership, native editing defaults, and validation
  semantics.
- Fixed explicit semantic labels being concatenated with duplicate descendant
  labels; caller-provided descendant semantics now remain available when Naked
  UI semantics are excluded.

### Quality

- Enabled strict analysis and complete public API documentation checks, added a
  real coverage gate, made workspace scripts FVM-aware, and aligned CI with the
  checked-in Flutter version.
- Pinned third-party workflow actions to immutable revisions and enabled
  automated GitHub Actions update proposals.
- Reconciled the guides and runnable catalog with the public API, registered the
  tooltip demo, and corrected all example source links.

## 1.0.0-beta.1

- feat(naked-select): add `mouseCursor` property to NakedSelect
- refactor(naked-tooltip): replace `RawMenuAnchor` with `RawTooltip`
- fix: stabilize flaky tests (InkSparkle shader + focus mode)

## 0.2.0-beta.7

- fix: text style handling in NakedTextField
- feat: improve 3.27-safe semantics for menu, select, accordion, checkbox, radio, slider, and text field

## 0.2.0-beta.6

- fix: disabled and error state support for NakedTextField

## 0.2.0-beta.5

- fix: NakedAccordionItemState scope on content
- refactor: remove NakedMenuController typedef

## 0.2.0-beta.4

- docs: refine documentation for developer clarity
- refactor: Simplify NakedTextFieldBuilder signature
- feat: add excludeSemantics parameter to all widgets

## 0.2.0-beta.3

- feat: expose StrutStyle to NakedTextField
- fix: state scope not in the Context
- feat: recreate NakedTooltip widget
- refactor: Overlay Rendering
- docs: Improve the usage examples

## 0.2.0-beta.2

### Bug Fixes

- Fixed `.when` method priority order to prioritize active interaction states (dragged) before selection states

### Improvements

- Added comprehensive test coverage for mixins and utilities

## 0.2.0-beta.1

- Added: Popover; Toggle
- API: Standardized state callbacks (onHoverChange/onPressChange/onFocusChange); removed onDisabledState (use enabled); added onSelectChange/onDragChange where applicable
- Better use of Raw Flutter components where available
- Accessibility: Improved semantics across button, checkbox, radio, slider, select, tabs, dialog, tooltip
- Focus/State: Unified focus handling (FocusNodeMixin) and consistent hover/press/selected for builders

- Architecture: Builder-first APIs (e.g., NakedTextField builder) with state provided via NakedStateScope

## 0.0.1-dev.2 (2025-07-03)

### Features

* "Naked" - A Behavior-First UI Component Library for Flutter ([#579](https://github.com/btwld/naked_ui/issues/579)) ([c55b55f](https://github.com/btwld/naked_ui/commit/c55b55ffa47206fd49da9eebf85e834b5f08220e))
* Add maybeOf helper to InheritedWidgets and refactor of() ([805a37e](https://github.com/btwld/naked_ui/commit/805a37e5a2924e79fe08784ff9ac52b20e59bc44))
* Add maybeOf helper to InheritedWidgets and refactor of() ([805a37e](https://github.com/btwld/naked_ui/commit/805a37e5a2924e79fe08784ff9ac52b20e59bc44))
* Add test for Hover to RadioButton ([#601](https://github.com/btwld/naked_ui/issues/601)) ([8bd0425](https://github.com/btwld/naked_ui/commit/8bd0425150e9d81a03f9885ad493da47ea1080b2))
* Add textStyle prop in NakedTextField  ([#608](https://github.com/btwld/naked_ui/issues/608)) ([4b5252b](https://github.com/btwld/naked_ui/commit/4b5252b7a49d21695a97e806fef5fd9f2d21555a))
* Implement Tooltip Lifecycle ([#603](https://github.com/btwld/naked_ui/issues/603)) ([2ddbf60](https://github.com/btwld/naked_ui/commit/2ddbf60b0a6093b41c193a4fd42259cc40519810))
* Recreate Button using Naked ([#587](https://github.com/btwld/naked_ui/issues/587)) ([0d55724](https://github.com/btwld/naked_ui/commit/0d5572437d4963f13572402128b6a7a85e60aab1))
* Refactor radio and checkbox components with new architecture ([#672](https://github.com/btwld/naked_ui/issues/672)) ([4f3ce7d](https://github.com/btwld/naked_ui/commit/4f3ce7d4023710adb9cc7f4ba751e78d8fe3f3c2))


### Bug Fixes

* Change default autofocus to false in Menu and Select ([#609](https://github.com/btwld/naked_ui/issues/609)) ([76d8736](https://github.com/btwld/naked_ui/commit/76d873661f7cec60195e1a0bdec530936decc82e))


### Miscellaneous Chores

* release 0.0.1-dev.2 ([399a65d](https://github.com/btwld/naked_ui/commit/399a65d6ebe2a5b2089dd233721f91a04dfe9e97))
* release 0.0.1-dev.2 ([6d1ff7f](https://github.com/btwld/naked_ui/commit/6d1ff7fa42c9b47191c5f3e8ac8ec2f26565d29f))
* release 0.0.1-dev.2 ([c1b981e](https://github.com/btwld/naked_ui/commit/c1b981ea029d3da7d7cd25f3197e27b049789d72))

## 0.0.1-dev.0

* Initial development release
* Core functionality for HeadlessButton component
* State management via HeadlessInteractiveStateController
* Support for interactive states (disabled, focused, hovered, pressed)
* Fully customizable rendering via builder pattern
