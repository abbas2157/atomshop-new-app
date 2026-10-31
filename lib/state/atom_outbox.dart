import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../data/atom_account.dart';
import '../data/atom_auth.dart';
import '../data/atom_http.dart';
import '../data/atom_offline_store.dart';
import '../shell/atom_feedback.dart';
import 'atom_account_providers.dart';
import 'atom_connectivity.dart';

/// What a customer can do offline and have sent later.
enum OutboxKind { offer, customOrder, profile, location, photo }

/// One thing made offline, waiting on the phone to be sent.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.payload,
    this.files = const [],
    this.owner = '',
    this.error = '',
  });

  final String id;
  final OutboxKind kind;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  /// Photos, copied into the app's folder ([AtomOfflineStore.keepFile]).
  final List<String> files;

  /// The account it was made on ('' for a guest). Account changes wait
  /// until that account is signed in again.
  final String owner;

  /// Why the server refused it; it then waits for the customer instead of
  /// being sent again.
  final String error;

  bool get refused => error.isNotEmpty;

  /// "Offer: iPhone 15", "Profile changes".
  String get title => switch (kind) {
        OutboxKind.offer => 'Offer: ${payload['product'] ?? ''}',
        OutboxKind.customOrder => 'Custom order: ${payload['product_title'] ?? ''}',
        OutboxKind.profile => 'Profile changes',
        OutboxKind.location => 'City and area',
        OutboxKind.photo => 'Profile photo',
      };

  OutboxItem refusedWith(String message) =>
      OutboxItem(id: id, kind: kind, createdAt: createdAt, payload: payload, files: files, owner: owner, error: message);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'created_at': createdAt.toIso8601String(),
        'payload': payload,
        'files': files,
        'owner': owner,
        'error': error,
      };

  static OutboxItem? fromJson(Map<String, dynamic> j) {
    final kind = OutboxKind.values.where((k) => k.name == j['kind']).firstOrNull;
    if (kind == null) return null;
    return OutboxItem(
      id: '${j['id']}',
      kind: kind,
      createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      payload: j['payload'] is Map ? Map<String, dynamic>.from(j['payload'] as Map) : const {},
      files: [for (final f in (j['files'] as List? ?? const [])) '$f'],
      owner: '${j['owner'] ?? ''}',
      error: '${j['error'] ?? ''}',
    );
  }
}

/// What [AtomOutbox.submit] did: sent now (with the server's [result]), or
/// kept on the phone to send later.
typedef OutboxSubmit = ({bool queued, Object? result});

/// Offers, custom orders and profile changes made without a connection are
/// kept here (on the phone) and sent in the order they were made as soon as
/// the connection is back: at launch, when the network returns, when the
/// app comes back to the front, or from "Waiting to send".
final outboxProvider = NotifierProvider<AtomOutbox, List<OutboxItem>>(AtomOutbox.new);

class AtomOutbox extends Notifier<List<OutboxItem>> {
  static const _key = 'outbox';

  bool _syncing = false;

  @override
  List<OutboxItem> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final saved = await AtomOfflineStore.read(_key);
    final loaded = [
      for (final j in (saved is List ? saved : const []))
        if (j is Map) ?OutboxItem.fromJson(Map<String, dynamic>.from(j)),
    ];
    // Anything submitted while the file was being read stays.
    final ids = {for (final i in loaded) i.id};
    state = [...loaded, ...state.where((i) => !ids.contains(i.id))];
    unawaited(sync());
  }

  Future<void> _save(List<OutboxItem> items) async {
    state = items;
    await AtomOfflineStore.write(_key, [for (final i in items) i.toJson()]);
  }

  /// Profile, area and photo changes replace each other: only the latest
  /// is sent. Sending them twice changes nothing, so a request that may
  /// have reached the server can be kept too.
  static bool _isChange(OutboxKind k) => k == OutboxKind.profile || k == OutboxKind.location || k == OutboxKind.photo;

  /// Sends now when the phone is online. When it is offline, or the request
  /// never left the phone, keeps it to send later and returns queued.
  /// Any other error (a refusal, a slow server) is thrown as before, so the
  /// screen shows it.
  Future<OutboxSubmit> submit(OutboxKind kind, Map<String, dynamic> payload, {List<String> files = const []}) async {
    final offline = ref.read(onlineProvider).value == false;
    if (!offline) {
      try {
        return (queued: false, result: await _send(kind, payload, files));
      } on AtomApiException catch (e) {
        final keep = e.unsent || (_isChange(kind) && e.isOffline);
        if (!keep) rethrow;
      }
    }
    final kept = [for (final f in files) await AtomOfflineStore.keepFile(f)];
    final owner = kind == OutboxKind.offer ? '' : (await SessionManager.getUserUuid() ?? '');
    final item = OutboxItem(id: atomRequestId(), kind: kind, createdAt: DateTime.now(), payload: payload, files: kept, owner: owner);
    final replaced = _isChange(kind) ? state.where((i) => i.kind == kind && i.owner == owner).toList() : const <OutboxItem>[];
    for (final old in replaced) {
      for (final f in old.files) {
        await AtomOfflineStore.dropFile(f);
      }
    }
    await _save([...state.where((i) => !replaced.contains(i)), item]);
    return (queued: true, result: null);
  }

  Future<Object?> _send(OutboxKind kind, Map<String, dynamic> p, List<String> files) {
    final account = ref.read(atomAccountApiProvider);
    final auth = ref.read(atomAuthApiProvider);
    int? id(Object? v) => v is int ? v : int.tryParse('${v ?? ''}');
    String s(Object? v) => '${v ?? ''}';
    return switch (kind) {
      OutboxKind.offer => account.makeOffer(
          fullName: s(p['full_name']),
          phone: s(p['phone']),
          cityId: id(p['city_id']) ?? 0,
          areaId: id(p['area_id']),
          product: s(p['product']),
          onWhatsApp: p['on_whatsapp'] == true,
          photos: files,
        ),
      OutboxKind.customOrder => account.placeCustomOrder(p, photos: files),
      OutboxKind.profile => auth.updateMe(
          name: s(p['name']),
          email: s(p['email']),
          fatherName: s(p['father_name']),
          cnic: s(p['cnic']),
          alternatePhone: s(p['alternate_phone']),
          address: s(p['address']),
          workAddress: s(p['work_address']),
          cityId: id(p['city_id']),
          areaId: id(p['area_id']),
          phone: s(p['phone']),
        ),
      OutboxKind.location => auth.updateLocation(cityId: id(p['city_id']) ?? 0, areaId: id(p['area_id']) ?? 0, address: s(p['address']), phone: s(p['phone'])),
      OutboxKind.photo => auth.uploadPhoto(files.first),
    };
  }

  /// Sends what is waiting, oldest first. Stops at the first sign the
  /// server can't be reached (it is tried again later); a refusal is kept
  /// with its reason for the customer to see.
  Future<void> sync() async {
    if (_syncing || state.isEmpty || ref.read(onlineProvider).value == false) return;
    _syncing = true;
    var sent = 0;
    try {
      final me = await SessionManager.getUserUuid() ?? '';
      for (final item in List.of(state)) {
        if (item.refused || (item.owner.isNotEmpty && item.owner != me)) continue;
        try {
          await _send(item.kind, item.payload, item.files);
        } on AtomApiException catch (e) {
          if (e.isOffline || e.isUnauthorised || e.isRateLimited || e.statusCode >= 500) break;
          await _save([for (final i in state) i.id == item.id ? i.refusedWith(e.message) : i]);
          continue;
        }
        await _drop(item);
        sent++;
      }
    } finally {
      _syncing = false;
    }
    if (sent > 0) {
      AtomAccountApi.forgetOrders();
      ref
        ..invalidate(meProvider)
        ..invalidate(accountSummaryProvider)
        ..invalidate(ordersProvider)
        ..invalidate(customOrdersProvider)
        ..invalidate(offersProvider);
      atomToast(sent == 1 ? 'Sent what you saved while offline.' : 'Sent $sent things you saved while offline.');
    }
  }

  /// A refused item, sent again (the customer may have fixed the reason,
  /// e.g. by signing in).
  Future<void> retry(String id) async {
    await _save([
      for (final i in state)
        i.id == id ? OutboxItem(id: i.id, kind: i.kind, createdAt: i.createdAt, payload: i.payload, files: i.files, owner: i.owner) : i,
    ]);
    await sync();
  }

  /// Forgets an item (sent, or the customer removed it) and its photos.
  Future<void> remove(String id) async {
    final item = state.where((i) => i.id == id).firstOrNull;
    if (item != null) await _drop(item);
  }

  Future<void> _drop(OutboxItem item) async {
    for (final f in item.files) {
      await AtomOfflineStore.dropFile(f);
    }
    await _save([...state.where((i) => i.id != item.id)]);
  }
}
