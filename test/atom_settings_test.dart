import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/screens/account/atom_settings_screen.dart';
import 'package:atompro/state/atom_connectivity.dart';
import 'package:atompro/state/atom_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings shows only what the session allows.
void main() {
  setUp(() => PackageInfo.setMockInitialValues(
        appName: 'Atomshop',
        packageName: 'com.ecommerce.atomshop',
        version: '2.0.0',
        buildNumber: '25',
        buildSignature: '',
      ));

  Future<void> open(WidgetTester tester, {required bool signedIn}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        atomSignedInProvider.overrideWithValue(signedIn),
        onlineProvider.overrideWithValue(const AsyncData(true)),
      ],
      child: MaterialApp(theme: AtomTheme.light(), home: const AtomSettingsScreen()),
    ));
    await tester.pump();
  }

  testWidgets('a guest gets sign in, never sign out or delete account', (tester) async {
    await open(tester, signedIn: false);
    expect(find.text('Sign in or create an account'), findsOneWidget);
    expect(find.text('Delete account'), findsNothing);
    expect(find.text('Change password'), findsNothing);
    await tester.scrollUntilVisible(find.text('© Atomshop.pk'), 300);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Version 2.0.0 (build 25)'), findsOneWidget);
  });

  testWidgets('a signed-in customer gets account security and sign out', (tester) async {
    await open(tester, signedIn: true);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sign out'), 300);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
