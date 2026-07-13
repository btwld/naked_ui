import 'package:flutter/material.dart';
import 'package:naked_ui/naked_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(child: LinkExample()),
      ),
    );
  }
}

/// Deterministic styled fixture for the headless Link contract.
class LinkExample extends StatefulWidget {
  const LinkExample({
    super.key,
    this.textDirection = TextDirection.ltr,
    this.textScale = 1,
    this.longText = false,
    this.disableAnimations = true,
  });

  final TextDirection textDirection;
  final double textScale;
  final bool longText;
  final bool disableAnimations;

  @override
  State<LinkExample> createState() => _LinkExampleState();
}

class _LinkExampleState extends State<LinkExample> {
  var _result = 'none';
  var _activationCount = 0;
  var _primaryEnabled = true;
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  bool get _isRtl => widget.textDirection == TextDirection.rtl;

  void _activate(String result) {
    setState(() {
      _result = result;
      _activationCount++;
    });
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    setState(() {
      _result = 'none';
      _activationCount = 0;
      _primaryEnabled = true;
      _hovered = false;
      _focused = false;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(widget.textScale),
        disableAnimations: widget.disableAnimations,
      ),
      child: Directionality(
        textDirection: widget.textDirection,
        child: RepaintBoundary(
          key: const ValueKey('link.evidence.surface'),
          child: Material(
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRtl ? 'روابط Naked UI' : 'Naked UI links',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPrimaryLine(),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [_buildExternalLink(), _buildDisabledLink()],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Result: $_result; activations: $_activationCount',
                        key: const ValueKey('link.result'),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'hovered:$_hovered focused:$_focused '
                        'pressed:$_pressed enabled:$_primaryEnabled',
                        key: const ValueKey('link.state'),
                        style: const TextStyle(color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton(
                            key: const ValueKey('link.next-focus'),
                            onPressed: () => _activate('next-focus'),
                            child: const Text('Next focus target'),
                          ),
                          OutlinedButton(
                            key: const ValueKey('link.disable-primary'),
                            onPressed: _primaryEnabled
                                ? () => setState(() {
                                    _primaryEnabled = false;
                                    _hovered = false;
                                    _pressed = false;
                                  })
                                : null,
                            child: const Text('Disable primary Link'),
                          ),
                          OutlinedButton(
                            key: const ValueKey('link.reset'),
                            onPressed: _reset,
                            child: const Text('Reset Link fixture'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryLine() {
    final linkText = _isRtl
        ? widget.longText
              ? 'دليل الوصول الكامل للمكونات التفاعلية والقابلة للتخصيص'
              : 'دليل الوصول'
        : widget.longText
        ? 'Read the complete accessibility guide for customizable interactive components'
        : 'Read the documentation';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _isRtl ? 'تعرّف على المكوّنات في ' : 'Learn about the components in ',
          style: const TextStyle(color: Color(0xFF334155), fontSize: 16),
        ),
        NakedLink(
          key: const ValueKey('link.primary'),
          linkUrl: Uri.parse('https://example.com/naked-ui'),
          semanticLabel: _isRtl ? linkText : null,
          onPressed: _primaryEnabled ? () => _activate('primary') : null,
          onHoverChange: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _focused = value),
          onPressChange: (value) => setState(() => _pressed = value),
          child: Text(linkText),
          builder: (context, state, child) => _LinkSurface(
            state: state,
            standalone: false,
            disableAnimations: widget.disableAnimations,
            child: child!,
          ),
        ),
      ],
    );
  }

  Widget _buildExternalLink() {
    return NakedLink(
      key: const ValueKey('link.external'),
      linkUrl: Uri.parse('https://docs.flutter.dev/ui/accessibility'),
      semanticLabel: 'Flutter accessibility documentation',
      semanticHint: 'Opens in a new window',
      onPressed: () => _activate('external'),
      child: const Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Flutter accessibility'),
          SizedBox(width: 6),
          ExcludeSemantics(
            child: Icon(
              Icons.open_in_new,
              size: 16,
              semanticLabel: 'External link icon',
            ),
          ),
        ],
      ),
      builder: (context, state, child) => _LinkSurface(
        state: state,
        standalone: true,
        disableAnimations: widget.disableAnimations,
        child: child!,
      ),
    );
  }

  Widget _buildDisabledLink() {
    return NakedLink(
      key: const ValueKey('link.disabled'),
      enabled: false,
      onPressed: () => _activate('disabled'),
      child: const Text('Unavailable documentation'),
      builder: (context, state, child) => _LinkSurface(
        state: state,
        standalone: true,
        disableAnimations: widget.disableAnimations,
        child: child!,
      ),
    );
  }
}

/// A standalone styled Link used to verify platform target-size guidance.
class StandaloneLinkExample extends StatelessWidget {
  const StandaloneLinkExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NakedLink(
        key: const ValueKey('link.standalone'),
        linkUrl: Uri.parse('https://example.com/naked-ui'),
        onPressed: () {},
        child: const Text('Open documentation'),
        builder: (context, state, child) => _LinkSurface(
          state: state,
          standalone: true,
          disableAnimations: true,
          child: child!,
        ),
      ),
    );
  }
}

class _LinkSurface extends StatelessWidget {
  const _LinkSurface({
    required this.state,
    required this.standalone,
    required this.disableAnimations,
    required this.child,
  });

  final NakedLinkState state;
  final bool standalone;
  final bool disableAnimations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground = state.isDisabled
        ? const Color(0xFF64748B)
        : const Color(0xFF1D4ED8);
    final background = state.when(
      disabled: const Color(0xFFE2E8F0),
      pressed: const Color(0xFFBFDBFE),
      hovered: const Color(0xFFDBEAFE),
      orElse: Colors.transparent,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: state.isFocused ? const Color(0xFF2563EB) : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(standalone ? 8 : 4),
      ),
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        constraints: standalone
            ? const BoxConstraints(minWidth: 48, minHeight: 48)
            : const BoxConstraints(),
        padding: standalone
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(standalone ? 6 : 2),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
          child: IconTheme(
            data: IconThemeData(color: foreground),
            child: child,
          ),
        ),
      ),
    );
  }
}
