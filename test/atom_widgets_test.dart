import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/design/atom_tokens.dart';
import 'package:atompro/responsive/atom_responsive.dart';
import 'package:atompro/widgets/atom_button.dart';
import 'package:atompro/widgets/atom_dialog.dart';
import 'package:atompro/widgets/atom_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(390, 844)}) => MaterialApp(
      theme: AtomTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: child)),
      ),
    );

/// Widget tests for the shared app v2 widgets.
void main() {
  testWidgets('AtomButton shows its icon and label and calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(AtomButton(label: 'Sign in', icon: Icons.login_rounded, onPressed: () => taps++)));

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    expect(taps, 1);
  });

  testWidgets('AtomButton is at least 44 px tall at every size', (tester) async {
    for (final size in [AtomButtonSize.large, AtomButtonSize.medium]) {
      await tester.pumpWidget(_wrap(AtomButton(label: 'Go', icon: Icons.arrow_forward, onPressed: () {}, size: size)));
      expect(tester.getSize(find.byType(AtomButton)).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('a loading AtomButton ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(AtomButton(label: 'Send', icon: Icons.send, loading: true, onPressed: () => taps++)));
    await tester.tap(find.text('Send'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a disabled AtomButton turns grey; a loading one keeps its colour', (tester) async {
    Color fill(String label) => tester.widget<Material>(find.ancestor(of: find.text(label), matching: find.byType(Material)).first).color!;
    await tester.pumpWidget(_wrap(const Column(children: [
      AtomButton(label: 'Off', icon: Icons.send, onPressed: null),
      AtomButton(label: 'Busy', icon: Icons.send, loading: true, onPressed: null),
    ])));
    expect(fill('Off'), AtomColors.surface);
    expect(fill('Busy'), AtomColors.primary);
  });

  testWidgets('showAtomConfirm is true only for the main action', (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => TextButton(
        onPressed: () async => results.add(await showAtomConfirm(context, title: 'Sign out?', message: 'Sure?', confirmLabel: 'Sign out', confirmIcon: Icons.logout_rounded, danger: true)),
        child: const Text('Open'),
      ),
    )));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final signOut = tester.widget<AtomButton>(find.widgetWithText(AtomButton, 'Sign out'));
    expect(signOut.variant, AtomButtonVariant.danger);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // outside the dialog
    await tester.pumpAndSettle();

    expect(results, [true, false, false]);
  });

  testWidgets('order status badges use the API values, including Varification', (tester) async {
    await tester.pumpWidget(_wrap(Column(children: [AtomBadge.orderStatus('Varification'), AtomBadge.orderStatus('Instalments')])));
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Installments'), findsOneWidget);
  });

  testWidgets('screen class follows the width', (tester) async {
    late AtomScreen phone;
    late AtomScreen tablet;
    await tester.pumpWidget(_wrap(Builder(builder: (c) {
      phone = c.atomScreen;
      return const SizedBox();
    })));
    await tester.pumpWidget(_wrap(Builder(builder: (c) {
      tablet = c.atomScreen;
      return const SizedBox();
    }), size: const Size(800, 1280)));
    expect(phone, AtomScreen.compact);
    expect(tablet, AtomScreen.medium);
  });
}
