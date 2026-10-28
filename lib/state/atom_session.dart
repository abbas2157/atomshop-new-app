import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/services/fcm_service.dart';
import '../data/atom_auth.dart';
import '../data/atom_http.dart';

/// Who is using the app. The app opens as a guest (owner decision
/// 2026-10-28); signing in is needed only for orders, installments and
/// payments.
class AtomSession {
  const AtomSession.guest()
      : signedIn = false,
        name = null,
        phone = null;

  const AtomSession.signedIn({required this.name, this.phone}) : signedIn = true;

  final bool signedIn;
  final String? name;
  final String? phone;

  /// "MA" for the avatar.
  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

/// Single source of truth for guest vs signed in. Screens and the bottom bar
/// watch this instead of reading secure storage themselves.
final atomSessionProvider = AsyncNotifierProvider<AtomSessionNotifier, AtomSession>(AtomSessionNotifier.new);

class AtomSessionNotifier extends AsyncNotifier<AtomSession> {
  @override
  Future<AtomSession> build() {
    // A token revoked elsewhere (password reset, another sign-out) makes the
    // app a guest again instead of failing every signed-in call.
    AtomHttp.onUnauthorised = () => _forget();
    ref.onDispose(() => AtomHttp.onUnauthorised = null);
    return _read();
  }

  Future<AtomSession> _read() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return const AtomSession.guest();
    return AtomSession.signedIn(name: await SessionManager.getUserName(), phone: await SessionManager.getPhone());
  }

  /// Call after the login screen saves a session.
  Future<void> refresh() async => state = AsyncData(await _read());

  Future<void> signOut() async {
    // Revoke the token and stop pushes for the account, then forget it here.
    await ref.read(atomAuthApiProvider).signOut();
    await FcmService.unlinkUser();
    await _forget();
  }

  Future<void> _forget() async {
    if (state.value?.signedIn == false) return;
    await SessionManager.logout();
    state = const AsyncData(AtomSession.guest());
    // Keep receiving guest pushes on this phone.
    await FcmService.syncToken();
  }
}

/// Convenience: true only once the session is known and signed in.
final atomSignedInProvider = Provider<bool>((ref) => ref.watch(atomSessionProvider).value?.signedIn ?? false);
