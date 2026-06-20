import 'package:atompro/core/cache/reference_data_provider.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_generator.dart';
import 'package:atompro/core/services/fcm_service.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/theme/app_theme.dart';
import 'package:atompro/core/theme/theme_controller.dart';
import 'package:atompro/features/customer/splash/view/splash_screen.dart';
import 'package:atompro/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await _initializeFirebase();

  // Optional: Customize status & navigation bar appearance
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // content behind status bar
      systemNavigationBarColor: Colors.transparent, // content behind nav bar
      statusBarIconBrightness: Brightness.dark, // light/dark icons
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Kick off reference data cache load + silent background sync.
    // Runs once per app session; provider stays alive for the lifetime of
    // ProviderScope so cities / areas / categories / brands are always ready.
    ref.read(referenceDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the customer theme mode and apply it to the dynamic palette
    // before the theme is built, so every ColorPalette.* reference adapts.
    final mode = ref.watch(customerThemeModeProvider);
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    ColorPalette.isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    return ScreenUtilPlusInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp(
          title: 'AtomShop',
          scaffoldMessengerKey: SnackbarService().scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          // Single theme built from the (now brightness-aware) ColorPalette.
          theme: AppTheme.theme,

          home: const SplashScreen(),
          navigatorKey: AppNavigator.navigatorKey,

          onGenerateRoute: AppRouteGenerator.generateRoute,
        );
      },
    );
  }
}
