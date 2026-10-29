import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/reachability.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../state/atom_account_providers.dart';
import '../state/atom_catalogue_providers.dart';
import '../state/atom_connectivity.dart';
import 'atom_feedback.dart';

/// Slim banner over every screen while the phone is offline or the server
/// can't be reached. When the connection comes back it says so once and
/// reloads whatever failed to load, so no screen needs a manual retry.
class AtomOfflineBanner extends ConsumerStatefulWidget {
  const AtomOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtomOfflineBanner> createState() => _AtomOfflineBannerState();
}

class _AtomOfflineBannerState extends ConsumerState<AtomOfflineBanner> {
  bool _wasDown = false;

  @override
  void initState() {
    super.initState();
    atomServerReachable.addListener(_onChange);
  }

  @override
  void dispose() {
    atomServerReachable.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  /// Reload data that failed while offline (only failed ones: working
  /// screens keep what they show).
  void _recover() {
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
                      online ? "Can't reach Atomshop right now. We'll keep trying." : "You're offline. Showing what was already loaded.",
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
