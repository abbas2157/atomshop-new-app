import 'package:atompro/design/atom_theme.dart';
import 'package:atompro/screens/home/atom_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home's top bar fits every phone width and text size the app allows
/// (AtomTextScaleClamp keeps text between 0.9x and 1.3x).
void main() {
  // Small (iPhone SE / old Android) to large phones and small tablets, in
  // logical pixels; 360 is the most common Android width.
  const widths = [320.0, 340.0, 360.0, 375.0, 393.0, 412.0, 430.0, 600.0];
  const scales = [0.9, 1.0, 1.15, 1.3];

  for (final signedIn in [false, true]) {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('${signedIn ? 'signed in' : 'guest'} · ${width.toInt()} dp · text ${scale}x', (tester) async {
          tester.view.physicalSize = Size(width * 3, 800 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
            theme: AtomTheme.light(),
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: scale,
              maxScaleFactor: scale,
              child: Scaffold(
                body: Padding(
                  // Home's side gutter.
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeHeader(signedIn: signedIn, onSignIn: () {}, onNotifications: () {}),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          // A RenderFlex overflow is reported as an exception here.
          expect(tester.takeException(), isNull);
          expect(find.byTooltip('Notifications'), findsOneWidget);
          if (!signedIn) {
            expect(find.text('Sign in'), findsOneWidget);
            // The bell and Sign in never overlap, and both stay on screen.
            final bell = tester.getRect(find.byTooltip('Notifications'));
            final signIn = tester.getRect(find.text('Sign in'));
            expect(bell.right, lessThanOrEqualTo(signIn.left));
            expect(signIn.right, lessThanOrEqualTo(width));
            // The label is shown whole, never cut to "Sign…".
            final label = tester.renderObject<RenderParagraph>(find.text('Sign in'));
            expect(label.didExceedMaxLines, isFalse);
          }
        });
      }
    }
  }
}
