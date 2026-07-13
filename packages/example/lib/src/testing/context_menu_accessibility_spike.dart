import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naked_ui/naked_ui.dart';

/// The two approved trigger-semantics variants for the disposable spike.
enum ContextMenuSpikeVariant { v0PhysicalAndKeyboard, v1SemanticLongPress }

/// Real child surfaces exercised by the spike.
enum ContextMenuSpikeChildKind { link, selectableText, row }

/// Initial-focus alternatives measured independently from trigger semantics.
enum ContextMenuSpikeInitialFocus { boundary, firstEnabledItem }

/// Entry paths recorded without conflating input requests with actual opens.
enum ContextMenuSpikeOpenSource {
  secondaryPointer,
  physicalLongPress,
  shiftF10,
  contextMenuKey,
  semanticLongPress,
}

/// Stable fixture keys for automated and manual evidence.
abstract final class ContextMenuSpikeKeys {
  static const variant = ValueKey<String>('context-menu-spike.variant');
  static const triggerLink = ValueKey<String>(
    'context-menu-spike.trigger.link',
  );
  static const triggerSelectable = ValueKey<String>(
    'context-menu-spike.trigger.selectable',
  );
  static const triggerRow = ValueKey<String>('context-menu-spike.trigger.row');
  static const scroll = ValueKey<String>('context-menu-spike.scroll');
  static const menu = ValueKey<String>('context-menu-spike.menu');
  static const itemRename = ValueKey<String>('context-menu-spike.item.rename');
  static const itemDelete = ValueKey<String>('context-menu-spike.item.delete');
  static const state = ValueKey<String>('context-menu-spike.state');
  static const disable = ValueKey<String>('context-menu-spike.disable');
  static const reset = ValueKey<String>('context-menu-spike.reset');
  static const geometryAnchor = ValueKey<String>(
    'context-menu-spike.geometry.anchor',
  );
  static const geometryOverlay = ValueKey<String>(
    'context-menu-spike.geometry.overlay',
  );
}

/// Independent lifecycle and activation observations for a single trigger.
class ContextMenuSpikeCounters extends ChangeNotifier {
  int openRequests = 0;
  int actualOpens = 0;
  int closeRequests = 0;
  int actualCloses = 0;
  int selections = 0;
  int childActivations = 0;
  int textSelectionChanges = 0;

  ContextMenuSpikeOpenSource? lastOpenSource;
  Offset? lastLocalInvocation;
  String? lastSelection;
  String? focusedItem;
  String? initialFocusObservation;
  TextSelection? lastTextSelection;

  final List<String> events = <String>[];

  void recordOpenRequest(
    ContextMenuSpikeOpenSource source,
    Offset? localPosition,
  ) {
    openRequests += 1;
    lastOpenSource = source;
    lastLocalInvocation = localPosition;
    events.add('open-request:${source.name}');
    notifyListeners();
  }

  void recordActualOpen() {
    actualOpens += 1;
    events.add('actual-open');
    notifyListeners();
  }

  void recordCloseRequest() {
    closeRequests += 1;
    events.add('close-request');
    notifyListeners();
  }

  void recordActualClose() {
    actualCloses += 1;
    events.add('actual-close');
    notifyListeners();
  }

  void recordSelection(String value) {
    selections += 1;
    lastSelection = value;
    events.add('selection:$value');
    notifyListeners();
  }

  void recordChildActivation() {
    childActivations += 1;
    events.add('child-activation');
    notifyListeners();
  }

  void recordTextSelection(TextSelection selection, SelectionChangedCause? _) {
    textSelectionChanges += 1;
    lastTextSelection = selection;
    events.add('text-selection:${selection.start}-${selection.end}');
  }

  // Focus state is observed from NakedMenuItem's existing state builders.
  // Deliberately avoid notifications while those builders are executing.
  void observeItemFocus(String value, bool focused) {
    if (focused) {
      focusedItem = value;
    } else if (focusedItem == value) {
      focusedItem = null;
    }
  }

  void observeInitialFocus(String value) {
    initialFocusObservation = value;
    events.add('initial-focus:$value');
    notifyListeners();
  }

  void reset() {
    openRequests = 0;
    actualOpens = 0;
    closeRequests = 0;
    actualCloses = 0;
    selections = 0;
    childActivations = 0;
    textSelectionChanges = 0;
    lastOpenSource = null;
    lastLocalInvocation = null;
    lastSelection = null;
    focusedItem = null;
    initialFocusObservation = null;
    lastTextSelection = null;
    events.clear();
    notifyListeners();
  }

  @override
  String toString() =>
      'open $openRequests/$actualOpens; '
      'close $closeRequests/$actualCloses; '
      'selection $selections; child $childActivations; '
      'source ${lastOpenSource?.name ?? '-'}; '
      'focus ${focusedItem ?? initialFocusObservation ?? '-'}';
}

class _OpenContextMenuIntent extends Intent {
  const _OpenContextMenuIntent(this.source);

  final ContextMenuSpikeOpenSource source;
}

/// One disposable trigger fixture. The supplied child kind is rendered once.
///
/// Existing [NakedMenu] item, role, outside-dismissal, and selection behavior
/// is reused behind a semantics-excluded trigger that sits below the real
/// child in hit-test order. This is intentionally not production structure.
class ContextMenuSpikeTrigger extends StatefulWidget {
  const ContextMenuSpikeTrigger({
    super.key,
    required this.variant,
    required this.childKind,
    required this.counters,
    this.initialFocus = ContextMenuSpikeInitialFocus.boundary,
    this.enabled = true,
    this.disableFirstItem = false,
  });

  final ContextMenuSpikeVariant variant;
  final ContextMenuSpikeChildKind childKind;
  final ContextMenuSpikeCounters counters;
  final ContextMenuSpikeInitialFocus initialFocus;
  final bool enabled;
  final bool disableFirstItem;

  @override
  State<ContextMenuSpikeTrigger> createState() =>
      _ContextMenuSpikeTriggerState();
}

class _ContextMenuSpikeTriggerState extends State<ContextMenuSpikeTrigger> {
  final MenuController _menuController = MenuController();
  late final FocusNode _triggerFocusNode = FocusNode(
    debugLabel: 'context-menu-spike.${widget.childKind.name}',
  );
  final GlobalKey _renameFocusProbeKey = GlobalKey(
    debugLabel: 'context-menu-spike.rename.focus-probe',
  );
  final GlobalKey _deleteFocusProbeKey = GlobalKey(
    debugLabel: 'context-menu-spike.delete.focus-probe',
  );
  final GlobalKey _menuFocusProbeKey = GlobalKey(
    debugLabel: 'context-menu-spike.menu.focus-probe',
  );
  bool _closeInFlight = false;
  int _openGeneration = 0;

  @override
  void dispose() {
    _triggerFocusNode.dispose();
    super.dispose();
  }

  void _requestOpen(ContextMenuSpikeOpenSource source, Offset? localPosition) {
    if (!widget.enabled) return;
    widget.counters.recordOpenRequest(source, localPosition);
    if (_menuController.isOpen) return;
    _menuController.open(position: localPosition);
  }

  void _handleOpen() {
    _closeInFlight = false;
    final generation = ++_openGeneration;
    widget.counters.recordActualOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_menuController.isOpen ||
          generation != _openGeneration) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_menuController.isOpen ||
            generation != _openGeneration) {
          return;
        }
        _measureOrApplyInitialFocus(generation);
      });
    });
  }

  void _measureOrApplyInitialFocus(int generation) {
    if (widget.initialFocus == ContextMenuSpikeInitialFocus.boundary) {
      final menuContext = _menuFocusProbeKey.currentContext;
      final boundaryHasPrimaryFocus =
          menuContext != null &&
          Focus.of(menuContext) == FocusManager.instance.primaryFocus;
      widget.counters.observeInitialFocus(
        boundaryHasPrimaryFocus ? 'boundary' : 'none',
      );
      return;
    }

    final targetContext = widget.disableFirstItem
        ? _deleteFocusProbeKey.currentContext
        : _renameFocusProbeKey.currentContext;
    if (targetContext == null) {
      widget.counters.observeInitialFocus('none');
      return;
    }
    Focus.of(targetContext).requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_menuController.isOpen ||
          generation != _openGeneration) {
        return;
      }
      widget.counters.observeInitialFocus(
        widget.counters.focusedItem ?? 'none',
      );
    });
  }

  void _handleCloseRequest(VoidCallback hide) {
    widget.counters.recordCloseRequest();
    if (!_menuController.isOpen || _closeInFlight) return;
    _closeInFlight = true;
    hide();
  }

  void _handleClose() {
    _closeInFlight = false;
    final closedGeneration = _openGeneration;
    widget.counters.recordActualClose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _menuController.isOpen ||
          closedGeneration != _openGeneration ||
          _triggerFocusNode.context == null) {
        return;
      }
      _triggerFocusNode.requestFocus();
    });
  }

  Widget _buildRealChild() {
    switch (widget.childKind) {
      case ContextMenuSpikeChildKind.link:
        return NakedLinkResolver(
          resolve: (_, _) => NakedLinkResolution.handled,
          child: NakedLink(
            key: ContextMenuSpikeKeys.triggerLink,
            linkUrl: Uri.parse('https://example.com/naked-ui'),
            focusNode: _triggerFocusNode,
            semanticLabel: 'Naked UI documentation',
            onActivated: (_) => widget.counters.recordChildActivation(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Naked UI documentation'),
            ),
          ),
        );
      case ContextMenuSpikeChildKind.selectableText:
        return SelectableText(
          'Selectable release notes for Naked UI',
          key: ContextMenuSpikeKeys.triggerSelectable,
          focusNode: _triggerFocusNode,
          onSelectionChanged: widget.counters.recordTextSelection,
        );
      case ContextMenuSpikeChildKind.row:
        return Focus(
          focusNode: _triggerFocusNode,
          child: Semantics(
            key: ContextMenuSpikeKeys.triggerRow,
            container: true,
            child: const SizedBox(
              width: 240,
              height: 48,
              child: Row(
                children: [
                  Icon(Icons.folder_outlined),
                  SizedBox(width: 8),
                  Expanded(child: Text('Project Alpha')),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildMenu() {
    return ConstrainedBox(
      key: ContextMenuSpikeKeys.menu,
      constraints: const BoxConstraints.tightFor(width: 184),
      child: ColoredBox(
        key: _menuFocusProbeKey,
        color: const Color(0xFFF5F5F5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NakedMenuItem<String>(
              key: ContextMenuSpikeKeys.itemRename,
              value: 'rename',
              enabled: !widget.disableFirstItem,
              semanticLabel: 'Rename',
              builder: (context, state, child) {
                widget.counters.observeItemFocus('rename', state.isFocused);
                return Padding(
                  key: _renameFocusProbeKey,
                  padding: const EdgeInsets.all(12),
                  child: child,
                );
              },
              child: const Text('Rename'),
            ),
            NakedMenuItem<String>(
              key: ContextMenuSpikeKeys.itemDelete,
              value: 'delete',
              semanticLabel: 'Delete',
              builder: (context, state, child) {
                widget.counters.observeItemFocus('delete', state.isFocused);
                return Padding(
                  key: _deleteFocusProbeKey,
                  padding: const EdgeInsets.all(12),
                  child: child,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semanticLongPress =
        widget.enabled &&
            widget.variant == ContextMenuSpikeVariant.v1SemanticLongPress
        ? () => _requestOpen(ContextMenuSpikeOpenSource.semanticLongPress, null)
        : null;

    final menuScaffold = Positioned.fill(
      child: ExcludeFocusTraversal(
        child: NakedMenu<String>(
          controller: _menuController,
          excludeSemantics: true,
          consumeOutsideTaps: false,
          onOpen: _handleOpen,
          onClose: _handleClose,
          onCloseRequested: _handleCloseRequest,
          onSelected: widget.counters.recordSelection,
          overlayBuilder: (context, info) => _buildMenu(),
          child: const SizedBox.expand(),
        ),
      ),
    );

    final trigger = Semantics(
      onLongPress: semanticLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onSecondaryTapUp: widget.enabled
            ? (details) => _requestOpen(
                ContextMenuSpikeOpenSource.secondaryPointer,
                details.localPosition,
              )
            : null,
        onLongPressStart: widget.enabled
            ? (details) => _requestOpen(
                ContextMenuSpikeOpenSource.physicalLongPress,
                details.localPosition,
              )
            : null,
        child: Stack(
          fit: StackFit.passthrough,
          children: [menuScaffold, _buildRealChild()],
        ),
      ),
    );
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f10, shift: true):
            _OpenContextMenuIntent(ContextMenuSpikeOpenSource.shiftF10),
        SingleActivator(LogicalKeyboardKey.contextMenu): _OpenContextMenuIntent(
          ContextMenuSpikeOpenSource.contextMenuKey,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenContextMenuIntent: CallbackAction<_OpenContextMenuIntent>(
            onInvoke: (intent) {
              _requestOpen(intent.source, null);
              return null;
            },
          ),
        },
        child: trigger,
      ),
    );
  }
}

/// Geometry-only observations kept separate from menu semantics and focus.
class ContextMenuGeometryObservations extends ChangeNotifier {
  int openRequests = 0;
  int actualOpens = 0;
  Offset? requestedLocalPosition;
  Offset? rawMenuPosition;
  Offset? resolvedOverlayPoint;
  Offset? naiveAnchorPlusLocalPoint;
  Rect? anchorRect;

  void recordRequest(Offset position) {
    openRequests += 1;
    requestedLocalPosition = position;
    notifyListeners();
  }

  void recordOpen() {
    actualOpens += 1;
    notifyListeners();
  }

  void recordOverlay(RawMenuOverlayInfo info, Offset resolvedPoint) {
    rawMenuPosition = info.position;
    anchorRect = info.anchorRect;
    resolvedOverlayPoint = resolvedPoint;
    naiveAnchorPlusLocalPoint = info.position == null
        ? null
        : info.anchorRect.topLeft + info.position!;
  }
}

/// A point-positioning probe using only RawMenuAnchor and OverlayPositioner.
///
/// Pointer global coordinates are converted to the target Overlay's coordinate
/// space before opening. The raw anchor-local position is recorded separately
/// so transformed-anchor drift in `anchorRect.topLeft + position` is visible.
class ContextMenuGeometryProbe extends StatefulWidget {
  const ContextMenuGeometryProbe({
    super.key,
    required this.observations,
    this.anchorSize = const Size(120, 56),
    this.overlaySize = const Size(184, 88),
  });

  final ContextMenuGeometryObservations observations;
  final Size anchorSize;
  final Size overlaySize;

  @override
  State<ContextMenuGeometryProbe> createState() =>
      _ContextMenuGeometryProbeState();
}

class _ContextMenuGeometryProbeState extends State<ContextMenuGeometryProbe> {
  final MenuController _controller = MenuController();
  Offset? _overlayPoint;

  void _openAt(TapUpDetails details) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    _overlayPoint = overlayBox.globalToLocal(details.globalPosition);
    widget.observations.recordRequest(details.localPosition);
    _controller.open(position: details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _controller,
      consumeOutsideTaps: false,
      onOpen: widget.observations.recordOpen,
      onOpenRequested: (info, show) => show(),
      onCloseRequested: (hide) => hide(),
      overlayBuilder: (context, info) {
        final resolvedPoint = _overlayPoint ?? info.anchorRect.bottomLeft;
        widget.observations.recordOverlay(info, resolvedPoint);
        return OverlayPositioner(
          targetRect: Rect.fromLTWH(resolvedPoint.dx, resolvedPoint.dy, 0, 0),
          positioning: const OverlayPositionConfig(
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.topLeft,
          ),
          child: SizedBox.fromSize(
            key: ContextMenuSpikeKeys.geometryOverlay,
            size: widget.overlaySize,
            child: const ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        );
      },
      child: GestureDetector(
        key: ContextMenuSpikeKeys.geometryAnchor,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onSecondaryTapUp: _openAt,
        child: SizedBox.fromSize(
          size: widget.anchorSize,
          child: const ColoredBox(color: Color(0xFFBDBDBD)),
        ),
      ),
    );
  }
}
