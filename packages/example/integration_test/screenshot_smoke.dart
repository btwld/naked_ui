import 'dart:io';

import 'package:example/api/naked_dialog.0.dart' as dialog_example;
import 'package:example/api/naked_field.0.dart' as field_example;
import 'package:example/src/testing/screenshot_evidence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naked_ui/naked_ui.dart';

import 'helpers/screenshot_test_helpers.dart';
import 'helpers/test_helpers.dart';

const _alertOpenKey = ValueKey('alert-dialog.open');
const _alertTitleKey = ValueKey('alert-dialog.title');
const _alertMessageFocusKey = ValueKey('alert-dialog.message-focus');
const _alertCancelKey = ValueKey('alert-dialog.cancel');
const _alertConfirmKey = ValueKey('alert-dialog.confirm');

void _configureScreenshotView(WidgetTester tester) {
  if (Platform.isAndroid || Platform.isIOS) return;
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _alertScreenshotApp({
  bool longMessage = false,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: dialog_example.AlertDialogExample(longMessage: longMessage),
      ),
    ),
  );
}

Widget _fieldScreenshotApp({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: appChild!,
    ),
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}

class _FieldStatePreview extends StatelessWidget {
  const _FieldStatePreview({
    required this.fieldKey,
    required this.label,
    required this.description,
    this.enabled = true,
    this.readOnly = false,
  });

  final Key fieldKey;
  final String label;
  final String description;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return NakedField(
      key: fieldKey,
      label: label,
      description: description,
      enabled: enabled,
      readOnly: readOnly,
      builder: (context, state, _) {
        final borderColor = state.isDisabled
            ? Colors.grey.shade500
            : Colors.blueGrey.shade700;
        final status = state.isDisabled ? 'Disabled' : 'Read only';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NakedFieldLabel(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            NakedTextField(
              style: const TextStyle(fontSize: 16),
              builder: (context, _, editable) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: state.isDisabled
                        ? Colors.grey.shade200
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: editable,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            NakedFieldDescription(child: Text(description)),
            const SizedBox(height: 4),
            ExcludeSemantics(child: Text(status)),
          ],
        );
      },
    );
  }
}

class _FieldStateGallery extends StatelessWidget {
  const _FieldStateGallery();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Disabled and read-only fields',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _FieldStatePreview(
            fieldKey: ValueKey('field.screenshot.disabled'),
            label: 'Disabled email',
            description: 'Unavailable until account access is restored.',
            enabled: false,
          ),
          SizedBox(height: 16),
          _FieldStatePreview(
            fieldKey: ValueKey('field.screenshot.readonly'),
            label: 'Read-only email',
            description: 'Focusable for review but cannot be edited.',
            readOnly: true,
          ),
        ],
      ),
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 2));

  testWidgets('dialog open screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey('dialog.screenshot.surface');
    final usesNativeSurface = Platform.isAndroid || Platform.isIOS;
    if (!usesNativeSurface) {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    await tester.pumpWidget(
      const RepaintBoundary(
        key: screenshotSurfaceKey,
        child: dialog_example.MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Basic Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Action'), findsOneWidget);
    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    if (!usesNativeSurface) {
      expect(logicalSize, const Size(800, 600));
    }
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'dialog',
        scenario: 'open',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        animationMode: 'fixed 400ms transition, settled',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('alert dialog safe focus screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey('alert-dialog.screenshot.safe-focus');
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(key: screenshotSurfaceKey, child: _alertScreenshotApp()),
    );
    await tester.pump();

    await tester.tap(find.byKey(_alertOpenKey));
    await tester.pumpUntil(
      () => find.byKey(_alertTitleKey).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 2),
    );
    final cancelButton = tester.widget<NakedButton>(
      find.descendant(
        of: find.byKey(_alertCancelKey),
        matching: find.byType(NakedButton),
      ),
    );
    await tester.pumpUntil(
      () => FocusManager.instance.primaryFocus == cancelButton.focusNode,
      timeout: const Duration(seconds: 2),
    );
    expect(FocusManager.instance.primaryFocus, same(cancelButton.focusNode));

    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'alert_dialog',
        scenario: 'open_safe_focus',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        animationMode: 'disabled, zero-duration route transition',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('alert dialog destructive action screenshot evidence', (
    tester,
  ) async {
    const screenshotSurfaceKey = ValueKey(
      'alert-dialog.screenshot.destructive-action',
    );
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(key: screenshotSurfaceKey, child: _alertScreenshotApp()),
    );
    await tester.pump();

    await tester.tap(find.byKey(_alertOpenKey));
    await tester.pumpUntil(
      () => find.byKey(_alertConfirmKey).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 2),
    );
    await tester.tap(find.byKey(_alertConfirmKey));
    await tester.pumpUntil(
      () =>
          find.text('Result: confirm; confirmations: 1').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 2),
    );
    expect(find.byKey(_alertTitleKey), findsNothing);

    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'alert_dialog',
        scenario: 'destructive_action',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        animationMode: 'disabled, action completed',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('alert dialog long message screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey(
      'alert-dialog.screenshot.long-message',
    );
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: screenshotSurfaceKey,
        child: _alertScreenshotApp(
          longMessage: true,
          textScaler: const TextScaler.linear(2),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(_alertOpenKey));
    await tester.pumpUntil(
      () => find.byKey(_alertMessageFocusKey).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 2),
    );
    final messageFocus = tester.widget<Focus>(
      find.byKey(_alertMessageFocusKey),
    );
    await tester.pumpUntil(
      () => FocusManager.instance.primaryFocus == messageFocus.focusNode,
      timeout: const Duration(seconds: 2),
    );
    expect(FocusManager.instance.primaryFocus, same(messageFocus.focusNode));
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(_alertTitleKey)),
      ).scale(10),
      20,
    );

    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'alert_dialog',
        scenario: 'long_message_200_text',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        textScale: 2,
        animationMode: 'disabled, zero-duration route transition',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('required invalid Field screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey('field.screenshot.required-invalid');
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: screenshotSurfaceKey,
        child: _fieldScreenshotApp(child: const field_example.FieldExample()),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.pump();
    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(field_example.fieldEmailStateKey)).data,
      contains('invalid'),
    );

    if (!Platform.isMacOS) return;
    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'field',
        scenario: 'required_invalid',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        animationMode: 'disabled, required invalid state',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('RTL Field screenshot evidence', (tester) async {
    const screenshotSurfaceKey = ValueKey('field.screenshot.rtl');
    const label = 'البريد الإلكتروني';
    const description = 'أدخل عنوان بريد يمكننا الوصول إليه.';
    const invalidError = 'أدخل عنوان بريد إلكتروني صالحًا.';
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: screenshotSurfaceKey,
        child: _fieldScreenshotApp(
          textDirection: TextDirection.rtl,
          child: const field_example.FieldExample(
            initialValue: 'غير صالح',
            label: label,
            description: description,
            requiredError: 'أدخل عنوان بريد إلكتروني.',
            invalidError: invalidError,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.tap(find.byKey(field_example.fieldEmailSubmitKey));
    await tester.pump();
    final invalidErrorContext = tester.element(find.text(invalidError));
    TextDirection directionOf(Finder finder) =>
        Directionality.of(tester.element(finder));

    expect(directionOf(find.text('Semantic email field')), TextDirection.ltr);
    expect(
      directionOf(find.textContaining('Validation remains application-owned')),
      TextDirection.ltr,
    );
    expect(
      directionOf(find.byKey(field_example.fieldEmailStateKey)),
      TextDirection.ltr,
    );
    expect(
      directionOf(find.byKey(field_example.fieldEmailKey)),
      TextDirection.rtl,
    );
    expect(
      directionOf(find.byKey(field_example.fieldEmailControlKey)),
      TextDirection.rtl,
    );
    expect(
      directionOf(find.byKey(field_example.fieldEmailLabelKey)),
      TextDirection.rtl,
    );
    expect(
      directionOf(find.byKey(field_example.fieldEmailDescriptionKey)),
      TextDirection.rtl,
    );
    expect(Directionality.of(invalidErrorContext), TextDirection.rtl);
    expect(
      Localizations.localeOf(invalidErrorContext),
      const Locale('en', 'US'),
    );
    expect(find.text(invalidError), findsOneWidget);

    if (!Platform.isMacOS) return;
    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'field',
        scenario: 'rtl',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        locale: 'en-US',
        direction: 'RTL',
        animationMode: 'disabled, Arabic copy in RTL under en-US locale',
      ),
      surface: screenshotSurface,
    );
  });

  testWidgets('disabled and read-only 200 percent Field screenshot evidence', (
    tester,
  ) async {
    const screenshotSurfaceKey = ValueKey(
      'field.screenshot.disabled-readonly-200',
    );
    _configureScreenshotView(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: screenshotSurfaceKey,
        child: _fieldScreenshotApp(
          textScaler: const TextScaler.linear(2),
          child: const _FieldStateGallery(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Disabled email'), findsOneWidget);
    expect(find.text('Read-only email'), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Disabled email')),
      ).scale(10),
      20,
    );
    expect(tester.takeException(), isNull);

    if (!Platform.isAndroid) return;
    final screenshotSurface = find.byKey(screenshotSurfaceKey);
    final logicalSize = tester.getSize(screenshotSurface);
    await tester.captureEvidenceScreenshot(
      binding,
      ScreenshotEvidence(
        component: 'field',
        scenario: 'disabled_readonly_200',
        surface: '${logicalSize.width}x${logicalSize.height} logical pixels',
        devicePixelRatio: tester.view.devicePixelRatio,
        textScale: 2,
        animationMode: 'disabled, static state comparison',
      ),
      surface: screenshotSurface,
    );
  });
}
