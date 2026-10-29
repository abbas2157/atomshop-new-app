import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/auth/session_manager.dart';
import '../core/services/fcm_service.dart';
import '../utils/atom_format.dart';
import 'atom_http.dart';

/// Customer accounts. See [AtomAuthApi] for which endpoints and why.

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

/// Customer accounts over the existing `api/account/*` endpoints (owner,
/// 2026-10-29: use these until `api/app/auth/*` is built). Their quirks,
/// handled here so the screens stay simple:
///
/// * Failures come back as HTTP 200 with `success: false` (AtomHttp turns
///   them into [AtomApiException]).
/// * Some answers put the result in `message` and a sentence in `data`.
/// * Codes are 4 digits. Verifying one returns no token, so after a code the
///   app signs in with the password the customer just typed (kept in memory
///   for that one step only, never stored).
/// * Sign-up takes name, email and password only; the phone is saved with
///   the delivery area in the next step (`profile/update` needs phone, city,
///   area and address together).
/// * There is no sign-in by code, CNIC upload or token revocation.
class AtomAuthApi {
  const AtomAuthApi(this._http);

  final AtomHttp _http;

  /// Digits in a code from these endpoints.
  static const codeLength = 4;

  /// What `account/profile/update` can save. Father name, CNIC, alternate
  /// number, work address and email are not stored by these endpoints, so
  /// the profile screen hides them.
  static const supportsExtendedProfile = false;

  /// Code sign-in ("Get a code on WhatsApp") needs an endpoint that returns
  /// a token after a code; the old API has none.
  static const supportsCodeSignIn = false;

  // In memory between two steps of one flow (register → code, sign in →
  // code, forgot → reset). Never written to storage.
  static ({String login, String password})? _pending;
  static String _pendingPhone = '';
  static String _pendingLogin = '';

  /// Phone typed at sign-up, saved with the delivery area (step 3).
  static String get pendingPhone => _pendingPhone;

  /// The result of an envelope whose result may sit in `data` or `message`.
  static Map<String, dynamic> _result(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return _map(envelope['message']);
  }

  /// Keeps what the order form and the shell read without a network call.
  static Future<void> saveSession(String token, AtomUser user) async {
    await _saveSession(token, user);
    // Area names for Home's "Delivering to …" (ids are saved by the session).
    const storage = FlutterSecureStorage();
    await storage.write(key: 'city_title', value: user.city?.title ?? '');
    await storage.write(key: 'area_title', value: user.area?.title ?? '');
  }

  static Future<void> _saveSession(String token, AtomUser user) => SessionManager.saveUserSession(
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
    final data = _map(await _http.post('account/login', {'email': login.trim(), 'password': password, 'fcm_token': ?await _fcm()}));
    if (data['email_verified'] == false) {
      _pending = (login: login.trim(), password: password);
      // The login answer only emails the code; this also sends it by WhatsApp.
      try {
        await _http.postEnvelope('account/send/code', {'email': login.trim()});
      } on AtomApiException {
        // The emailed code still works.
      }
      throw NeedsVerification(CodeSent(id: _str(data['user_id']), channels: const [], phoneMasked: ''));
    }
    final user = _map(data['user']);
    final token = _str(user['token']);
    if (token.isEmpty) throw const AtomApiException('Could not sign you in. Please try again.');
    if (_str(user['role']).isNotEmpty && user['role'] != 'customer') {
      throw const AtomApiException('This is not a customer account. Please use the app for your account type.');
    }
    final basic = _fromOld(user, const {});
    await saveSession(token, basic);
    _pending = null;
    await FcmService.syncToken();
    // The login answer has ids only; the profile adds area names and photo.
    try {
      return await me();
    } on AtomApiException {
      return basic;
    }
  }

  /// Email is required by `account/create`; the phone waits for step 3.
  Future<CodeSent> register({required String name, required String phone, required String email, required String password}) async {
    final data = _map(await _http.post('account/create', {
      'name': name,
      'email': email.trim(),
      'password': password,
      'c_password': password,
      'fcm_token': ?await _fcm(),
    }));
    _pending = (login: email.trim(), password: password);
    _pendingPhone = phone.trim();
    return CodeSent(id: _str(data['user_id']), channels: const ['email'], phoneMasked: '');
  }

  /// Checks the code, then signs in with the password from the step before.
  Future<AtomUser> verifyRegistration({required String userUuid, required String code}) async {
    await _http.post('account/send/code/verify', {'user_id': userUuid, 'code': code});
    final pending = _pending;
    if (pending == null) throw const AtomApiException('Your account is confirmed. Please sign in.');
    return signIn(login: pending.login, password: pending.password);
  }

  Future<CodeSent> resendRegistration(String userUuid) async {
    final login = _pending?.login ?? '';
    if (login.isEmpty) throw const AtomApiException('Please go back and try again.');
    final user = _map(_result(await _http.postEnvelope('account/send/code', {'email': login}))['user']);
    final id = _str(user['uuid']);
    return CodeSent(id: id.isEmpty ? userUuid : id, channels: const [], phoneMasked: '');
  }

  Future<CodeSent> requestLoginCode(String login) async => throw const AtomApiException('Sign in with your password for now.');

  Future<AtomUser> verifyLoginCode({required String challengeId, required String code}) async => throw const AtomApiException('Sign in with your password for now.');

  /// Sends the code by WhatsApp and, for a real email, by email too.
  Future<CodeSent> forgotPassword({required String login, required bool byEmail}) async {
    final user = _map(_result(await _http.postEnvelope('account/send/code', {'email': login.trim()}))['user']);
    _pendingLogin = login.trim();
    return CodeSent(id: _str(user['uuid']), channels: const [], phoneMasked: '');
  }

  /// Checks the code. The "reset token" is the account uuid: the server
  /// accepts a new password for it for 15 minutes after a verified code.
  Future<String> verifyReset({required String resetId, required String code}) async {
    await _http.post('account/send/code/verify', {'user_id': resetId, 'code': code});
    return resetId;
  }

  Future<AtomUser> resetPassword({required String resetToken, required String password}) async {
    await _http.postEnvelope('account/send/code/reset/password', {'user_id': resetToken, 'password': password, 'c_password': password});
    final login = _pendingLogin;
    if (login.isEmpty) throw const AtomApiException('Password saved. Please sign in.');
    final user = await signIn(login: login, password: password);
    _pendingLogin = '';
    return user;
  }

  /// No customer token revocation on these endpoints; the session notifier
  /// unlinks pushes and forgets the token on the phone.
  Future<void> signOut() async {}

  Future<String> _uuid() async {
    final uuid = await SessionManager.getUserUuid() ?? '';
    if (uuid.isEmpty) throw const AtomApiException('Please sign in again.', statusCode: 401);
    return uuid;
  }

  Future<AtomUser> me() async {
    final r = _result(await _http.getEnvelope('account/profile/${await _uuid()}'));
    return _saved(_fromOld(_map(r['user']), _map(r['customer'])));
  }

  /// Saves name, phone, area and address (all are required together).
  Future<AtomUser> _update({required String name, required String phone, required int? cityId, required int? areaId, required String address}) async {
    if (cityId == null || areaId == null) throw const AtomApiException('Choose your city and area first.');
    final r = _result(await _http.postEnvelope('account/profile/update', {
      'user_id': await _uuid(),
      'name': name,
      'phone': phone,
      'city_id': cityId,
      'area_id': areaId,
      'address': address,
    }));
    if (phone.isNotEmpty) _pendingPhone = '';
    return _saved(_fromOld(_map(r['user']), _map(r['customer'])));
  }

  /// Only name, mobile, area and address are stored by these endpoints.
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
    String phone = '',
  }) async {
    final current = await me();
    return _update(
      name: name,
      phone: phone.isNotEmpty ? phone : current.phone,
      cityId: cityId ?? current.city?.id,
      areaId: areaId ?? current.area?.id,
      address: address,
    );
  }

  /// Delivery area (sign-up step 3 and Account → City and area). The old
  /// endpoint also needs the phone and an address.
  Future<AtomUser> updateLocation({required int cityId, required int areaId, String address = '', String phone = ''}) async {
    final current = await me();
    return _update(
      name: current.name,
      phone: phone.isNotEmpty ? phone : (current.phone.isNotEmpty ? current.phone : _pendingPhone),
      cityId: cityId,
      areaId: areaId,
      address: address.isNotEmpty ? address : current.address,
    );
  }

  Future<AtomUser> uploadPhoto(String path) async {
    await _http.postFiles('account/profile/upload', {'user_id': await _uuid()}, {
      'profile_image': [path],
    });
    return me();
  }

  Future<AtomUser> uploadCnic({required bool front, required String path}) async =>
      throw const AtomApiException('CNIC photos are collected when you place an order.');

  Future<void> changePassword({required String current, required String next}) async =>
      _http.postEnvelope('account/change/password', {'user_id': await _uuid(), 'old_password': current, 'new_password': next, 'confirm_password': next});

  /// Store requirement: customers can delete their account in the app. The
  /// endpoint checks the token, not a password.
  Future<void> deleteAccount(String password) async => _http.getEnvelope('account/delete/${await _uuid()}');

  Future<AtomUser> _saved(AtomUser user) async {
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) await saveSession(token, user);
    return user;
  }

  /// The old `user` (+ `customer` from the profile) as an [AtomUser].
  static AtomUser _fromOld(Map<String, dynamic> u, Map<String, dynamic> c) {
    final email = _str(u['email']);
    final cityId = _id(u['city_id']);
    final areaId = _id(u['area_id']);
    final picture = _str(u['profile_picture_url']);
    return AtomUser(
      uuid: _str(u['uuid']),
      name: _str(u['name']),
      phone: _str(u['phone']),
      // Placeholder addresses (…@atomshop.pk) are not the customer's.
      email: email.toLowerCase().endsWith('@atomshop.pk') ? '' : email,
      joinedAt: DateTime.tryParse(_str(u['created_at'])) ?? _monthDayYear(_str(u['joined_date'])),
      pictureUrl: picture.isNotEmpty ? picture : _str(c['picture']),
      city: AtomRef.fromJson(c['city']) ?? (cityId == null ? null : AtomRef(cityId, '')),
      area: AtomRef.fromJson(c['area']) ?? (areaId == null ? null : AtomRef(areaId, '')),
      address: _str(c['address']).isNotEmpty ? _str(c['address']) : _str(u['address']),
      verified: false,
      customerId: _str(u['id']),
      fatherName: '',
      cnicMasked: '',
      alternatePhone: '',
      workAddress: '',
      cnicFrontUploaded: false,
      cnicBackUploaded: false,
    );
  }

  /// "Oct 28, 2026" (the profile's joined_date).
  static DateTime? _monthDayYear(String s) {
    final m = RegExp(r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final month = months.indexOf(m.group(1)!.toLowerCase()) + 1;
    return month == 0 ? null : DateTime(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
  }
}

final atomAuthApiProvider = Provider<AtomAuthApi>((ref) => AtomAuthApi(ref.watch(atomHttpProvider)));
