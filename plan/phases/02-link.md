# Phase 02 — Link

Authority: **active just-in-time execution/evidence plan**.

Status: **[PR #65](https://github.com/btwld/naked_ui/pull/65) is review-ready
at `8084ecf`; the approved correction is implemented and all seven exact-head
hosted checks pass. Phase closure remains blocked by the required web
screenshots, D-19 current-stable compatibility run, human
assistive-technology sessions, real Context Menu/Hover Card composition, merge
authorization, and post-merge verification.**

Goal: ship a headless link interaction primitive with Link rather than Button
semantics, Enter activation, focus/hover/press state, correct unavailable
behavior, and one navigation owner. Delegate default platform navigation and
native web-anchor coordination to Flutter's official `url_launcher.Link`;
allow a consumer callback to replace that default without also navigating.

Planning baseline: workspace `d341b90`; rejected reviewer baseline `2614555`;
approved implementation correction `dc20214`; current PR/docs head `8084ecf`
on 2026-07-13. Contract source: briefing
[§20](../briefing.md#20-component-contract-link), refined by
[approved D-16](../decisions.md#phase-2-decision-evidence-approved-2026-07-13)
and governed by approved
[D-19](../decisions.md#architecture-decision-evidence-approved-2026-07-13).

## Approved correction

`Semantics.linkUrl` is not harmless metadata on Flutter web: the semantics DOM
can expose it as an anchor `href`. D-16 therefore makes `linkUrl` the
destination and availability source. Default navigation uses the official
`url_launcher.Link`; a supplied `onPressed` replaces its follow callback so a
single activation cannot run both custom and browser navigation. The
unavailable path bypasses the official web wrapper because that delegate keeps
Link semantics when `uri == null`.

## Scope

Ship `NakedLink` for a single interactive link child and the direct
`url_launcher: ^6.3.2` dependency needed for official default navigation. Do
not add a router, direct `launchUrl` calls, hand-written DOM anchors,
visited-link history, text styling, a rich-text parser, or button-like Space
activation.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Interaction state | `NakedFocusableDetector` and existing `NakedState` conventions | Reuse focus, hover, press, and effective-enabled behavior. |
| Semantics | Flutter `Semantics(link: true, linkUrl: ...)` plus the official Link delegate | Use one effective link node while available; bypass the delegate and omit Link/URL/action/focus while unavailable. |
| Keyboard | `Shortcuts`/`Actions` with existing activation intents | Enter and Numpad Enter only; leave Space unclaimed. |
| Platform navigation | Official `url_launcher.Link` 6.3.2 | Direct package dependency and default path; a supplied `onPressed` replaces its follow callback. |
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
| Destination | Non-null `linkUrl` is the destination; unavailable links expose no Link flag, URI, anchor, or `href`. |
| Actions | Tap follows the destination by default or calls the override once; no action when unavailable. |
| Keyboard | Enter/Numpad Enter activate once. Space is not consumed and may scroll. |
| Focus | Keyboard-focusable only while effectively enabled; normal traversal order. |
| Pointer | Primary tap activates once; hover/press states are observable. Native browser coordination belongs to the official Link delegate; secondary click remains unclaimed by Naked UI. |
| Disabled | No focus, tap, semantic action, destination, or pointer state transition. |
| Selection | Composing near selectable/rich text must not break text selection or create duplicate nodes. |

## Executed correction and proof

### 1. Establish one navigation owner

- `linkUrl` now controls destination and availability.
- Default activation delegates to official `url_launcher.Link`; a supplied
  `onPressed` replaces default navigation rather than composing a second
  navigation path.
- Production code does not call `launchUrl` directly or coordinate DOM events.

### 2. Correct unavailable destination semantics

- Effective enabled state is `enabled && linkUrl != null`.
- The unavailable path omits the official Link wrapper, Link flag, URL,
  semantic tap, focus path, native anchor, and `href`. The consumer child stays
  discoverable as ordinary unavailable content because HTML has no disabled
  anchor contract.
- A keyed inner detector preserves a consumer's stateful subtree while the
  official wrapper enters or leaves the widget tree.

### 3. Prove key, pointer, selection, and lifecycle boundaries

- Tests cover Enter/Numpad Enter once per physical key sequence, Space
  pass-through and web scrolling, primary activation, canceled/secondary
  pointer paths, semantic tap, ancestor and null-destination unavailability,
  directional focus, selectable/rich text, focus ownership, and disposal.
- Removing a destination synchronizes transient state during
  `didUpdateWidget` without calling consumers during build; ended-state
  callbacks are delivered after the frame.
- Re-enabling below a stationary pointer restores hover after layout.

### 4. Prove real browser ownership

- The pinned-Chrome in-app test coordinates the default semantic action and
  DOM event, proving an unsuppressed native destination outcome. A separate
  W3C WebDriver test performs a trusted click on the custom override and proves
  exactly one callback without navigation.
- Dynamically removing the destination removes the anchor/`href` and cannot
  activate.
- Flutter semantics tests separately prove one Link role/URL/action while
  available and none while unavailable.

### 5. Complete canonical fixture and available platform proof

- The deterministic fixture, registry entry, focused integration file,
  aggregate registration, inventory guard, accessibility guideline tests, and
  reviewed Ubuntu golden are present on PR #65.
- Flutter-tester, real macOS, pinned Chrome, exact Flutter 3.41.0, primary
  Ubuntu, API 34 Android, and PR-title checks all pass on exact head `8084ecf`.
- Exact-head evidence is in
  [Flutter CI run 29271218258](https://github.com/btwld/naked_ui/actions/runs/29271218258),
  [integration run 29271218352](https://github.com/btwld/naked_ui/actions/runs/29271218352),
  [web run 29271218418](https://github.com/btwld/naked_ui/actions/runs/29271218418),
  [Android run 29271218265](https://github.com/btwld/naked_ui/actions/runs/29271218265),
  and
  [PR-title run 29271218006](https://github.com/btwld/naked_ui/actions/runs/29271218006).
- VoiceOver, TalkBack, Chrome accessibility-tree, release-iOS VoiceOver, and
  the unsupported Flutter 3.41.2 web screenshots remain honest blockers. The
  newly approved D-19 current-stable compatibility gate also remains open.

### 6. Correct public documentation

- API docs, package/root READMEs, changelog, and examples describe destination
  ownership, default navigation, the custom override, effective enabled state,
  Enter/Space behavior, and browser/composition boundaries.
- The implementation remains headless: styling, localized content, router
  policy, and visited history stay with the consumer.

## Visual evidence

- Reviewed golden:
  `packages/example/test/goldens/components/baselines/naked_link__keyboard_focus.png`.
- Reviewed real-target artifacts: macOS default inline, keyboard focus, and
  200% long text; API 34 Android unavailable state.
- Required web hover, external-hint, and RTL screenshots remain unsupported on
  Flutter 3.41.2. Chrome behavior/DOM logs do not substitute for them.

## Verification

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_link_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_link_semantics_test.dart
fvm flutter test packages/naked_ui/test
fvm flutter test packages/example/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_link_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart

# exact declared minimum, from the repository root
cd ../..
fvm install 3.41.0 --skip-pub-get
fvm spawn 3.41.0 pub get
fvm spawn 3.41.0 analyze
fvm spawn 3.41.0 test packages/naked_ui/test
```

The pinned-Chrome integration workflow is authoritative for DOM and browser
behavior; exact-head real macOS and hosted API 34 proof are present. Required
web screenshots, manual VoiceOver/TalkBack/Chrome-tree sessions, and release
iOS proof remain open under
[integration-testing.md](../integration-testing.md).

## Stop conditions

Block release if disabled output retains an `href`, a key/pointer path invokes
the callback twice, Space is consumed, selectable text becomes unusable, the
web DOM exposes duplicate anchors, or real assistive technology reports a
button/duplicate link instead of one named link.

## Acceptance

- [x] Approved D-16 navigation ownership is implemented without direct launcher
      or DOM coordination in Naked UI.
- [x] Unavailable links expose neither action, Link semantics, destination,
      anchor, nor `href` in automated target proof.
- [x] Enter activates once; Space remains available to its ancestor; lifecycle,
      stationary-hover, directional-focus, and selectable/rich-text regressions
      pass.
- [x] Default, custom-override, and unavailable browser paths are proven with
      the official Link delegate on pinned Chrome; the custom path includes a
      trusted W3C WebDriver click.
- [x] All seven hosted checks pass on exact PR head `8084ecf`.
- [ ] The required current-stable compatibility gate passes without using
      post-minimum production APIs.
- [ ] Required web screenshots and VoiceOver/TalkBack/Chrome-tree/release-iOS
      records are attached.
- [ ] Real Context Menu and Hover Card implementations compose around Link.
- [ ] Maintainer authorizes merge and post-merge `main` workflows pass.

## Primary references

- [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter `SemanticsProperties.linkUrl`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/linkUrl.html)
- [`url_launcher` `Link`](https://pub.dev/documentation/url_launcher/latest/link/Link-class.html)
- [`url_launcher` 6.3.2 `Link` source](https://github.com/flutter/packages/blob/url_launcher-v6.3.2/packages/url_launcher/url_launcher/lib/src/link.dart)
- [`url_launcher_web` 2.4.3 Link delegate source](https://github.com/flutter/packages/blob/url_launcher_web-v2.4.3/packages/url_launcher/url_launcher_web/lib/src/link.dart)
- [WAI-ARIA Link Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/link/)
- [WHATWG disabled elements](https://html.spec.whatwg.org/multipage/semantics-other.html#disabled-elements)
