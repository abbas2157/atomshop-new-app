// Generated from Firebase CLI configuration for project atomshop-a726c.
// Keep this file in sync if Firebase app IDs change.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzBNdhyf_KOpV475tyiFnG_gKdIjvOHM0',
    appId: '1:1029416266088:android:efef4e633501b7afc70edd',
    messagingSenderId: '1029416266088',
    projectId: 'atomshop-a726c',
    storageBucket: 'atomshop-a726c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2HNiImL6ZBe79B0Skg56E910BJiD7L5E',
    appId: '1:1029416266088:ios:683d4d19a0de160cc70edd',
    messagingSenderId: '1029416266088',
    projectId: 'atomshop-a726c',
    storageBucket: 'atomshop-a726c.firebasestorage.app',
    iosBundleId: 'com.atomservices.atomshop',
  );
}
