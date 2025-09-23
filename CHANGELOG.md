

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
