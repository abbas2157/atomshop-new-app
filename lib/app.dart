import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/auth/session_manager.dart';
import 'data/atom_http.dart';
import 'data/atom_product_detail.dart';

import 'design/atom_theme.dart';
import 'memory/atom_image_memory.dart';
import 'responsive/atom_responsive.dart';
import 'shell/atom_feedback.dart';
import 'shell/atom_offline_banner.dart';
import 'shell/atom_shell.dart';
import 'shell/atom_update_gate.dart';

/// When a failed provider tries again. Only a lost connection or a timeout
/// is worth retrying (3 times, 0.5 s, 1 s, 2 s); a real answer from the
/// server (404, 422, "product not found") is shown at once.
Duration? atomRetry(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  if (error is AtomApiException && !error.isOffline) return null;
  if (error is ProductNotFound) return null;
  return Duration(milliseconds: 500 * (1 << retryCount));
}

/// Start-up work for the app (call once in `main`, after the binding exists).
/// Started in main(), before anything else.
final atomLaunchClock = Stopwatch();

/// The shortest time the launch splash stays on screen.
const atomSplashMinimum = Duration(milliseconds: 1500);

Future<void> initAtomApp() async {
  AtomImageMemory.configure();
  await _clearOldAppData();
}

/// The previous app also had a seller mode and agent sign-ins. On the first
/// launch of this version, forget the seller session and the mode switch,
/// and sign out any session that is not a customer's (sellers and agents
/// have their own apps). Runs once.
Future<void> _clearOldAppData() async {
  const storage = FlutterSecureStorage(aOptions: AndroidOptions());
  const doneKey = 'v2_old_data_cleared';
  try {
    if (await storage.read(key: doneKey) == '1') return;
    const oldKeys = [
      'app_mode',
      'seller_auth_token',
      'seller_user_id',
      'seller_user_uuid',
      'seller_user_name',
      'seller_email',
      'seller_role',
      'seller_id',
      'seller_business_name',
      'seller_verified',
    ];
    for (final key in oldKeys) {
      await storage.delete(key: key);
    }
    final role = await SessionManager.getUserRole();
    if (await SessionManager.isLoggedIn() && role != null && role.isNotEmpty && role != 'customer') {
      await SessionManager.logout();
    }
    await storage.write(key: doneKey, value: '1');
  } catch (_) {
    // Never block start-up on storage; it tries again next launch.
  }
}

/// Root widget: Atomshop customer app.
class AtomApp extends StatefulWidget {
  const AtomApp({super.key});

  @override
  State<AtomApp> createState() => _AtomAppState();
}

class _AtomAppState extends State<AtomApp> {
  bool _covered = true;

  @override
  void initState() {
    super.initState();
    // The native splash goes at the first frame; the app's own copy of it
    // ([_LaunchCover]) takes over there and stays until [atomSplashMinimum]
    // from launch. Android 12+ shows no system splash when the app is not
    // opened from its icon (e.g. "Open" after installing), and a release
    // build draws its first frame almost at once, so without the cover the
    // splash was often never seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      final wait = atomSplashMinimum - atomLaunchClock.elapsed;
      Future<void>.delayed(wait.isNegative ? Duration.zero : wait, () {
        if (mounted) setState(() => _covered = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atomshop',
      scaffoldMessengerKey: atomMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AtomTheme.light(),
      // Dark status-bar icons by default; screens with a dark header set
      // light ones over it (an AnnotatedRegion nearer the top wins).
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: Stack(
          children: [
            AtomTextScaleClamp(child: AtomOfflineBanner(child: AtomUpdateGate(child: child!))),
            Positioned.fill(child: _LaunchCover(visible: _covered)),
          ],
        ),
      ),
      navigatorKey: atomNavigatorKey,
      home: const AtomShell(),
    );
  }
}

/// The launch splash drawn by the app: the Android 12 splash image at the
/// size the system shows it (240 x 240 on white), so the hand-over from the
/// system splash is seamless. Fades out, then stops taking touches.
class _LaunchCover extends StatelessWidget {
  const _LaunchCover({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: const ColoredBox(
          color: Colors.white,
          child: Center(
            child: Image(
              image: AssetImage('assets/launcher/splash_android12.png'),
              width: 240,
              height: 240,
              semanticLabel: 'Atomshop.pk',
            ),
          ),
        ),
      ),
    );
  }
}
