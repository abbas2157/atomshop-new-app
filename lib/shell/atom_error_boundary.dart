import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';

/// App-wide safety net (call once in `main`).
///
/// - A widget that fails to build shows a small, plain "something went
///   wrong" box in release builds instead of the red/grey error screen.
/// - Framework and uncaught async errors are logged by type only (no
///   messages, tokens or customer data) and never crash the app.
///
/// No crash-reporting service is wired in yet; when one is added
/// (e.g. Firebase Crashlytics), report from the two handlers below.
void installAtomErrorBoundary() {
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('[Atomshop] UI error: ${details.exception.runtimeType}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Atomshop] Unhandled error: ${error.runtimeType}');
    if (kDebugMode) debugPrint('$error\n$stack');
    return true;
  };

  if (!kDebugMode) {
    ErrorWidget.builder = (details) => const _BrokenPart();
  }
}

class _BrokenPart extends StatelessWidget {
  const _BrokenPart();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AtomColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AtomSpace.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AtomColors.muted, size: 18),
            const SizedBox(width: AtomSpace.xs),
            Flexible(child: Text('Something went wrong here. Go back and try again.', style: AtomText.small)),
          ],
        ),
      ),
    );
  }
}
