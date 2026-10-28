import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/atom_models.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import '../state/atom_app_version.dart';
import '../state/atom_catalogue_providers.dart';
import '../utils/atom_format.dart';
import '../widgets/atom_button.dart';

/// Root navigator, so app-level prompts (update) can open over any page.
final atomNavigatorKey = GlobalKey<NavigatorState>();

/// Server-driven gates from GET api/app/config, over the whole app:
/// maintenance (`maintenance.enabled`), forced update (`version.min`) and a
/// one-time update prompt (`version.latest`).
///
/// The app stays mounted underneath, so a half-filled form or the page the
/// customer was on is still there when maintenance ends. The config is read
/// again when the app comes back to the front. If it can't be read, nothing
/// is blocked: these screens are UX only, the server enforces the rules.
class AtomUpdateGate extends ConsumerStatefulWidget {
  const AtomUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtomUpdateGate> createState() => _AtomUpdateGateState();
}

class _AtomUpdateGateState extends ConsumerState<AtomUpdateGate> {
  static const _storage = FlutterSecureStorage();
  static const _seenKey = 'update_prompt_seen';
  static const _recheckAfter = Duration(minutes: 2);

  late final AppLifecycleListener _lifecycle;
  DateTime _checkedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recheck);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Back in the foreground: read maintenance and version again (at most
  /// every couple of minutes, or at once from "Check again").
  void _recheck({bool force = false}) {
    if (!force && DateTime.now().difference(_checkedAt) < _recheckAfter) return;
    _checkedAt = DateTime.now();
    ref.invalidate(appConfigProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateProvider, (_, next) {
      if (next.value == AppUpdate.available) _offerOnce();
    });
    final config = ref.watch(appConfigProvider).value;
    final update = ref.watch(appUpdateProvider).value;

    final Widget? blocker = config != null && config.maintenance
        ? _MaintenanceScreen(config: config, onCheck: () => _recheck(force: true))
        : (update == AppUpdate.required ? const _ForceUpdateScreen() : null);

    return Stack(
      children: [
        // Kept alive (state, forms, the open page) but hidden and unreachable.
        Offstage(offstage: blocker != null, child: TickerMode(enabled: blocker == null, child: widget.child)),
        ?blocker,
      ],
    );
  }

  Future<void> _offerOnce() async {
    final latest = ref.read(appConfigProvider).value?.latestVersion ?? '';
    if (latest.isEmpty || await _storage.read(key: _seenKey) == latest) return;
    await _storage.write(key: _seenKey, value: latest);
    final url = storeUrl(ref.read(appConfigProvider).value);
    final dialogContext = atomNavigatorKey.currentContext;
    if (url == null || dialogContext == null || !dialogContext.mounted) return;
    await showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text('A new version is ready', style: AtomText.heading),
        content: Text('Update Atomshop to get the latest features and fixes.', style: AtomText.body),
        actions: [
          AtomButton(label: 'Later', icon: Icons.schedule_rounded, variant: AtomButtonVariant.text, size: AtomButtonSize.small, onPressed: () => Navigator.of(context).pop()),
          AtomButton(
            label: 'Update',
            icon: Icons.system_update_rounded,
            size: AtomButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop();
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}

/// This app's store page from the config (Atomshop android / ios link).
String? storeUrl(AppConfig? config) {
  final links = config?.storeLinks['atomshop'];
  final url = Platform.isIOS ? (links?['ios']) : (links?['android']);
  return (url == null || url.isEmpty) ? null : url;
}

class _GateScreen extends StatelessWidget {
  const _GateScreen({required this.icon, required this.title, required this.message, required this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AtomPageWidth(
          child: Padding(
            padding: EdgeInsets.all(context.atomGutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/app-atomshop.png', width: 88, height: 88, semanticLabel: 'Atomshop'),
                const SizedBox(height: AtomSpace.lg),
                Icon(icon, color: AtomColors.primary, size: 28),
                const SizedBox(height: AtomSpace.xs),
                Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: AtomText.title)),
                const SizedBox(height: AtomSpace.xs),
                Text(message, textAlign: TextAlign.center, style: AtomText.body.copyWith(fontSize: 15)),
                const SizedBox(height: AtomSpace.lg),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen({required this.config, required this.onCheck});

  final AppConfig config;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final until = config.maintenanceUntil?.toLocal();
    final message = config.maintenanceMessage.isNotEmpty ? config.maintenanceMessage : 'We are improving Atomshop. Your orders and installments are safe.';
    final eta = until == null ? '' : '\nExpected back by ${AtomFormat.date(until)}, ${TimeOfDay.fromDateTime(until).format(context)}.';
    return _GateScreen(
      icon: Icons.build_circle_outlined,
      title: 'Atomshop is under maintenance',
      message: '$message$eta',
      action: AtomButton(label: 'Check again', icon: Icons.refresh_rounded, expand: true, onPressed: onCheck),
    );
  }
}

class _ForceUpdateScreen extends ConsumerWidget {
  const _ForceUpdateScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = storeUrl(ref.watch(appConfigProvider).value);
    return _GateScreen(
      icon: Icons.system_update_rounded,
      title: 'Please update Atomshop',
      message: 'This version is no longer supported. Update the app to keep shopping and tracking your installments.',
      action: AtomButton(
        label: 'Update now',
        icon: Icons.system_update_rounded,
        expand: true,
        onPressed: url == null ? null : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
  }
}
