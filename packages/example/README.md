# Naked UI example

This app is the executable catalog for `naked_ui`. It demonstrates every
component, custom styling through builders, keyboard interaction, and
accessibility semantics.

## Run

From the repository root:

```sh
fvm flutter pub get
cd packages/example
fvm flutter run
```

Generate a native platform directory first when your target is not already
present, for example `fvm flutter create --platforms=macos .`.

## Verify

The fast widget suite runs on `flutter-tester`:

```sh
fvm flutter test packages/example/test
```

Run the complete integration suite from this directory:

```sh
fvm flutter test integration_test/all_tests.dart -d flutter-tester
```

The repository runner can execute unit tests, integration tests, or one
component from the root:

```sh
fvm dart tool/test.dart
fvm dart tool/test.dart --all
fvm dart tool/test.dart --component=button
```

Available component names are `button`, `checkbox`, `radio`, `slider`,
`textfield`, `select`, `popover`, `tooltip`, `menu`, `accordion`, `tabs`, and
`dialog`.
