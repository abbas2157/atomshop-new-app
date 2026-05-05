import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_generator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/theme/app_theme.dart';
import 'package:atompro/features/customer/splash/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Apply the theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,

          home: const SplashScreen(),
          navigatorKey: AppNavigator.navigatorKey,

          onGenerateRoute: AppRouteGenerator.generateRoute,
        );
      },
    );
  }
}
