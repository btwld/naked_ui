# Phase 05 — Context Menu adapter over Menu

Authority: **inactive research/spike draft; neither spike nor implementation is
approved by this file**.

Status: **Implementation remains blocked until an explicitly approved
trigger-semantics spike produces the real AT evidence needed for D-03.**

Goal: add secondary-click, touch long-press, and keyboard context-menu entry
to the existing menu implementation, opening at the invocation point while
preserving the trigger child's real semantic role and reusing all menu-item
behavior.

Planning baseline: `d341b90` on 2026-07-13. Contract source: briefing
[§15](../briefing.md#15-component-contract-context-menu). Open gate:
[D-03](../decisions.md#decision-log). Cross-cutting D-19 also requires
approval before activation.

## Reuse before new machinery

| Need | Reuse | Decision |
|---|---|---|
| Overlay/menu lifecycle | Flutter `RawMenuAnchor` + `MenuController` | Use `open(position: ...)`; do not create `OverlayEntry` lifecycle. |
| Position/collision | `AnchoredOverlayShell` and `OverlayPositioner` | Add a private anchor-rect resolver; default behavior stays unchanged. |
| Items, roles, close-on-select | Existing `NakedMenuItem` and private menu scope | Implement in `naked_menu.dart` so the item family is not copied or made public internally. |
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
| Focus on open | First enabled item, using existing menu focus behavior. |
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

### 2. Add a private point-anchor hook

- **Where:** `packages/naked_ui/lib/src/utilities/anchored_overlay_shell.dart`
  and `packages/naked_ui/lib/src/utilities/positioning.dart` tests.
- Add an internal callback that derives the overlay anchor rect from
  `RawMenuOverlayInfo`; its default returns the existing `anchorRect`, so Menu,
  Select, Popover, and Tooltip behavior cannot change.
- Context Menu derives a zero-size rect from
  `info.anchorRect.topLeft + info.position` for pointer opens and uses the
  normal trigger rect for keyboard opens.
- Test viewport edges, transform/scroll, RTL, text scale, and trigger removal.

### 3. Implement the adapter without duplicating menu items

- **Where:** `packages/naked_ui/lib/src/naked_menu.dart` and export barrel.
- Add `NakedContextMenu<T>` in this file so it can reuse the private menu scope
  and `NakedMenuItem<T>`. Share effective-enabled, selection, open/close, and
  focus-restoration paths with `NakedMenu`.
- Track open reason/position only as behavior state for builders. Clear stale
  pointer coordinates before keyboard opens.
- Make close and select callbacks idempotent across 3.41/3.44.6 raw-menu
  lifecycle ordering and the watched master close-while-closed behavior.

### 4. Cover gestures, keyboard, focus, and regression

- **Where:** proposed `naked_context_menu_test.dart` and
  `naked_context_menu_semantics_test.dart`, plus regression tests in existing
  menu/select/popover suites for the private shell change.
- Test secondary tap down/up, touch long press threshold/cancel, primary click
  pass-through, selection drag, scroll cancellation, keyboard keys, disabled
  wrapper, disabled item skip, item callback/close order, Escape/outside close,
  focus restoration, trigger disposal, and rapid reopen.
- Invoke the trigger through a semantics action and test semantic
  inside/outside classification on 3.41.2 and 3.44.6; this cannot be inferred
  from the future beta `TapRegion` fix.
- Verify the menu stays on-screen at all four viewport edges.

### 5. Add deterministic fixture and platform proof

- **Where:** proposed `packages/example/lib/api/naked_context_menu.0.dart`,
  registry, `packages/example/integration_test/components/naked_context_menu_integration.dart`,
  aggregate runner, `docs/widget/context-menu.mdx`, and changelog.
- Stable keys: `context-menu.trigger`, `.menu`, `.item.rename`, `.item.delete`,
  `.value`, `.disable`, and `.reset`.
- Run mouse secondary-click on macOS/web, long press on Android, and both
  keyboard entry keys where the platform reports them. Attach edge-position
  screenshots and AT notes.

## Planned visual evidence

- Screenshots: `context_menu__pointer_edge__macos__reference.png` and
  `context_menu__long_press__android__reference.png`.
- Golden: `packages/example/test/goldens/components/baselines/naked_context_menu__open.png`.
- Web evidence is the pinned Chrome behavior/accessibility log until stable
  screenshot capture is supported.

## Version and verification matrix

The component must pass on 3.41.0/3.41.2 and 3.44.6 because it depends on raw
menu open/close ordering. Run existing Menu, Select, and Popover suites on both
ends of the matrix, not just the new test. Add focused beta/master canaries for
the watched `TapRegion` and `RawMenuAnchor` changes; those canaries are not
release proof. Use the exact install/spawn commands in the
[shared SDK matrix](../process.md#executable-sdk-and-local-command-matrix);
the commands below are the workspace slice.

```sh
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test packages/naked_ui/test/src/naked_context_menu_test.dart
fvm flutter test packages/naked_ui/test/semantics/naked_context_menu_semantics_test.dart
fvm flutter test packages/naked_ui/test/src/naked_menu_test.dart
fvm flutter test packages/naked_ui/test/src/naked_select_test.dart
fvm flutter test packages/naked_ui/test/src/naked_popover_test.dart
fvm flutter test packages/naked_ui/test
cd packages/example
fvm flutter test -r compact -d flutter-tester integration_test/components/naked_context_menu_integration.dart
fvm flutter test -r compact -d flutter-tester integration_test/all_tests.dart
```

## Stop conditions

Block the phase if preserving the child role makes the menu undiscoverable to
supported AT, semantic long press double-fires, primary link/selection/scroll
behavior is damaged, point positioning cannot remain in the viewport, focus
is lost after close, or the raw-menu lifecycle differs across supported SDKs
in a way that produces duplicate callbacks.

## Acceptance

- [ ] D-03 has recorded VoiceOver, TalkBack, and Chrome evidence.
- [ ] Existing item/scope/overlay machinery is reused; no parallel item family exists.
- [ ] Secondary click, long press, Shift+F10, and Context Menu key are proven.
- [ ] Primary child behavior and role remain intact.
- [ ] Edge positioning, close idempotence, restoration, and 3.41/3.44.6 regressions pass.
- [ ] Example, aggregate, docs, changelog, evidence packet, and status board are current.

## Primary references

- [Flutter `RawMenuAnchor`](https://api.flutter.dev/flutter/widgets/RawMenuAnchor-class.html)
- [Flutter `MenuController.open`](https://api.flutter.dev/flutter/widgets/MenuController/open.html)
- [Flutter `CupertinoMenuAnchor`](https://api.flutter.dev/flutter/cupertino/CupertinoMenuAnchor-class.html)
- [Flutter `TapRegion`](https://api.flutter.dev/flutter/widgets/TapRegion-class.html)
- [WAI-ARIA Menu and Menubar Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/)
