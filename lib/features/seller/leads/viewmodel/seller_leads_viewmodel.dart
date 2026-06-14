import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:atompro/features/seller/leads/repository/seller_leads_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The plan gate is returned as DATA (SellerLeadsBundle.gated), never thrown.
// A thrown SellerPlanUpgradeException put the provider into an AsyncError state
// that was re-executed on every rebuild — an infinite refetch loop hammering
// the API. Settling into a stable AsyncData state (the same approach the
// dashboard provider already uses) stops the loop. The screen reads
// `bundle.gate` to decide whether to show the plan gate.
final sellerLeadsBundleProvider = FutureProvider.autoDispose
    .family<SellerLeadsBundle, SellerLeadsQuery>((ref, query) async {
  try {
    return await ref.read(sellerLeadsRepositoryProvider).getLeadsBundle(query);
  } on SellerPlanUpgradeException catch (e) {
    ref.keepAlive();
    return SellerLeadsBundle.gated(e);
  }
});

final sellerNewLeadsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.read(sellerLeadsRepositoryProvider).getNewLeadsCount();
  } catch (_) {
    return 0;
  }
});
