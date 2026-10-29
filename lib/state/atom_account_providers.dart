import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/atom_account.dart';
import '../data/atom_auth.dart';
import '../data/atom_site_pages.dart';
import 'atom_catalogue_providers.dart';
import 'atom_cache.dart';
import 'atom_session.dart';

/// Signed-in data. Every provider here watches the session, so signing in
/// or out drops what belonged to the previous person.

final meProvider = FutureProvider.autoDispose<AtomUser>((ref) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAuthApiProvider).me();
});

final accountSummaryProvider = FutureProvider.autoDispose<AccountSummary>((ref) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).summary();
});

/// First page of orders per filter (all, active, completed).
final ordersProvider = FutureProvider.autoDispose.family<OrdersPage, String>((ref, status) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).orders(status: status);
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetail, String>((ref, uuid) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).order(uuid);
});

/// Installments tab: active, pending, completed.
final installmentsProvider = FutureProvider.autoDispose.family<InstallmentsOverview, String>((ref, tab) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).installments(tab);
});

/// First page of payments, all orders ('') or one order's uuid.
final paymentsProvider = FutureProvider.autoDispose.family<PaymentsPage, String>((ref, orderUuid) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).payments(orderUuid: orderUuid.isEmpty ? null : orderUuid);
});

final receiptProvider = FutureProvider.autoDispose.family<Receipt, int>((ref, id) {
  ref.watch(atomSignedInProvider);
  return ref.watch(atomAccountApiProvider).receipt(id);
});

final customOrdersProvider = FutureProvider.autoDispose<List<CustomOrderRow>>((ref) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).customOrders();
});

final offersProvider = FutureProvider.autoDispose<List<OfferRow>>((ref) {
  ref.watch(atomSignedInProvider);
  ref.cacheFor(AtomCacheTime.list);
  return ref.watch(atomAccountApiProvider).offers();
});

final askAtomSuggestionsProvider = FutureProvider.autoDispose<List<AskAtomSuggestion>>((ref) {
  ref.cacheFor(AtomCacheTime.catalogue);
  return ref.watch(atomAccountApiProvider).askAtomSuggestions();
});

/// about, why, faqs, privacy, refund, app-privacy.
/// A content page (privacy, refund, terms, faqs). The server's copy wins;
/// until `api/app/pages/{slug}` is live, or when it fails, the website's
/// text bundled in the app is shown instead (lib/data/atom_site_pages.dart).
final pageContentProvider = FutureProvider.autoDispose.family<PageContent, String>((ref, slug) async {
  ref.cacheFor(AtomCacheTime.catalogue);
  try {
    return await ref.watch(atomAccountApiProvider).page(slug);
  } catch (_) {
    final fee = ref.read(appConfigProvider).value?.atompayFeePercent ?? 3;
    final bundled = atomSitePage(slug, atompayFeePercent: fee);
    if (bundled == null) rethrow;
    return bundled;
  }
});

/// Unread count for the bell; refreshed by the notifications screen.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(atomSignedInProvider)) return 0;
  ref.cacheFor(AtomCacheTime.list);
  return (await ref.watch(atomAccountApiProvider).notifications()).unread;
});

/// After any change to orders or payments (an order placed, a profile
/// saved), drop the cached account lists so screens refetch.
void refreshAccount(WidgetRef ref) {
  AtomAccountApi.forgetOrders();
  ref
    ..invalidate(accountSummaryProvider)
    ..invalidate(ordersProvider)
    ..invalidate(installmentsProvider)
    ..invalidate(paymentsProvider)
    ..invalidate(customOrdersProvider)
    ..invalidate(offersProvider)
    ..invalidate(meProvider);
}
