import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../core/services/fcm_service.dart';
import '../utils/atom_format.dart';
import 'atom_http.dart';

/// Customer accounts over `api/app/auth/*` and `api/app/me*`
/// (docs/backend-prompt-app-v2.md, sections A and B). Codes are sent by
/// WhatsApp (and email when the account has a real one) and never come
/// back in a response.

String _str(Object? v) => v == null ? '' : v.toString();
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
int? _id(Object? v) => AtomFormat.parseAmount(v);

/// `{id, title}` (city or area).
class AtomRef {
  const AtomRef(this.id, this.title);

  final int id;
  final String title;

  static AtomRef? fromJson(Object? v) {
    final m = _map(v);
    final id = _id(m['id']);
    return id == null ? null : AtomRef(id, _str(m['title']));
  }
}

class AtomUser {
  const AtomUser({
    required this.uuid,
    required this.name,
    required this.phone,
    required this.email,
    required this.joinedAt,
    required this.pictureUrl,
    required this.city,
    required this.area,
    required this.address,
    required this.verified,
    required this.customerId,
    required this.fatherName,
    required this.cnicMasked,
    required this.alternatePhone,
    required this.workAddress,
    required this.cnicFrontUploaded,
    required this.cnicBackUploaded,
  });

  final String uuid;
  final String name;
  final String phone;
  final String email;
  final DateTime? joinedAt;
  final String pictureUrl;
  final AtomRef? city;
  final AtomRef? area;
  final String address;
  final bool verified;
  final String customerId;
  final String fatherName;
  final String cnicMasked;
  final String alternatePhone;
  final String workAddress;
  final bool cnicFrontUploaded;
  final bool cnicBackUploaded;

  /// "Johar Town, Lahore".
  String get place => [area?.title, city?.title].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  factory AtomUser.fromJson(Map<String, dynamic> j) => AtomUser(
        uuid: _str(j['uuid']),
        name: _str(j['name']),
        phone: _str(j['phone']),
        email: _str(j['email']),
        joinedAt: DateTime.tryParse(_str(j['joined_at'])),
        pictureUrl: _str(j['picture_url']),
        city: AtomRef.fromJson(j['city']),
        area: AtomRef.fromJson(j['area']),
        address: _str(j['address']),
        verified: j['verified'] == true,
        customerId: _str(j['customer_id']),
        fatherName: _str(j['father_name']),
        cnicMasked: _str(j['cnic_masked']),
        alternatePhone: _str(j['alternate_phone']),
        workAddress: _str(j['work_address']),
        cnicFrontUploaded: j['cnic_front_uploaded'] == true,
        cnicBackUploaded: j['cnic_back_uploaded'] == true,
      );
}

/// A code was sent. [id] is what the next step sends back (user uuid,
/// challenge id or reset id).
class CodeSent {
  const CodeSent({required this.id, required this.channels, required this.phoneMasked});

  final String id;

  /// "whatsapp", "email".
  final List<String> channels;

  /// "0300 ••• 4567", or empty when the server does not say.
  final String phoneMasked;

  bool get byWhatsApp => channels.isEmpty || channels.contains('whatsapp');

  factory CodeSent.fromJson(Map<String, dynamic> j, String idKey) => CodeSent(
        id: _str(j[idKey]),
        channels: (j['sent_to'] is List ? j['sent_to'] as List : const []).map((e) => e.toString()).toList(growable: false),
        phoneMasked: _str(j['phone_masked']),
      );
}

/// Sign-in needs the account's code first (registered but never verified).
class NeedsVerification implements Exception {
  const NeedsVerification(this.code);

  final CodeSent code;
}

class AtomAuthApi {
  const AtomAuthApi(this._http);

  final AtomHttp _http;

  Future<AtomUser> _signedIn(Object? data) async {
    final j = _map(data);
    final token = _str(j['token']);
    final user = AtomUser.fromJson(_map(j['user']));
    if (token.isEmpty) throw const AtomApiException('Could not sign you in. Please try again.');
    await saveSession(token, user);
    await FcmService.syncToken();
    return user;
  }

  /// Keeps what the order form and the shell read without a network call.
  static Future<void> saveSession(String token, AtomUser user) => SessionManager.saveUserSession(
        token: token,
        userId: user.customerId,
        username: user.name,
        userUuid: user.uuid,
        role: 'customer',
        phone: user.phone,
        email: user.email,
        cityId: user.city?.id.toString(),
        areaId: user.area?.id.toString(),
        address: user.address,
      );

  Future<String?> _fcm() => FcmService.getToken();

  /// Phone or email plus password. Throws [NeedsVerification] for an account
  /// that never confirmed its code (a new code is sent).
  Future<AtomUser> signIn({required String login, required String password}) async {
    try {
      return await _signedIn(await _http.post('app/auth/login', {'login': login.trim(), 'password': password, 'fcm_token': ?await _fcm()}));
    } on AtomApiException catch (e) {
      if (e.data['needs_verification'] == true) throw NeedsVerification(CodeSent.fromJson(e.data, 'user_uuid'));
      rethrow;
    }
  }

  Future<CodeSent> register({required String name, required String phone, required String email, required String password}) async {
    final data = await _http.post('app/auth/register', {
      'name': name,
      'phone': phone,
      if (email.isNotEmpty) 'email': email,
      'password': password,
      'password_confirmation': password,
      'fcm_token': ?await _fcm(),
    });
    return CodeSent.fromJson(_map(data), 'user_uuid');
  }

  Future<AtomUser> verifyRegistration({required String userUuid, required String code}) async =>
      _signedIn(await _http.post('app/auth/register/verify', {'user_uuid': userUuid, 'code': code}));

  Future<CodeSent> resendRegistration(String userUuid) async =>
      CodeSent.fromJson({..._map(await _http.post('app/auth/register/resend', {'user_uuid': userUuid})), 'user_uuid': userUuid}, 'user_uuid');

  /// "Get a code on WhatsApp" sign-in.
  Future<CodeSent> requestLoginCode(String login) async =>
      CodeSent.fromJson(_map(await _http.post('app/auth/login/code', {'login': login.trim()})), 'challenge_id');

  Future<AtomUser> verifyLoginCode({required String challengeId, required String code}) async =>
      _signedIn(await _http.post('app/auth/login/code/verify', {'challenge_id': challengeId, 'code': code, 'fcm_token': ?await _fcm()}));

  Future<CodeSent> forgotPassword({required String login, required bool byEmail}) async => CodeSent.fromJson(
        _map(await _http.post('app/auth/password/forgot', {'login': login.trim(), 'channel': byEmail ? 'email' : 'whatsapp'})),
        'reset_id',
      );

  /// Returns the single-use reset token.
  Future<String> verifyReset({required String resetId, required String code}) async =>
      _str(_map(await _http.post('app/auth/password/verify', {'reset_id': resetId, 'code': code}))['reset_token']);

  Future<AtomUser> resetPassword({required String resetToken, required String password}) async => _signedIn(
        await _http.post('app/auth/password/reset', {'reset_token': resetToken, 'password': password, 'password_confirmation': password}),
      );

  /// Server side of signing out; the session notifier clears the phone.
  Future<void> signOut() async {
    try {
      await _http.post('app/auth/logout', {'fcm_token': ?await _fcm()});
    } on AtomApiException {
      // Signing out locally must never fail because the server didn't answer.
    }
  }

  Future<AtomUser> me() async => _user(await _http.get('app/me'));

  Future<AtomUser> updateMe({
    required String name,
    required String email,
    required String fatherName,
    required String cnic,
    required String alternatePhone,
    required String address,
    required String workAddress,
    required int? cityId,
    required int? areaId,
  }) async =>
      _user(await _http.post('app/me', {
        'name': name,
        if (email.isNotEmpty) 'email': email,
        if (fatherName.isNotEmpty) 'father_name': fatherName,
        if (cnic.isNotEmpty) 'cnic': cnic.replaceAll(RegExp(r'\D'), ''),
        if (alternatePhone.isNotEmpty) 'alternate_phone': alternatePhone,
        'address': address,
        if (workAddress.isNotEmpty) 'work_address': workAddress,
        'city_id': ?cityId,
        'area_id': ?areaId,
      }));

  Future<AtomUser> updateLocation({required int cityId, required int areaId}) async =>
      _user(await _http.post('app/me/location', {'city_id': cityId, 'area_id': areaId}));

  Future<AtomUser> uploadPhoto(String path) async => _user(await _http.postFiles('app/me/photo', const {}, {'photo': [path]}));

  Future<AtomUser> uploadCnic({required bool front, required String path}) async =>
      _user(await _http.postFiles('app/me/cnic', {'side': front ? 'front' : 'back'}, {'photo': [path]}));

  Future<void> changePassword({required String current, required String next}) async =>
      _http.post('app/me/password', {'current_password': current, 'password': next, 'password_confirmation': next});

  /// Store requirement: customers can delete their account in the app.
  Future<void> deleteAccount(String password) async => _http.post('app/me/delete', {'password': password});

  Future<AtomUser> _user(Object? data) async {
    final user = AtomUser.fromJson(_map(data));
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) await saveSession(token, user);
    return user;
  }
}

final atomAuthApiProvider = Provider<AtomAuthApi>((ref) => AtomAuthApi(ref.watch(atomHttpProvider)));
