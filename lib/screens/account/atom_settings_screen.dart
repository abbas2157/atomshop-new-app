import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_feedback.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_connectivity.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_logo.dart';
import '../../widgets/atom_page.dart';
import '../info/atom_info_widgets.dart';
import '../info/atom_legal_screen.dart';
import 'atom_account_screen.dart';
import 'atom_account_widgets.dart';

/// Settings, for guests and signed-in customers.
///
/// Shows only what the app and server really support: there is no dark
/// theme or second language in the design, and no promotional, SMS or
/// device-session controls on the server, so none are offered here.
class AtomSettingsScreen extends ConsumerStatefulWidget {
  const AtomSettingsScreen({super.key});

  @override
  ConsumerState<AtomSettingsScreen> createState() => _AtomSettingsScreenState();
}

class _AtomSettingsScreenState extends ConsumerState<AtomSettingsScreen> {
  late final AppLifecycleListener _lifecycle;
  AuthorizationStatus? _push;
  int? _cacheBytes;
  PackageInfo? _info;
  bool _clearing = false;

  /// cached_network_image keeps pictures here (flutter_cache_manager's
  /// default key), inside the temporary directory.
  static const _imageCacheFolder = 'libCachedImageData';

  @override
  void initState() {
    super.initState();
    // Coming back from the phone's settings may have changed permission.
    _lifecycle = AppLifecycleListener(onResume: _readPush);
    _readPush();
    _readCache();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _readPush() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) setState(() => _push = settings.authorizationStatus);
    } catch (_) {
      // Firebase not ready: the row says "Unknown" and still opens settings.
    }
  }

  Future<Directory> _cacheDir() async => Directory('${(await getTemporaryDirectory()).path}/$_imageCacheFolder');

  Future<void> _readCache() async {
    var total = 0;
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await for (final f in dir.list(recursive: true, followLinks: false)) {
          if (f is File) total += await f.length();
        }
      }
    } catch (_) {
      // Unreadable folder: show 0.
    }
    if (mounted) setState(() => _cacheBytes = total);
  }

  Future<void> _turnOnPush() async {
    if (_push == AuthorizationStatus.notDetermined) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission();
        if (mounted) setState(() => _push = settings.authorizationStatus);
        return;
      } catch (_) {
        // Fall through to the phone's settings.
      }
    }
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  /// Deletes downloaded pictures only. The account, delivery area and other
  /// saved choices are untouched; pictures download again when needed.
  Future<void> _clearCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cached pictures?'),
        content: const Text('This frees space on your phone. You stay signed in and nothing in your account changes. Pictures download again when you open them.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Files in use stay; the size below shows what is left.
    }
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await _readCache();
    if (mounted) setState(() => _clearing = false);
    atomToast('Cached pictures cleared.');
  }

  void _refreshData() {
    ref
      ..invalidate(appConfigProvider)
      ..invalidate(featuredProductsProvider)
      ..invalidate(topPicksProvider)
      ..invalidate(homeBrandsProvider)
      ..invalidate(allCategoriesProvider)
      ..invalidate(allBrandsProvider);
    if (ref.read(atomSignedInProvider)) refreshAccount(ref);
    atomToast('Getting the latest products and prices.');
  }

  Future<void> _reportProblem() async {
    final email = ref.read(appConfigProvider).value?.email ?? '';
    if (email.isEmpty) {
      AtomNav.contact(context);
      return;
    }
    final info = _info;
    final version = info == null ? '' : '${info.version} (${info.buildNumber})';
    // App and phone details only, never account details.
    final body = 'What happened?\n\n\nWhat did you expect?\n\n\n---\nAtomshop app $version · ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final uri = Uri(scheme: 'mailto', path: email, query: 'subject=${Uri.encodeComponent('Problem in the Atomshop app')}&body=${Uri.encodeComponent(body)}');
    await atomOpenUrl(context, uri.toString());
  }

  String get _pushLabel => switch (_push) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => 'On',
        AuthorizationStatus.denied => 'Off',
        AuthorizationStatus.notDetermined => 'Not set',
        null => '',
      };

  static String _size(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(atomSignedInProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final pushOn = _push == AuthorizationStatus.authorized || _push == AuthorizationStatus.provisional;
    final info = _info;

    return AtomPage(
      title: 'Settings',
      children: [
        if (signedIn)
          AccountMenuGroup(
            title: 'Account and security',
            rows: [
              AccountMenuRow(Icons.person_outline_rounded, 'Profile and verification', () => AtomNav.profile(context)),
              AccountMenuRow(Icons.place_outlined, 'City and area', () => AtomNav.location(context)),
              AccountMenuRow(Icons.lock_outline_rounded, 'Change password', () => AtomNav.changePassword(context)),
              AccountMenuRow(Icons.delete_outline_rounded, 'Delete account', () => confirmDeleteAccount(context, ref)),
            ],
          )
        else
          AccountMenuGroup(
            title: 'Account',
            rows: [
              AccountMenuRow(Icons.login_rounded, 'Sign in or create an account', () => AtomNav.signIn(context)),
              AccountMenuRow(Icons.place_outlined, 'Delivery area', () => AtomNav.location(context)),
            ],
          ),
        AccountMenuGroup(
          title: 'Notifications',
          rows: [
            AccountMenuRow(
              pushOn ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
              pushOn ? 'Push notifications' : 'Turn on push notifications',
              _turnOnPush,
              value: _pushLabel,
            ),
            if (signedIn) AccountMenuRow(Icons.inbox_outlined, 'Notification inbox', () => AtomNav.notifications(context)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AtomSpace.xs),
          child: Text(
            'We send order updates, payment reminders and receipts. Change what your phone shows in its settings.',
            style: AtomText.small,
          ),
        ),
        AccountMenuGroup(
          title: 'Storage and data',
          rows: [
            AccountMenuRow(Icons.image_outlined, _clearing ? 'Clearing…' : 'Clear cached pictures', _clearing ? () {} : _clearCache, value: _size(_cacheBytes)),
            AccountMenuRow(Icons.sync_rounded, 'Refresh products and prices', _refreshData),
            AccountMenuRow(online ? Icons.wifi_rounded : Icons.wifi_off_rounded, 'Connection', () => AppSettings.openAppSettings(type: AppSettingsType.wifi), value: online ? 'Online' : 'Offline'),
          ],
        ),
        AccountMenuGroup(
          title: 'Help and support',
          rows: [
            AccountMenuRow(Icons.help_outline_rounded, 'FAQs', () => AtomNav.faqs(context)),
            AccountMenuRow(Icons.phone_outlined, 'Contact us', () => AtomNav.contact(context)),
            AccountMenuRow(Icons.bug_report_outlined, 'Report a problem', _reportProblem),
          ],
        ),
        AccountMenuGroup(
          title: 'Privacy and legal',
          rows: [
            AccountMenuRow(Icons.shield_outlined, 'Privacy policy and terms', () => AtomNav.legal(context, tab: LegalTab.privacy)),
            AccountMenuRow(Icons.assignment_return_outlined, 'Returns and refunds', () => AtomNav.legal(context, tab: LegalTab.returns)),
            AccountMenuRow(Icons.admin_panel_settings_outlined, 'App permissions', () => AppSettings.openAppSettings()),
          ],
        ),
        AccountMenuGroup(
          title: 'About',
          rows: [
            AccountMenuRow(Icons.info_outline_rounded, 'About Atomshop', () => AtomNav.about(context)),
            AccountMenuRow(
              Icons.description_outlined,
              'Open-source licences',
              () => showLicensePage(
                context: context,
                applicationName: 'Atomshop',
                applicationVersion: info?.version,
                applicationIcon: const Padding(padding: EdgeInsets.all(AtomSpace.sm), child: AtomLogo(height: 36)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AtomSpace.lg),
        const Center(child: AtomLogo(height: 36)),
        const SizedBox(height: AtomSpace.xs),
        if (info != null) Text('Version ${info.version} (build ${info.buildNumber})', textAlign: TextAlign.center, style: AtomText.small),
        Text('© Atomshop.pk', textAlign: TextAlign.center, style: AtomText.small),
        if (signedIn) ...[
          const SizedBox(height: AtomSpace.md),
          Center(
            child: TextButton.icon(
              onPressed: () => confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('Sign out', style: AtomText.label.copyWith(color: AtomColors.rose)),
              style: TextButton.styleFrom(foregroundColor: AtomColors.rose, minimumSize: const Size(44, 44)),
            ),
          ),
        ],
        SizedBox(height: context.atomGutter),
      ],
    );
  }
}
