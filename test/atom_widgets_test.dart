import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/responsive/atom_responsive.dart';
import 'package:atompro/widgets/atom_button.dart';
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
