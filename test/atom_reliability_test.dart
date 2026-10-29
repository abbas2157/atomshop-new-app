import 'package:atompro/app.dart';
import 'package:atompro/data/atom_http.dart';
import 'package:atompro/data/atom_models.dart';
import 'package:atompro/data/atom_product_detail.dart';
import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/responsive/atom_responsive.dart';
import 'package:atompro/screens/info/atom_info_widgets.dart';
import 'package:atompro/widgets/atom_auto_scroll_row.dart';
import 'package:atompro/widgets/atom_leave_guard.dart';
import 'package:atompro/widgets/atom_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Retries, duplicate-submit protection, server gates and layout
/// regressions found on the emulator.
void main() {
  group('atomRetry', () {
    test('retries only lost connections, three times with backoff', () {
      const offline = AtomApiException('Check your internet connection and try again.');
      expect(atomRetry(0, offline), const Duration(milliseconds: 500));
      expect(atomRetry(1, offline), const Duration(seconds: 1));
      expect(atomRetry(2, offline), const Duration(seconds: 2));
      expect(atomRetry(3, offline), isNull);
    });

    test('never retries a real answer from the server', () {
      expect(atomRetry(0, const AtomApiException('Not found', statusCode: 404)), isNull);
      expect(atomRetry(0, const AtomApiException('Invalid', statusCode: 422)), isNull);
      expect(atomRetry(0, const ProductNotFound(7)), isNull);
    });
  });

  test('request ids are 32 hex characters and unique', () {
    final ids = {for (var i = 0; i < 200; i++) atomRequestId()};
    expect(ids.length, 200);
    expect(ids.every((id) => RegExp(r'^[0-9a-f]{32}$').hasMatch(id)), isTrue);
  });

  test('maintenance comes from api/app/config and is off when missing', () {
    final on = AppConfig.fromJson({
      'maintenance': {'enabled': true, 'message': 'Back soon.', 'until': '2026-10-29T10:00:00Z'},
    });
    expect(on.maintenance, isTrue);
    expect(on.maintenanceMessage, 'Back soon.');
    expect(on.maintenanceUntil, DateTime.utc(2026, 10, 29, 10));

    final off = AppConfig.fromJson({});
    expect(off.maintenance, isFalse);
    expect(off.maintenanceUntil, isNull);
  });

  testWidgets('a page-width bottom bar is as tall as its content, not the screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: AtomPageWidth(child: Container(key: const Key('bar'), height: 60, color: Colors.blue)),
      ),
    ));
    final bar = tester.getSize(find.byType(AtomPageWidth));
    expect(bar.height, 60);
  });

  testWidgets('selects have a search box that filters the options', (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AtomTheme.light(),
      home: Scaffold(
        body: AtomSelectField<String>(
          title: 'Choose your city',
          options: const ['Lahore', 'Faisalabad', 'Multan'],
          label: (c) => c,
          selected: null,
          hint: 'Select city',
          onChanged: (c) => picked = c,
        ),
      ),
    ));
    await tester.tap(find.text('Select city'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your city'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mul');
    await tester.pumpAndSettle();
    expect(find.text('Lahore'), findsNothing);
    expect(find.text('Multan'), findsOneWidget);

    await tester.tap(find.text('Multan'));
    await tester.pumpAndSettle();
    expect(picked, 'Multan');
  });

  testWidgets('a page missing on the server is not blamed on the internet', (tester) async {
    Future<void> show(Object error) => tester.pumpWidget(MaterialApp(
          theme: AtomTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: InfoPageError(onRetry: () {}, websiteUrl: 'https://atomshop.pk/terms', error: error))),
        ));

    await show(const AtomApiException('Not found', statusCode: 404));
    expect(find.text('Read this on our website'), findsOneWidget);
    expect(find.textContaining('internet'), findsNothing);

    await show(const AtomApiException('Check your internet connection and try again.'));
    expect(find.text('You are offline'), findsOneWidget);
  });

  group('AtomAutoScrollRow', () {
    Widget row({bool reduceMotion = false}) => MediaQuery(
          data: MediaQueryData(size: const Size(400, 800), disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AtomAutoScrollRow(
              height: 100,
              itemWidth: 150,
              itemCount: 10,
              itemBuilder: (_, i) => Text('Item $i'),
            ),
          ),
        );

    double offset(WidgetTester tester) => tester.widget<ListView>(find.byType(ListView)).controller!.offset;

    testWidgets('drifts slowly on its own', (tester) async {
      await tester.pumpWidget(row());
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // About 20 px a second.
      expect(offset(tester), inInclusiveRange(30, 50));
    });

    testWidgets('stops while touched', (tester) async {
      await tester.pumpWidget(row());
      await tester.pump(const Duration(milliseconds: 500));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      final held = offset(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(offset(tester), held);
      await gesture.up();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('stays still when the phone asks for reduced motion', (tester) async {
      await tester.pumpWidget(row(reduceMotion: true));
      await tester.pump(const Duration(seconds: 2));
      expect(offset(tester), 0);
    });
  });

  group('AtomLeaveGuard', () {
    Future<void> openGuarded(WidgetTester tester, {required bool dirty}) async {
      await tester.pumpWidget(MaterialApp(
        theme: AtomTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AtomLeaveGuard(dirty: dirty, child: const Scaffold(body: Text('Form'))),
                )),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('an untouched form closes at once', (tester) async {
      await openGuarded(tester, dirty: false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsNothing);
    });

    testWidgets('an edited form asks first and stays on "Keep editing"', (tester) async {
      await openGuarded(tester, dirty: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave this form?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsNothing);
    });
  });
}
