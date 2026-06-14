import 'package:atompro/core/seller_plan_upgrade_exception.dart';

/// Wraps a payload so a plan gate can be carried as DATA instead of being
/// thrown. A thrown [SellerPlanUpgradeException] puts an autoDispose provider
/// into an AsyncError state that gets re-executed on every rebuild — an
/// infinite refetch loop. Returning [SellerGated.gated] keeps the provider in a
/// stable AsyncData state; the screen renders the gate from [gate].
///
/// See docs/seller-plan-gate-loop-fix.md.
class SellerGated<T> {
  final T? value;
  final SellerPlanUpgradeException? gate;

  const SellerGated.value(this.value) : gate = null;
  const SellerGated.gated(this.gate) : value = null;

  bool get isGated => gate != null;
}
