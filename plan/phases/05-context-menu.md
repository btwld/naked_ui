# Phase 05 — Context Menu adapter over Menu

Authority: **active disposable D-03 evidence-spike contract; production
implementation is not approved**.

Status: **the isolated spike is recorded on PR #66 at `2aca8d6`. D-03 remains
open; exports, package production code, registry, aggregate runner, docs,
changelog, and a public Context Menu constructor remain prohibited until the
missing evidence is reviewed and D-03 is explicitly resolved.**

Goal: determine whether secondary-click, touch long-press, keyboard entry, and
a role-neutral semantic long-press action can open existing menu behavior at
the invocation point while preserving Link, selectable-text, row, scrolling,
focus, and exactly-once activation. This phase produces evidence, not a
component.

Spike baseline: Link PR #65 head `52d9c97` stacked on current `origin/main` for
the real Link fixture; repeat final proof after Link merges and the spike is
refreshed from `origin/main`. Contract source: briefing
[§15](../briefing.md#15-component-contract-context-menu). Open gate:
[D-03](../decisions.md#decision-log). Approved cross-cutting D-19 governs
SDK/API use if the spike or phase is activated.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Overlay/menu lifecycle | Flutter `RawMenuAnchor` + `MenuController` | Measure `open(position: ...)` and 3.41/3.44 close ordering in test-only scaffolds; do not create production lifecycle. |
| Position/collision | `OverlayPositioner` | Use a separate test-only geometry probe because the current shell ignores `RawMenuOverlayInfo.position`; do not change the shell in this spike. |
| Items, roles, close-on-select | Existing `NakedMenuItem` and private menu scope | Reuse behind a semantics-excluded, pointer-obscured test scaffold only; never copy the item family. |
| Outside interaction | Existing `TapRegion` behavior through raw menu anchor | Reuse and test; do not stack another global pointer listener. |
| Pointer/keyboard input | Flutter `GestureDetector`, `Shortcuts`, `Actions` | Add only trigger entry paths. |
| Platform behavior reference | Flutter 3.44.6 `CupertinoMenuAnchor`/`CupertinoMenuItem` | Use its long-press, same-gesture swipe, focus, edge, and large-text cases as test input; do not add a styled Cupertino dependency. |
| [`shadcn_flutter` ContextMenu/MenuGroup](../shadcn-flutter-reference.md#component-findings) | Supplies secondary-click/mobile-long-press fixtures and arrow/Enter/Escape navigation inside the open menu, but uses a parallel overlay and omits trigger Shift+F10/Context Menu key and semantic-action contracts. | Use input cases only; keep Flutter raw anchor plus existing Naked Menu behavior. |

`RawMenuAnchor` deliberately does not provide focus or semantics. Naked UI
continues to own those parts. Flutter 3.44.6 differs from 3.41 in raw-menu
close sequencing, so lifecycle tests must run at both ends of the supported
matrix. Private experimental `PopupWindow`/`WindowPositioner` classes under
`package:flutter/src` are not dependencies.

The beta [`TapRegion` semantic-action fix](https://github.com/flutter/flutter/pull/183093)
has not landed in 3.44.6, while master
[`RawMenuAnchor` close-request behavior](https://github.com/flutter/flutter/pull/186376)
may call `onCloseRequested` when already closed. Current-stable tests must
therefore prove semantic activation/outside dismissal directly, and every
close/select completion must be idempotent. Run beta/master as canaries only;
see the shared [watchlist](../flutter-raw-primitives.md#beta-and-master-watchlist).

## Semantics and interaction contract

| Question | Required answer |
|---|---|
| Trigger role | The child keeps its own role (link, text region, row, canvas, etc.); never wrap it as a fake button. |
| Trigger action | Long-press semantic action only if the D-03 AT spike makes the menu discoverable without duplicate activation. |
| Menu | Existing `SemanticsRole.menu` with explicit menu-item children. |
| Pointer open | Secondary tap opens at pointer position; touch long press opens at long-press position. |
| Keyboard open | Context Menu key and Shift+F10 open relative to the focused trigger. |
| Focus on open | Measure current boundary autofocus versus a test-only first-enabled-item probe; current Menu does not focus the first item. |
| Close | Escape/outside interaction/item activation; close callback once. |
| Focus after close | Restore the invoking trigger if still mounted/focusable. |
| Disabled | Trigger paths and semantic long press do nothing; child may retain unrelated native semantics. |

Primary click remains the child's action. A Context Menu wrapper must not
steal it, alter text selection, or consume drag/scroll gestures.

## Ordered work

### 1. Run the D-03 trigger-semantics spike

- Build a disposable fixture around three children: a Link, selectable text,
  and a generic list row. Add secondary tap, long press, Shift+F10, and Context
  Menu key without changing each child's role.
- Inspect Flutter semantics and test VoiceOver/macOS, TalkBack/Android, and
  Chrome accessibility tree/keyboard. Record whether the semantic long-press
  action is exposed, understandable, and activates exactly once.
- Compare touch long-press and same-gesture item selection against
  `CupertinoMenuAnchor` as a behavioral oracle, including large text and all
  viewport edges; do not require its styling or private implementation.
- Confirm primary link activation and text selection remain intact.
- Resolve D-03 with evidence before freezing the public constructor. If no
  discoverable, non-destructive trigger model works, block this component and
  prefer an explicit adjacent menu button in Remix.

Use three bounded variants: V0 preserves the baseline child and has physical/
keyboard entry only; V1 adds role-neutral `Semantics.onLongPress` while the
physical `GestureDetector` is excluded from semantics; V2 is a passive
`Listener` timing probe only if V1 damages selection or scrolling. If only V2
passes, leave D-03 open and stop rather than promoting that machinery.

Split proof into independent axes: trigger semantics/gestures, initial focus
(current boundary versus test-only first enabled item), and point geometry
(`RawMenuAnchor` plus `OverlayPositioner`). Count open requests, actual opens,
close requests, actual closes, selections, and primary-child activations
separately across 3.41.0, 3.41.2, and current stable.

### 2. Keep an exact spike-only file boundary

- `packages/example/lib/src/testing/context_menu_accessibility_spike.dart`
- `packages/example/lib/context_menu_accessibility_spike.dart`
- `packages/example/test/context_menu_accessibility_spike_test.dart`
- `packages/example/integration_test/spikes/context_menu_accessibility_spike_test.dart`
- `packages/example/integration_test/spikes/context_menu_accessibility_at_results.md`

Do not edit `packages/naked_ui/lib/**`, exports, registry,
`integration_test/all_tests.dart`, production docs, or changelog. If the
test-only scaffold cannot reuse existing Menu behavior without changing the
measured child, stop.

### 3. Cover gestures, keyboard, focus, and geometry

- **Where:** the spike test and direct real-target runner above.
- Test secondary tap down/up, touch long press threshold/cancel, primary click
  pass-through, selection drag, scroll cancellation, keyboard keys, disabled
  wrapper, disabled item skip, item callback/close order, Escape/outside close,
  focus restoration, trigger disposal, and rapid reopen.
- Invoke the trigger through a semantics action and test semantic
  inside/outside classification on 3.41.2 and 3.44.6; this cannot be inferred
  from the future beta `TapRegion` fix.
- Verify the menu stays on-screen at all four viewport edges.

### 4. Record deterministic platform and AT proof

- **Where:** the standalone manual runner and spike AT-results record only.
- Stable keys use the `context-menu-spike.*` prefix and cover Link,
  selectable-text, row, menu/items, scroll, state, disable, and reset.
- Run mouse secondary-click on macOS/web, long press on Android, and both
  keyboard entry keys where the platform reports them. Attach edge-position
  screenshots and AT notes.

## Spike evidence

- Preserve exact test/target logs and focused screenshots only when they help
  diagnose geometry or AT output. Do not add production golden baselines or
  screenshot inventories for a disposable spike. Web evidence is the pinned
  headed-Chrome behavior/accessibility log.

## Version and verification matrix

The spike must pass on 3.41.0/3.41.2 and 3.44.6 because it measures raw-menu
open/close ordering. Run existing Menu, Select, and Popover suites on both ends
of the matrix as regression evidence. Add focused beta/master canaries for
the watched `TapRegion` and `RawMenuAnchor` changes; those canaries are not
release proof. Use the exact install/spawn commands in the
[shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix);
the commands below are the workspace slice.

```sh
fvm dart format --set-exit-if-changed packages/example/lib/context_menu_accessibility_spike.dart packages/example/lib/src/testing/context_menu_accessibility_spike.dart packages/example/test/context_menu_accessibility_spike_test.dart packages/example/integration_test/spikes/context_menu_accessibility_spike_test.dart
fvm flutter analyze
fvm flutter test packages/example/test/context_menu_accessibility_spike_test.dart
fvm flutter test packages/naked_ui/test/src/naked_menu_test.dart
fvm flutter test packages/naked_ui/test/src/naked_select_test.dart
fvm flutter test packages/naked_ui/test/src/naked_popover_test.dart
cd packages/example
fvm flutter test -r expanded -d flutter-tester integration_test/spikes/context_menu_accessibility_spike_test.dart
fvm flutter test -r expanded -d macos integration_test/spikes/context_menu_accessibility_spike_test.dart
```

## Stop conditions

Block the phase if preserving the child role makes the menu undiscoverable to
supported AT, semantic long press double-fires, primary link/selection/scroll
behavior is damaged, point positioning cannot remain in the viewport, focus
is lost after close, or the raw-menu lifecycle differs across supported SDKs
in a way that produces duplicate callbacks. Leave D-03 open if Link #65 is not
integrated, any required human AT session is missing, or only the passive V2
gesture probe avoids damage. Stop on any production/public API edit.

## Execution evidence (2026-07-13)

- [PR #66](https://github.com/btwld/naked_ui/pull/66) records the disposable
  spike at `2aca8d6`, based on Link `52d9c97`. Its diff is exactly the five
  authorized spike/evidence files; package production code, exports, registry,
  aggregate runner, production docs, changelog, and goldens are unchanged.
- Flutter 3.41.0, 3.41.2, and 3.44.6 each pass 15 focused tests, 4 target
  integration tests, and 67 Menu/Select/Popover regressions; pinned analysis
  is clean. Real macOS passes 4/4 with exit 0.
- V1 preserves Link role/actions and supports the measured trigger/focus/
  lifecycle/geometry contract. SelectableText exposes duplicate unlabeled
  native/wrapper action paths and prevents wrapper secondary-click/long-press
  open; the generic row remains an unlabeled action, and same-gesture touch
  selection is unproven. These are blockers, not implementation TODOs silently
  accepted by the spike.
- Chrome 150 reports all in-app tests passing but the host result/teardown hangs
  past the bounded timeout and required interruption, so the target is recorded
  as infrastructure-incomplete rather than passing. VoiceOver, TalkBack, and
  headed Chrome accessibility-tree sessions remain unrun. D-03 stays open.

## Acceptance

- [ ] D-03 has recorded VoiceOver, TalkBack, and Chrome evidence.
- [x] Existing item/scope/overlay machinery is reused; no parallel item family exists.
- [ ] Secondary click, long press, Shift+F10, and Context Menu key are proven.
- [ ] Primary child behavior and role remain intact.
- [ ] Edge positioning, close idempotence, restoration, and 3.41/3.44.6 regressions pass.
- [x] The five disposable files and evidence packet are current; no production
      API, registry, aggregate, docs, changelog, or golden surface changed.

## Primary references

- [Flutter `RawMenuAnchor`](https://api.flutter.dev/flutter/widgets/RawMenuAnchor-class.html)
- [Flutter `MenuController.open`](https://api.flutter.dev/flutter/widgets/MenuController/open.html)
- [Flutter `CupertinoMenuAnchor`](https://api.flutter.dev/flutter/cupertino/CupertinoMenuAnchor-class.html)
- [Flutter `TapRegion`](https://api.flutter.dev/flutter/widgets/TapRegion-class.html)
- [WAI-ARIA Menu and Menubar Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/)
