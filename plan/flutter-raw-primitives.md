# Flutter raw/headless primitive audit and release watchlist

Audited: **2026-07-13**. This is the shared upstream baseline for every
component phase. It answers two separate questions:

1. What public Flutter primitive can Naked UI safely reuse at its declared
   `>=3.41.0` floor?
2. What has landed in newer Flutter channels that should change a plan, a
   compatibility test, or a future floor decision?

An API being present on current stable, beta, or master does not make it usable
by package code compiled at 3.41. Public APIs above the floor are compatibility
evidence until the floor is deliberately raised. Beta/master behavior is a
canary, never release proof.

## Audited channels

| Channel | Exact source inspected | How it is used |
|---|---|---|
| Declared minimum | Flutter 3.41.0 plus workspace Flutter 3.41.2 (`90673a4eef`) | The public API ceiling for production code. |
| Current stable | Flutter 3.44.6 (`ee80f08bbf97172ec030b8751ceab557177a34a6`, 2026-07-08) | Required compatibility target and source of stable behavior changes. |
| Beta | `677d472756f83c14371dd8cc624387065f3d32a7` (2026-06-30) | Non-blocking canary for changes likely to reach stable. |
| Master | `cf9e8afe9a5e601158517782b5b824a328bb2c68` (2026-07-12) | Watchlist only; private and unreleased code is never imported. |

Flutter's feature release notes are named 3.44.0, while the current stable
hotfix release inspected here is 3.44.6. Record both the exact version and
commit in future evidence so “3.44” cannot hide a moving baseline.

## Recommended adoption policy (D-19 approval pending)

This section records the clean-sheet recommendation. It does not resolve D-19
or authorize a future phase; the maintainer must approve that policy when the
next phase is activated. Existing package constraints and explicitly approved
phase decisions continue to apply meanwhile.

- Reuse a primitive only when it is exported from a public Flutter library such
  as `package:flutter/widgets.dart`, `cupertino.dart`, or `material.dart` and
  compiles on the declared minimum.
- Prefer `widgets.dart` raw primitives for Naked UI behavior. Material and
  Cupertino components are valuable behavioral references, but their styling
  and platform policy do not become headless dependencies.
- A useful API introduced after 3.41 requires one explicit choice: keep a
  cross-floor adapter, deliberately raise the package floor, or defer the
  feature. Dart code must not reference a missing symbol and hope a runtime
  version check will protect it.
- Never import `package:flutter/src/...`, copy a private implementation to
  freeze an unstable contract, or ship against an experimental feature flag.
- Keep callbacks and disposal idempotent across release-channel lifecycle
  changes. Test observable results, not private callback order.

The existing package already follows the right layering: `NakedRadio` uses
`RawRadio`/`RadioGroup`; Menu, Select, and Popover use `RawMenuAnchor`; and
Tooltip uses `RawTooltip`. The audit did not find a newer public raw widget
that should replace those foundations wholesale. In fact, the exported
`Raw*` class-name inventory is unchanged across 3.41.2, 3.44.6, and audited
master; the relevant movement is in new public helpers/properties, styled
wrappers, and behavior fixes rather than a new headless component family.

## Component-by-component result

| Component | Raw/public foundation now | Stable/upcoming result | Research/approved result |
|---|---|---|---|
| Alert Dialog | `RawDialogRoute`, Navigator route focus/barrier semantics | 3.44.6 exports `showRawDialog`, but experimental native windowing can remove the barrier and silently ignore `routeBuilder`. | Keep the current route composition. Revisit only after a floor increase and real windowing modal/focus/semantics proof. |
| Link | `Semantics`, `Focus`, `Shortcuts`/`Actions`, pointer gestures, and official `url_launcher.Link` 6.3.2 | No Flutter-core raw Link exists through audited master. The official package provides the public native/web navigation coordinator; its web delegate retains Link semantics for a null URI. | **Approved D-16:** use official Link directly for destination/default navigation, let `onPressed` replace that path, and bypass the wrapper while unavailable. Do not call `launchUrl` or coordinate DOM events directly. |
| Field | `Semantics.isRequired`, `validationResult`, native child role/actions | 3.44.6 includes `FormState.fields`, `FormState.clearError`, and `FormFieldState.clearError`. | Do not use them: they miss the floor and would make Field own validation lifecycle. |
| Toggle Group | `FocusTraversalGroup`, `FocusNode`, `Shortcuts`/`Actions` | `RawRadio` is already the right base for real radio choice, not button toggles. Material `SegmentedButton` remains an API/behavior reference. | Keep custom roving focus for the toggle contract; route radio and tab intent to existing primitives. |
| Context Menu | `RawMenuAnchor`, `MenuController`, `TapRegion`, existing Naked Menu items/positioner | New `CupertinoMenuAnchor` demonstrates long-press-open, same-gesture swipe selection, focus, collision, and large-text behavior. Beta fixes semantic taps/long presses reaching `TapRegion`; master changes raw-menu close callbacks. | Keep `RawMenuAnchor`; use Cupertino as a test oracle, add current-stable semantic dismissal tests, and make close/select paths idempotent. |
| Toast | `OverlayPortal`, `OverlayPortalController`, `AppLifecycleListener` | 3.44.6 improves portal `MediaQuery` inset propagation and adds `Overlay.alwaysSizeToContent`. There is still no raw toast/status controller. | Keep the root portal/controller. Test the 3.41 fallback and 3.44.6 propagation; `alwaysSizeToContent` is not a viewport replacement. |
| Hover Card | `RawMenuAnchor` plus existing generic positioning; `RawTooltip` as a behavior reference | 3.44.6 adds `RawTooltip.ignorePointer`, but no public per-instance hide or focus/Escape ownership. Private `TooltipWindow` is experimental. | Keep the menu-anchor spike. Do not depend on a post-3.41 property or a private window. |
| Combobox | `RawAutocomplete`, `AutocompleteHighlightedOption`, `OptionsViewOpenDirection.mostSpace` | 3.44.6 improves async/inset handling. Beta wraps options in `ExcludeFocus`; 3.44.6 does not. In 3.44.6, `Semantics.identifier` forces a node, unlike the floor. | Use `mostSpace`; explicitly wrap popup options in `ExcludeFocus`; explicitly set the required semantics boundary instead of relying on `identifier`. |

## Material and Cupertino layering cross-check

| Styled framework component | Lower layer found in 3.44.6 source | Consequence |
|---|---|---|
| Material `Radio` and Cupertino `CupertinoRadio` | `RawRadio` | Naked Radio already uses the same correct foundation. |
| Material `MenuAnchor` and Cupertino `CupertinoMenuAnchor` | `RawMenuAnchor` | Naked Menu/Select/Popover are already at the intended headless layer; copy test cases, not styling. |
| Material `Autocomplete` | `RawAutocomplete` | Combobox should start with the raw widget and add only proven gaps. |
| Material `Tooltip` | `RawTooltip` | Naked Tooltip is correctly layered; Hover Card still needs a different per-instance/focus contract. |
| Material `showDialog` | New public `showRawDialog`, normally producing a `RawDialogRoute` | Useful implementation reference, but experimental true-window behavior prevents Alert Dialog adoption today. |
| Material `SegmentedButton` and Cupertino segmented controls | No new raw segmented/toggle-group base | Keep them as controlled-selection and platform-behavior references only. |
| Material `ScaffoldMessenger`/`SnackBar` | No raw Toast/queue primitive | A Naked Toast controller/viewport is justified only after its demand gate. |

## Stable 3.44.6 changes reviewed

### `showRawDialog`

`showRawDialog` is now publicly exported from `widgets.dart`. With
`flutter config --enable-windowing`, Flutter may display a true dialog window;
that window has no modal barrier, and Flutter silently ignores a custom
`routeBuilder`. Those behaviors conflict with the Alert Dialog contract and
windowing remains experimental. `RawDialogRoute` is therefore the correct
cross-floor primitive.

### Cupertino menu family

`CupertinoMenuAnchor`, `CupertinoMenuItem`, `CupertinoMenuDivider`, and
`CupertinoMenuEntry` are public and built on `RawMenuAnchor`. They are not a
headless base, but they are a useful behavioral oracle for Context Menu:
long-press-to-open, selecting during the same swipe gesture, explicit focus
ownership, overlay collision/padding, responsive large-text layout, and
open/close animation boundaries should all be considered in the spike.

### Raw tooltip and overlay changes

`RawTooltip.ignorePointer` defaults to `false`, which confirms that rich
pointer-hover persistence is a supported direction. It does not add the
per-instance hide/focus/Escape controls Hover Card requires, and it cannot be
referenced at the 3.41 floor.

`Overlay.alwaysSizeToContent` requires an `OverlayEntry` with
`canSizeOverlay: true`. It is for content-sized nested overlays, not a Toast
viewport or an anchored overlay that must obey the app overlay's viewport.
Toast therefore continues to use a root `OverlayPortal`.

### Raw autocomplete and semantics changes

On 3.44.6, `RawAutocomplete` better handles async disposal, avoids redundant
hide work, constrains options around `MediaQuery` padding/view insets, and uses
the current semantics announcement path. Naked UI receives those fixes when a
consumer runs that SDK but must still prove equivalent contract outcomes on
3.41. `OptionsViewOpenDirection.mostSpace` is already available at the floor
and should be used before inventing direction-selection logic.

Flutter 3.44.6 also makes `Semantics.identifier` implicitly introduce a new
semantics node. Because 3.41 does not guarantee that boundary, any Combobox
control/popup relationship must set `container: true` (and
`explicitChildNodes` where its tree requires it) explicitly.

No relevant `SemanticsRole` value was added between 3.41.2, 3.44.6, and audited
master. The planned roles (`alertDialog`, `comboBox`, `menu`, `status`,
`alert`, and the existing button/radio/link roles) remain the right vocabulary;
real VoiceOver, TalkBack, and web accessibility-tree proof is still required
because engine/platform mappings can change without a Dart enum change.

## Beta and master watchlist

These changes are **not** an API baseline. They define focused regression
tests to run now and simplifications to reconsider after a stable release.

| Channel/change | Current impact | Promotion condition |
|---|---|---|
| Beta [`a270a23a64` / #185543](https://github.com/flutter/flutter/pull/185543): `RawAutocomplete` wraps its options overlay in `ExcludeFocus` | 3.44.6 still permits focusable option descendants into ambient Tab traversal. The Combobox adapter must add its own `ExcludeFocus` and prove Tab closes/moves without selection. | After the fix reaches stable and the package floor contains it, decide whether the explicit wrapper can be removed; retain the regression test. |
| Beta [`f77fa02177` / #183093](https://github.com/flutter/flutter/pull/183093): `TapRegion` classifies semantic tap/long-press actions | Current stable may dismiss/open differently for accessibility actions, especially on web. Context Menu and existing raw-menu consumers need semantic activation and outside-dismissal tests now. | When stable, rerun exactly-once close/select tests before relying on the new routing. |
| Master [`a6667aa1a9` / #186376](https://github.com/flutter/flutter/pull/186376): `RawMenuAnchor.onCloseRequested` also runs when already closed | A caller that assumes “close requested means currently open” can double-complete. | Keep callbacks idempotent; update compatibility expectations only after a tagged stable release. |
| Master [`fcd4502342` / #187881](https://github.com/flutter/flutter/pull/187881): raw-menu scrolling listener disposal fix | Existing overlay disposal tests should catch listener/lifecycle regressions without copying the framework fix. | Receive the upstream fix through Flutter; do not vendor it. |
| Stable/master private `PopupWindow`, `TooltipWindow`, controllers, and positioners | Names look reusable, but the files live under `package:flutter/src`, require experimental windowing, and do not provide a supported cross-platform contract. | Consider only if Flutter publicly exports and documents them, removes the production warning, and the minimum SDK is raised with fallback/AT proof. |

## Required re-audit at the start of every phase

1. Record exact minimum, workspace, current stable, beta, and master commits.
2. Read the official stable changelog/release notes and diff public exports plus
   the relevant raw source from the previous audited stable.
3. Search for new public `Raw*`, `Overlay*`, focus, semantics, menu, dialog,
   form, and autocomplete APIs. Inspect Material/Cupertino implementations only
   for reusable behavior and test cases.
4. Classify every candidate as **adopt**, **adapt**, **behavior reference**,
   **watch**, or **reject**, with the SDK-floor reason.
5. Run focused tests on exact 3.41.0, the workspace pin, and current stable.
   Run beta/master only as non-blocking canaries for a primitive named in this
   watchlist.
6. Update this file and the affected phase plan before freezing public API.

## Primary Flutter sources

- [Flutter release notes](https://docs.flutter.dev/release/release-notes)
- [Flutter 3.44 feature release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.44.0)
- [Flutter stable changelog](https://github.com/flutter/flutter/blob/master/CHANGELOG.md)
- [`showRawDialog` source at 3.44.6](https://github.com/flutter/flutter/blob/3.44.6/packages/flutter/lib/src/widgets/dialog.dart)
- [`CupertinoMenuAnchor` source at 3.44.6](https://github.com/flutter/flutter/blob/3.44.6/packages/flutter/lib/src/cupertino/menu_anchor.dart)
- [`RawTooltip` API](https://api.flutter.dev/flutter/widgets/RawTooltip-class.html)
- [`Overlay.alwaysSizeToContent` API](https://api.flutter.dev/flutter/widgets/Overlay/alwaysSizeToContent.html)
- [`RawAutocomplete` API](https://api.flutter.dev/flutter/widgets/RawAutocomplete-class.html)
- [`RawMenuAnchor` API](https://api.flutter.dev/flutter/widgets/RawMenuAnchor-class.html)
- [`SemanticsRole` API](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)
