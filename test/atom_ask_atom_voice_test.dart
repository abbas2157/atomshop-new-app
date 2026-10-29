import 'package:atompro/data/atom_models.dart';
import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/screens/ask_atom/atom_ask_atom_screen.dart';
import 'package:atompro/state/atom_account_providers.dart';
import 'package:atompro/state/atom_catalogue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ask Atom has a mic for spoken questions, as on the website.
void main() {
  testWidgets('the composer has a mic labelled like the website', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        askAtomSuggestionsProvider.overrideWith((ref) async => const []),
        appConfigProvider.overrideWith((ref) async => AppConfig.fromJson(const {})),
      ],
      child: MaterialApp(theme: AtomTheme.light(), home: const AtomAskAtomScreen()),
    ));
    await tester.pump();
    expect(find.byTooltip('Speak your question'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
  });
}
