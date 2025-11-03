# Naked UI Example App

A showcase application demonstrating the Naked UI library.

## Getting Started

This project demonstrates how to use the Naked UI library to create customizable UI components with separation of concerns between behavior and appearance.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Testing

This example app includes comprehensive unit and integration tests for all Naked UI components.

### Quick Start - Running Tests

From the project root directory:

```bash
# Run unit tests only
dart tool/test.dart

# Run all tests (unit + integration)
dart tool/test.dart --all

# Run integration tests only
dart tool/test.dart --integration

# Run specific component tests
dart tool/test.dart --component=button
dart tool/test.dart --component=textfield

# Get detailed output for debugging
dart tool/test.dart --all --verbose
```

### Test Types

#### Unit Tests
- Fast, isolated tests for widget behavior
- Located in `test/widget_test.dart`
- Run automatically on every test command

#### Integration Tests
- Full UI automation tests on macOS
- Test real user interactions: hover, click, keyboard navigation
- Located in `integration_test/components/`
- Require macOS platform for UI testing

### Available Integration Test Components

- **button** - NakedButton interactions and states
- **checkbox** - NakedCheckbox toggle and accessibility
- **radio** - NakedRadio selection and groups
- **slider** - NakedSlider dragging and value changes
- **textfield** - NakedTextField input and validation
- **select** - NakedSelect dropdown and selection
- **popover** - NakedPopover positioning and dismissal
- **tooltip** - NakedTooltip display and timing
- **menu** - NakedMenu navigation and actions
- **accordion** - NakedAccordion expand/collapse
- **tabs** - NakedTabs switching and keyboard nav
- **dialog** - NakedDialog modal behavior

### Prerequisites

1. **macOS platform support** (for integration tests):
   ```bash
   flutter create --platforms=macos .
   ```

2. **Flutter dependencies up to date**:
   ```bash
   flutter pub get
   ```

### Troubleshooting

#### Integration Tests Hang or Fail

1. **Check app runs manually first**:
   ```bash
   flutter run -d macos
   ```

2. **Run individual component tests**:
   ```bash
   dart tool/test.dart --component=button
   ```

3. **Use verbose output for details**:
   ```bash
   dart tool/test.dart --integration --verbose
   ```

#### Common Issues

- **Timeout errors**: Integration tests have 5-minute timeout
- **macOS permissions**: Grant screen recording/accessibility permissions if prompted
- **Focus issues**: Tests automatically clean up focus state between runs
- **Gesture cleanup**: Improved hover simulation prevents test interference

#### Test Environment

- **Platform**: macOS required for integration tests
- **Timeout**: 5 minutes for full integration suite
- **Environment**: `RUN_INTEGRATION=1` set automatically
- **Reporter**: Compact by default, expanded with `--verbose`
