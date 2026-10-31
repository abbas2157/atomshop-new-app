import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/network/reachability.dart';
import '../data/atom_api.dart';
import '../data/atom_order.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../state/atom_account_providers.dart';
import '../state/atom_catalogue_providers.dart';
import '../state/atom_connectivity.dart';
import '../state/atom_outbox.dart';
import '../state/atom_session.dart';
import 'atom_feedback.dart';

/// Slim banner over every screen while the phone is offline or the server
/// can't be reached. When the connection comes back it says so once,
/// reloads whatever failed to load (so no screen needs a manual retry) and
/// sends what was saved offline (the outbox). It also keeps the city and
/// area lists saved on the phone for offline forms.
class AtomOfflineBanner extends ConsumerStatefulWidget {
  const AtomOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtomOfflineBanner> createState() => _AtomOfflineBannerState();
}

class _AtomOfflineBannerState extends ConsumerState<AtomOfflineBanner> with WidgetsBindingObserver {
  bool _wasDown = false;

  @override
  void initState() {
    super.initState();
    atomServerReachable.addListener(_onChange);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _savePlaces());
  }

  @override
  void dispose() {
    _retry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    atomServerReachable.removeListener(_onChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(outboxProvider.notifier).sync();
  }

  /// Every city's areas, the customer's own city first (at most weekly).
  Future<void> _savePlaces() async {
    if (!mounted) return;
    final api = ref.read(atomOrderApiProvider);
    await api.savePlacesForOffline(first: int.tryParse(await SessionManager.getCityId() ?? ''));
  }

  void _onChange() {
    if (mounted) setState(() {});
    _keepTrying();
  }

  /// While the phone has a network but the server has not answered, asks
  /// again every 20 seconds, so the banner clears (and the outbox sends)
  /// without the customer having to load something.
  Timer? _retry;

  void _keepTrying() {
    final online = ref.read(onlineProvider).value ?? true;
    if (!online || atomServerReachable.value) {
      _retry?.cancel();
      _retry = null;
      return;
    }
    _retry ??= Timer.periodic(const Duration(seconds: 20), (_) => _ping());
  }

  /// One small request (the app settings); any answer marks the server
  /// reachable again.
  void _ping() => ref.read(atomCatalogueApiProvider).config().ignore();

  /// Reload data that failed while offline (only failed ones: working
  /// screens keep what they show).
  void _recover() {
    ref.read(outboxProvider.notifier).sync();
    _savePlaces();
    if (ref.exists(appConfigProvider) && ref.read(appConfigProvider).hasError) ref.invalidate(appConfigProvider);
    if (ref.exists(featuredProductsProvider) && ref.read(featuredProductsProvider).hasError) ref.invalidate(featuredProductsProvider);
    if (ref.exists(topPicksProvider) && ref.read(topPicksProvider).hasError) ref.invalidate(topPicksProvider);
    if (ref.exists(homeBrandsProvider) && ref.read(homeBrandsProvider).hasError) ref.invalidate(homeBrandsProvider);
    if (ref.exists(allBrandsProvider) && ref.read(allBrandsProvider).hasError) ref.invalidate(allBrandsProvider);
    if (ref.exists(accountSummaryProvider) && ref.read(accountSummaryProvider).hasError) ref.invalidate(accountSummaryProvider);
    if (ref.exists(meProvider) && ref.read(meProvider).hasError) ref.invalidate(meProvider);
    // Families (one category's products, one product…): reload them all;
    // only the ones on screen are alive.
    ref
      ..invalidate(categoryProductsProvider)
      ..invalidate(brandProductsProvider)
      ..invalidate(productDetailProvider)
      ..invalidate(ordersProvider)
      ..invalidate(installmentsProvider)
      ..invalidate(paymentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider).value ?? true;
    final reachable = atomServerReachable.value;
    final down = !online || !reachable;
    // Watching keeps the outbox loaded (it sends what waits at launch).
    final waiting = ref.watch(outboxProvider).length;
    // Account changes made offline wait for their account to sign in.
    ref.listen(atomSignedInProvider, (_, signedIn) {
      if (signedIn) ref.read(outboxProvider.notifier).sync();
    });
    // The network is back: send now. The server counts as unreachable until
    // a request answers, and the outbox's own request is that first answer.
    ref.listen(onlineProvider, (was, now) {
      if (was?.value == false && now.value == true) {
        ref.read(outboxProvider.notifier).sync();
        if (!atomServerReachable.value) _ping();
      }
      _keepTrying();
    });

    if (_wasDown && !down) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        atomToast('Back online');
        _recover();
      });
    }
    _wasDown = down;

    if (!down) return widget.child;

    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Material(
            color: AtomColors.ink,
            child: Padding(
              padding: EdgeInsets.fromLTRB(AtomSpace.md, top + 6, AtomSpace.md, 8),
              child: Row(
                children: [
                  Icon(online ? Icons.cloud_off_rounded : Icons.wifi_off_rounded, size: 18, color: AtomColors.amber),
                  const SizedBox(width: AtomSpace.xs),
                  Expanded(
                    child: Text(
                      waiting > 0
                          ? "${online ? "Can't reach Atomshop right now." : "You're offline."} ${waiting == 1 ? '1 thing is' : '$waiting things are'} waiting to send."
                          : online
                              ? "Can't reach Atomshop right now. We'll keep trying."
                              : "You're offline. You can still make offers, custom orders and profile changes.",
                      style: AtomText.small.copyWith(color: AtomColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The banner covers the status bar area, so the page below starts
        // without its own top inset.
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child)),
      ],
    );
  }
}
