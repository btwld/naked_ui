# Naked UI — agent guide

Behavior-first (headless) Flutter component library. Components own
interaction, focus, keyboard, overlay, timer, and semantics behavior; styling
belongs to consumers (primary consumer: Remix for Flutter).

## Layout

- `packages/naked_ui/` — the library. Tests in `test/src` (widget/behavior) and
  `test/semantics`. Public API is exported from `lib/src/naked_widgets.dart`.
- `packages/example/` — canonical example app; real-target integration tests in
  `integration_test/components/`, aggregated by `integration_test/all_tests.dart`
  (a test file not imported there does not run in CI).
- `docs/` — docs.page site. `tool/` — test runners.

## Toolchain and commands

Flutter is pinned by `.fvmrc` (3.41.2); the package floor is `>=3.41.0`.
Pub workspace: run `flutter pub get` at the repo root.

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test
flutter test packages/example/test
cd packages/example && flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Component expansion program

New primitives (Alert Dialog, Link, Field, Toggle Group, Context Menu, Toast,
Hover Card, Combobox) and the test-harness hardening that precedes them are
governed by **[plan/README.md](plan/README.md)**. Before touching component,
test-harness, or CI work in that scope:

1. Read the status board in `plan/README.md` and the phase's plan file.
2. Follow the per-component workflow in `plan/process.md`.
3. Never silently resolve an open decision — record it in `plan/decisions.md`.
4. The binding behavior contracts live in `plan/briefing.md` (frozen reference).

## Conventions that bite

- Either `child` or `builder` is required where a visual surface exists;
  builders receive immutable state snapshots also available via `NakedStateScope`.
- Controlled state: a null callback never mutates a controlled value; effective
  enabled = `enabled` flag AND required callback/controller present.
- Never dispose externally supplied controllers/focus nodes; always dispose
  internal ones.
- No hard-coded English user-facing strings in the package; semantic labels are
  caller-supplied.
- Semantics reference notes: `.claude/semantics_reference.md`.
- `pumpAndSettle()` is unsafe for timer/repeating-animation components — use
  exact pumps or a bounded helper.
