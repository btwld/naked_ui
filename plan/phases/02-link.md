# Phase 02 — Link completion and web-contract correction

Status: **Implementation open in [PR #65](https://github.com/btwld/naked_ui/pull/65); changes required before approval.**

Goal: ship a truly headless link interaction primitive with link semantics,
Enter activation, focus/hover/press state, correct disabled behavior, and an
honest web contract. Preserve consumer choice over navigation and URL-launching
policy.

Planning baseline: workspace `d341b90`; reviewed PR head `2614555` on
2026-07-13. Contract source: briefing
[§20](../briefing.md#20-component-contract-link), refined by
[D-16](../decisions.md#component-plan-decision-evidence-2026-07-13).

## Required correction

`Semantics.linkUrl` is not harmless metadata on Flutter web: the semantics DOM
can expose it as an anchor `href`. PR #65 must stop describing it as metadata
only, must omit it when the link is effectively disabled, and must prove actual
DOM/browser behavior. Naked UI still does not decide how an app navigates.

## Scope

Ship `NakedLink` for a single interactive link child. Do not add a router,
URL-launcher dependency, visited-link history, text styling, a rich-text
parser, or button-like Space activation.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Interaction state | `NakedFocusableDetector` and existing `NakedState` conventions | Reuse focus, hover, press, and effective-enabled behavior. |
| Semantics | Flutter `Semantics(link: true, linkUrl: ...)` | Use one link node; only expose the URI while enabled. |
| Keyboard | `Shortcuts`/`Actions` with existing activation intents | Enter and Numpad Enter only; leave Space unclaimed. |
| Native web navigation | Official `url_launcher.Link` | Prove and document an optional consumer/example composition; no core dependency by default. |
| [`shadcn_flutter` `Button.link`](../shadcn-flutter-reference.md#component-findings) | A visual button variant whose generic clickable activates on Enter and Space and establishes no link destination contract. | Negative reference only; it cannot replace semantic/native Link behavior. |

The stable, beta, and master audit found no Flutter-core raw Link primitive.
Material/Cupertino do not provide a lower-level cross-platform Link widget.
Flutter semantics plus the official `url_launcher` package therefore remain
the relevant public layers; do not wait for or invent a framework wrapper.
See the shared [raw-primitives mapping](../flutter-raw-primitives.md#component-by-component-result).

## Semantics and interaction contract

| Question | Required answer |
|---|---|
| Role | Exactly one link node, never a button node. |
| Name | Derived from the child unless `semanticLabel` is supplied; no duplicate child label. |
| Destination | Enabled links may expose `linkUrl`; disabled links expose no URI/`href`. |
| Actions | Tap when enabled; no action when disabled. |
| Keyboard | Enter/Numpad Enter activate once. Space is not consumed and may scroll. |
| Focus | Keyboard-focusable only while effectively enabled; normal traversal order. |
| Pointer | Primary tap activates once; hover/press states are observable. Secondary/modifier behavior belongs to the chosen native-link adapter. |
| Disabled | No focus, tap, semantic action, destination, or pointer state transition. |
| Selection | Composing near selectable/rich text must not break text selection or create duplicate nodes. |

## Ordered work

### 1. Reduce and sequence PR #65

- Rebase after PR #64 because both branches touch registry, aggregate tests,
  docs navigation, CI, and changelog files.
- Remove the roughly 3.5K-line planning corpus from the component PR; land
  planning separately or keep only this phase plan if maintainers want it in
  the same PR.
- **Verify:** the PR diff contains Link source, focused tests, fixture,
  integration registration, docs, and release note only.

### 2. Correct disabled destination semantics

- **Where:** proposed `packages/naked_ui/lib/src/naked_link.dart`.
- Compute effective enabled once. Pass `linkUrl` to `Semantics` only when true;
  disabled output must not contain a tap action or destination.
- Preserve the builder/child invariant and state scope. Do not create a
  GestureDetector plus Semantics action that can double-fire.
- **Tests:** proposed `packages/naked_ui/test/src/naked_link_test.dart` and
  `packages/naked_ui/test/semantics/naked_link_semantics_test.dart`.

### 3. Prove key and pointer boundaries

- Test Enter and Numpad Enter from primary focus, Space pass-through, repeated
  key-up/down behavior, primary pointer activation, hover/press transitions,
  ancestor-disabled state, semantic tap, and disposal during activation.
- Add a scrollable fixture proving Space still scrolls while the link is
  focused.
- Add a selectable-text composition fixture and verify dragging selects text
  without accidental activation.

### 4. Run a native-link composition spike

- **Where:** example-only fixture/test; keep `url_launcher` outside
  `packages/naked_ui/pubspec.yaml` unless a separate dependency decision is
  approved.
- Compare `NakedLink` alone with `url_launcher.Link` supplying its
  `followLink` callback. Inspect whether nested/merged semantics produce one
  link node and one DOM anchor.
- On Chrome, verify `href`, disabled URI removal, primary activation, keyboard
  activation, Cmd/Ctrl-click, Shift-click, context menu, and target behavior.
- If composition duplicates semantics or anchors, document the supported
  boundary instead of adding a broad escape hatch blindly: consumers use
  `url_launcher.Link` for browser-native navigation and reuse Naked UI's
  visual builder/state only through the smallest reviewed adapter.

### 5. Complete canonical fixture and platform proof

- **Where:** proposed `packages/example/lib/api/naked_link.0.dart`,
  `packages/example/lib/registry.dart`,
  `packages/example/integration_test/components/naked_link_integration.dart`,
  and `packages/example/integration_test/all_tests.dart`.
- Stable keys: enabled link, disabled link, scroll container, activation
  count, destination readout, and reset.
- Record VoiceOver, TalkBack, and Chrome tree/DOM results for enabled,
  disabled, custom label, and selectable-text cases.

### 6. Correct documentation

- **Where:** proposed `docs/widget/link.mdx`, API docs, `CHANGELOG.md`.
- State that `linkUrl` can affect platform output, that `onPressed` remains
  caller navigation policy, and which native-browser behaviors require the
  official `url_launcher.Link` composition.
- Include a router callback example and, only if the spike passes, an official
  Link composition example.

## Planned visual evidence

- Screenshots: `link__focus_and_disabled__macos__reference.png` and
  `link__large_text_rtl__android__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_link__states.png`.
- Chrome contributes DOM, modifier-key, selection, and accessibility-tree logs;
  do not substitute an unstable Flutter 3.41 web screenshot.

## Verification

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test packages/naked_ui/test/src/naked_link_test.dart
flutter test packages/naked_ui/test/semantics/naked_link_semantics_test.dart
flutter test packages/naked_ui/test
flutter test packages/example/test
cd packages/example
flutter test -r compact -d flutter-tester integration_test/components/naked_link_integration.dart
flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

The pinned-Chrome integration workflow is authoritative for DOM and browser
behavior. Real macOS, Android, manual VoiceOver/TalkBack, and release iOS proof
remain required by [integration-testing.md](../integration-testing.md).

## Stop conditions

Block release if disabled output retains an `href`, a key/pointer path invokes
the callback twice, Space is consumed, selectable text becomes unusable, the
web DOM exposes duplicate anchors, or real assistive technology reports a
button/duplicate link instead of one named link.

## Acceptance

- [ ] PR #65 is rebased after Alert Dialog and contains one component contract.
- [ ] Disabled links expose neither action nor destination on every target.
- [ ] Enter activates once; Space remains available to its ancestor.
- [ ] One supported native-link composition is proven or the unsupported boundary is explicit.
- [ ] Chrome DOM/modifier/context behavior and VoiceOver/TalkBack semantics are recorded.
- [ ] Example, docs, changelog, traceability table, and status board are current.

## Primary references

- [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter `SemanticsProperties.linkUrl`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/linkUrl.html)
- [`url_launcher` `Link`](https://pub.dev/documentation/url_launcher/latest/link/Link-class.html)
- [WAI-ARIA Link Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/)
