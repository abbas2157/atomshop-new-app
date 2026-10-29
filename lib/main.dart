import 'dart:async';

import 'package:atompro/app.dart';
import 'package:atompro/shell/atom_error_boundary.dart';
import 'package:atompro/core/services/facebook_events_service.dart';
import 'package:atompro/core/services/fcm_service.dart';
import 'package:atompro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  atomLaunchClock.start();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Decode the launch cover's picture now, so the app's first frame
  // already shows it (see AtomApp).
  await _precacheLaunchCover();
  installAtomErrorBoundary();
  await initAtomApp();
  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await _initializeFirebase();
  await FacebookEventsService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // content behind status bar
      systemNavigationBarColor: Colors.transparent, // content behind nav bar
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(retry: atomRetry, child: AtomApp()));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FCM] Firebase.initializeApp() succeeded.');
    await FcmService.initialize();
    debugPrint('[FCM] FcmService.initialize() completed.');
  } on UnsupportedError catch (e) {
    debugPrint('[FCM] Firebase unsupported on this platform: $e');
  } catch (e, st) {
    debugPrint('[FCM] Firebase/FCM initialization threw: $e');
    debugPrint('[FCM] $st');
    // Push notification setup is best effort and must not block app startup.
  }
}

Future<void> _precacheLaunchCover() async {
  final done = Completer<void>();
  final stream = const AssetImage('assets/launcher/splash_android12.png').resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, _) => done.isCompleted ? null : done.complete(),
    onError: (_, _) => done.isCompleted ? null : done.complete(),
  );
  stream.addListener(listener);
  // Never hold up the launch for long.
  await done.future.timeout(const Duration(seconds: 1), onTimeout: () {});
  stream.removeListener(listener);
}
