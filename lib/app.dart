import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/auth/session_manager.dart';

import 'design/atom_theme.dart';
import 'memory/atom_image_memory.dart';
import 'responsive/atom_responsive.dart';
import 'shell/atom_shell.dart';
import 'shell/atom_update_gate.dart';

/// Start-up work for the app (call once in `main`, after the binding exists).
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
  @override
  void initState() {
    super.initState();
    // The native splash stays up until the first frame of the shell.
    WidgetsBinding.instance.addPostFrameCallback((_) => FlutterNativeSplash.remove());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atomshop',
      debugShowCheckedModeBanner: false,
      theme: AtomTheme.light(),
      builder: (context, child) => AtomTextScaleClamp(child: child!),
      home: const AtomUpdateGate(child: AtomShell()),
    );
  }
}
