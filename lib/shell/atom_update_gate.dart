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
import '../widgets/atom_button.dart';

/// Forced and optional updates, driven by `version.min` / `version.latest`
/// in GET api/app/config. Below the minimum the app shows only the update
/// screen; below the latest it asks once per new version.
class AtomUpdateGate extends ConsumerStatefulWidget {
  const AtomUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtomUpdateGate> createState() => _AtomUpdateGateState();
}

class _AtomUpdateGateState extends ConsumerState<AtomUpdateGate> {
  static const _storage = FlutterSecureStorage();
  static const _seenKey = 'update_prompt_seen';

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateProvider, (_, next) {
      if (next.value == AppUpdate.available) _offerOnce();
    });
    final update = ref.watch(appUpdateProvider).value;
    if (update == AppUpdate.required) return const _ForceUpdateScreen();
    return widget.child;
  }

  Future<void> _offerOnce() async {
    final latest = ref.read(appConfigProvider).value?.latestVersion ?? '';
    if (latest.isEmpty || await _storage.read(key: _seenKey) == latest) return;
    await _storage.write(key: _seenKey, value: latest);
    if (!mounted) return;
    final url = storeUrl(ref.read(appConfigProvider).value);
    if (url == null) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
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

class _ForceUpdateScreen extends ConsumerWidget {
  const _ForceUpdateScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = storeUrl(ref.watch(appConfigProvider).value);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: AtomPageWidth(
            child: Padding(
              padding: EdgeInsets.all(context.atomGutter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/app-atomshop.png', width: 88, height: 88, semanticLabel: 'Atomshop'),
                  const SizedBox(height: AtomSpace.lg),
                  Semantics(header: true, child: Text('Please update Atomshop', textAlign: TextAlign.center, style: AtomText.title)),
                  const SizedBox(height: AtomSpace.xs),
                  Text(
                    'This version is no longer supported. Update the app to keep shopping and tracking your installments.',
                    textAlign: TextAlign.center,
                    style: AtomText.body.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: AtomSpace.lg),
                  AtomButton(
                    label: 'Update now',
                    icon: Icons.system_update_rounded,
                    expand: true,
                    onPressed: url == null ? null : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
