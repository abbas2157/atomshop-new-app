import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_generator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/core/theme/app_theme.dart';
import 'package:atompro/features/splash/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // dark icons on white bg
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
