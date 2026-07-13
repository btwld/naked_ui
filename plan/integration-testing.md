# Integration testing playbook

This is the operational companion to the binding verification contracts in
[briefing §12](briefing.md#12-verification-architecture) and
[briefing §21](briefing.md#21-integration-screenshot-golden-and-ci-implementation).
It applies to every component phase. If this playbook and the frozen briefing
ever conflict, stop and resolve the conflict explicitly; do not weaken the
briefing silently.

The rules below incorporate the failures and fixes from Phase 0 / PR #63.

## 1. Choose the cheapest test layer that proves the behavior

- Use unit tests for pure state, equality, controller, queue, timer, and
  geometry logic.
- Use widget and semantics tests for one component tree, callbacks, focus,
  keyboard mappings, semantics properties/actions, disposal, and fake-frame
  timing.
- Use integration tests only for behavior that needs the canonical example or
  a real platform: platform focus, pointer/hover, text input, overlays,
  browser behavior, screenshots, and cross-component flows.
- Keep data local and deterministic. Register fakes before pumping the app; no
  production services, live APIs, current time, randomness, or network images.
- Give every driven control a stable `ValueKey`. A phase plan must list the
  fixture keys before implementation begins.

Every contract requirement must map to the cheapest owning test plus any
real-target proof it needs. An integration test is not a substitute for exact
widget or semantics assertions.

## 2. Authoritative runners

| Proof | Authoritative command/path | Rule |
|---|---|---|
| Fast aggregate | `flutter test -r compact -d flutter-tester integration_test/all_tests.dart` from `packages/example` | Proves aggregate registration and shared behavior quickly. |
| Real macOS behavior | Same command with `-d macos` | Must run on a real macOS target; a macOS host using `flutter-tester` is not macOS proof. |
| Android behavior | `flutter test -r compact -d <emulator> integration_test/all_tests.dart` | Native behavior is authoritative. `flutter drive` is reserved for screenshot/report-data transport. |
| Web behavior | `flutter drive` with `test_driver/integration_test_behavior.dart`, `-d web-server`, and `--browser-name=chrome` | Flutter web integration uses a driver; do not replace this with `flutter test -d chrome`. |
| Screenshot evidence | Dedicated `integration_test/screenshot_smoke.dart` with `test_driver/integration_test.dart` | Behavior must pass independently before evidence capture runs. |

Use the checked-in workflows and scripts as the executable source of truth:

- `.github/workflows/integration-tests.yml`
- `.github/workflows/integration-android.yml`
- `.github/workflows/integration-web.yml`
- `tool/run_android_integration.sh`
- `tool/run_integration_all.sh`

Do not combine native behavior and host-transport evidence into one result that
can hide an in-app failure. Keep the behavior aggregate and screenshot smoke as
separate blocking steps.

## 3. Aggregate registration

- Add every `integration_test/components/*_integration.dart` file to
  `integration_test/all_tests.dart` and invoke its `main` in a named group.
- Run `packages/example/test/integration_inventory_test.dart`; importing or
  creating a file without registering it in the aggregate is not delivery.
- Run the new component file directly while iterating, then run the aggregate.
  A direct-file pass alone is insufficient.
- Keep the aggregate timeout bounded. Do not raise the shared two-minute
  per-test timeout to make one slow or hung test green.

## 4. Assertions must prove outcomes

- Focus through a known `FocusNode`, pump one frame, assert primary focus,
  send one complete logical key event, then assert the value, callback, overlay,
  route, focus, or visible result.
- For disabled paths, prove focus/action refusal and assert no state changed.
- Test pointer and semantic activation against the same observable callback
  contract where both are supported.
- Do not assert only that a widget still exists after an interaction.
- Do not catch and return `false`, catch and log, or otherwise turn a failed
  key, pointer, semantics, screenshot, or cleanup operation into a green test.
- Cleanup runs in `finally`/teardown and cleanup failures fail the test. Never
  suppress `removePointer`, gesture release, controller disposal, or overlay
  removal errors.

## 5. Deterministic time and pumping

- Use `pump()` for one state/focus application frame.
- Use an exact `pump(duration)` only when the duration is a public invariant.
- Use the shared bounded `pumpUntil` for asynchronous observable state whose
  completion time is not contractual. The predicate must observe the real
  state under test, and timeout must fail with a diagnostic.
- Do not fix a slow runner with extra padding frames, a real
  `Future.delayed`, retries, or a larger blanket timeout.
- `pumpAndSettle()` is allowed only when the tree is known to settle. It is
  forbidden around live timers, cursor blinking, repeating/indeterminate
  animation, pending hover-card delays, or active toast timers.
- Drive timers with fake frame time. Verify just-before, at-boundary, pause,
  resume with remaining duration, cancellation, and disposal paths.
- Reset viewport/DPR, focus, pointer, lifecycle, controllers, overlays, and
  any global test configuration through teardown-safe cleanup.

The delayed hover failure from Phase 0 is the reference pattern: wait for the
observable hover state with a bound, not a guessed 32 ms frame; then propagate
pointer cleanup failures.

## 6. Platform rules

### macOS

- Confirm `flutter devices` lists macOS and run with `-d macos`.
- If sandboxed IO/network behavior is introduced, review both debug/profile
  and release entitlements. Run `flutter clean` after entitlement changes.
- A Flutter-tool foreground warning is evidence to investigate, not a reason
  to retry. Reproduce the smallest failing file, inspect `flutter doctor -v`,
  and compare with the pinned hosted macOS run.
- Moving stalls across unrelated tests indicate a runner/toolchain problem;
  stable failure at one assertion indicates test or product behavior. Record
  that distinction and never mask either with retries.

### Android

- Check `flutter devices` and `adb devices` before claiming a local run.
- Use `flutter test` for behavior and the checked-in Android script for the
  behavior-plus-screenshot CI sequence.
- If no local SDK/emulator exists, say so and use the hosted API 34 result as
  the authoritative Android proof. Missing local hardware is not permission to
  omit the platform gate.
- Exercise touch/long-press, safe-area/keyboard inset, and TalkBack-oriented
  paths on Android when the component contract requires them.

### Web

- Chrome and ChromeDriver must match by major version. Record both versions.
- Start ChromeDriver on port 4444, retain its PID, and arrange cleanup with a
  shell trap or an equivalent lifecycle step.
- Use `-d web-server --browser-name=chrome`; keep browser dimensions explicit
  for fixture evidence.
- Web-targeted Dart code must not import `dart:io`; use conditional imports.
- Flutter finders drive the Canvas-rendered widget tree. Browser URL, history,
  cookies, or DOM-only assertions require a browser-level seam and must not be
  inferred from widget finders.
- Preserve the full web log. A successful command must contain the success
  marker and no in-app timeout/failure marker; a host process exit code alone
  is not sufficient evidence.

Flutter 3.41.2 cannot currently produce stable web screenshot evidence in this
repository. Do not claim a web screenshot passed. Before closing a component
phase, either establish a stable reviewed capture path on the pinned toolchain
or obtain an explicit maintainer decision for alternate evidence. Until then,
the pinned web behavior log is required but does not satisfy a binding web
screenshot requirement by itself.

### iOS and assistive technology

- The current automated matrix does not prove iOS. Record the required manual
  iOS release check separately.
- Semantics-tree assertions do not replace VoiceOver, TalkBack, or Chrome
  accessibility-tree results. Record target, OS/browser, AT version, actions,
  expected versus actual behavior, tester, and date.

## 7. Screenshots, goldens, and accessibility evidence

- Run behavior assertions before capturing a screenshot.
- Real-target screenshots are review artifacts, not cross-platform pixel
  goldens. Goldens use the pinned Ubuntu image, Flutter SDK, checked-in font,
  800×600 surface, DPR 1, locale/direction/text scale/brightness, and fixed
  animation state.
- Android prepares the native surface once before capture. On Flutter 3.41.2,
  macOS uses the reviewed `RepaintBoundary` fallback and standard binding
  report data because the native screenshot plugin is unavailable.
- Use `component__scenario__platform__theme.png`; include the tested SHA,
  Flutter version, target, surface, DPR, locale/direction, text scale,
  animation mode, result, and reviewer in the manifest/handoff.
- For pull requests, distinguish the reviewed head SHA from GitHub's tested
  merge-ref SHA. After merge, record the resulting main commit as well.
- Run accessibility guidelines on the canonical styled example, never only on
  the headless wrapper. Dispose the semantics handle in teardown-safe cleanup.
- A screenshot proves appearance only. Keyboard, focus, semantics, lifecycle,
  and callback behavior require separate assertions.

## 8. Failure-triage protocol

When any local or hosted integration check fails:

1. Record the exact SHA, target/device, Flutter/Dart version, OS/Xcode or
   Chrome/ChromeDriver version, command, first failing assertion, and full log.
2. Run the smallest failing component file on the same target; then run the
   aggregate to detect ordering or leaked-state effects.
3. Reproduce at least twice without adding a retry to the gate. Compare other
   targets only to classify the boundary, not to dismiss the failing target.
4. Inspect the observable state, focus node, pointer lifecycle, scheduled
   frames, widget tree, and platform connection relevant to the first failure.
5. Fix the root condition. For timing, wait on observable state; for cleanup,
   propagate the error; for platform setup, fix the target/toolchain.
6. Add or strengthen the smallest regression test and prove that it fails
   against the old behavior before accepting the green result.
7. Rerun format, analysis, the focused regression, package/example suites,
   aggregate `flutter-tester`, and every affected real target.
8. Monitor the exact PR head checks and the workflows triggered by the merged
   commit. Do not rely on an older green SHA.

Stop and escalate instead of merging when:

- a required target cannot run and no authoritative hosted result exists;
- the same test remains flaky without a root cause;
- a required test is absent from the aggregate;
- a driver or helper can swallow an in-app or cleanup failure;
- required screenshot or manual AT evidence is unsupported or missing;
- a platform result contradicts the component contract.

Quarantine is allowed only with a linked issue, owner, reason, and removal
date, and the component cannot be described as fully validated while
quarantined.

## 9. Per-phase integration checklist

Every just-in-time phase plan must name:

- [ ] The requirement-to-test map and why each integration scenario needs a
      real target rather than only a widget test.
- [ ] The integration file, aggregate group, stable fixture keys, deterministic
      local data, and reset behavior.
- [ ] Pointer, keyboard/focus, semantics action, disabled, RTL, 200% text,
      collision/inset, dynamic-removal, and disposal scenarios that apply.
- [ ] Exact pumps or observable `pumpUntil` conditions, timeout diagnostics,
      and teardown ownership.
- [ ] The platform matrix: `flutter-tester`, real macOS, API 34 Android, pinned
      web, and any explicit N/A with justification.
- [ ] Screenshot names, golden cases, manifest metadata, accessibility
      guidelines, and manual AT sessions.
- [ ] Exact local commands, unavailable local targets, hosted jobs, artifact
      locations, and reviewed/tested SHAs.

A phase cannot close until every applicable item is evidenced or an explicit
blocking decision is recorded.
