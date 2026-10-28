import 'package:atompro/app.dart';
import 'package:atompro/core/services/facebook_events_service.dart';
import 'package:atompro/core/services/fcm_service.dart';
import 'package:atompro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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

  runApp(const ProviderScope(child: AtomApp()));
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
