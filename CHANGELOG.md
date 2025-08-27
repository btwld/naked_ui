## [0.1.0] - 2025-08-27

### ⚠️ BREAKING CHANGES

- **API Change**: Standardized state callback naming convention across all components:
  - `onStateHover` → `onHoverChange`
  - `onStatePressed` → `onPressChange`
  - `onStateFocus` → `onFocusChange`
  - `onStateDragging` → `onDragChange` (NakedSlider)
  - `onStateSelected` → `onSelectChange` (NakedRadio, NakedSelectItem)
- **Removed Callbacks**:
  - `onDisabledState` removed from NakedButton and NakedMenu (use `enabled` property instead)
- **Migration Required**: Existing code using the old callback names will need updates
- See [MIGRATION.md](./MIGRATION.md) for detailed migration instructions

### Added
- Comprehensive migration guide (MIGRATION.md) for upgrading from pre-v0.1.0 versions

### Fixed
- Inconsistent callback naming patterns across components
- Updated outdated documentation to reflect current API conventions

### Documentation  
- Updated all widget documentation to match implemented API
- Fixed outdated examples in documentation files
- Ensured consistency between code and documentation

---

## 0.0.1-dev.1

 - **REFACTOR**: Select (#596).
 - **REFACTOR**: Tabs and Tooltip (#595).
 - **REFACTOR**: Naked Slider (#594).
 - **REFACTOR**: radio group (#593).
 - **REFACTOR**: naked menu (#592).
 - **REFACTOR**: accordion (#591).
 - **REFACTOR**: Refactor Checkbox (#590).
 - **REFACTOR**: update outdated API (#583).
 - **FIX**: Change default autofocus to false in Menu and Select (#609).
 - **FEAT**: Add textStyle prop in NakedTextField  (#608).
 - **FEAT**: Implement Tooltip Lifecycle (#603).
 - **FEAT**: Add test for Hover to RadioButton (#601).
 - **FEAT**: Recreate Button using Naked (#587).
 - **FEAT**: "Naked" - A Behavior-First UI Component Library for Flutter (#579).
 - **DOCS**: organize folders and files.
 - **DOCS**: Improve accordion example.
 - **DOCS**: Remove old example app (#607).
 - **DOCS**: Document naked button (#599).

# Changelog

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
