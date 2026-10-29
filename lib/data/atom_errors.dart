import 'package:flutter/material.dart';

import 'atom_http.dart';
import 'atom_product_detail.dart';

/// Every error a customer reads goes through here, so each one is a whole,
/// plain sentence that says what happened and what to do next. Server text
/// is kept when it is already written for customers; short or technical
/// server text is rewritten; framework text is never shown.

/// Known server sentences (lower case, no end punctuation) → what to show.
const _rewrites = <String, String>{
  // Accounts (api/account/*).
  'invalid login credentials': 'Your phone number, email or password is not right. Check them and try again.',
  'user not found': 'We could not find an account with that phone number or email. Check it, or create an account.',
  'code is invalid': 'That code is not right. Check the latest message we sent and try again.',
  'code is expired': 'That code has expired. Tap “Resend code” to get a new one.',
  'old password is incorrect': 'Your current password is not right. Check it and try again.',
  'please fill all the fields': 'Please fill in all the fields.',
  'you are blocked on this website': 'This account has been blocked. Please contact us for help.',
  'your account is blocked by support team': 'This account has been paused by our support team. Please contact us for help.',
  'profile image not uploaded': 'Please choose a photo to upload.',
  'profile image upload failed': 'We could not upload your photo. Please try again.',
  'profile not retrieved error': 'We could not load your profile. Please try again.',
  'profile not updated error': 'We could not save your profile. Please try again.',
  'profile not deleted error': 'We could not delete your account. Please try again, or contact us.',
  'user registration failed': 'We could not create your account. Please try again.',
  'notification not found': 'This notification is no longer available.',
  // Generic server failures.
  'something went wrong': _serverTrouble,
  'something went wrong please try again': _serverTrouble,
  'server error': _serverTrouble,
  'error occurred': _serverTrouble,
  'unauthenticated': 'Your session has ended. Please sign in again.',
  'too many attempts': 'Too many tries. Please wait a few minutes and try again.',
};

const _offline = 'You seem to be offline. Check your internet connection and try again.';
const _slow = atomSlowMessage;

/// A request that timed out.
const atomSlowMessage = 'Atomshop is taking too long to answer. Please try again.';
const _serverTrouble = 'Something went wrong on our side. Please try again in a moment.';
const _notYet = 'This is not available in the app yet. Please try again later.';

/// Field names in validation messages, as customers know them.
const _fields = <String, String>{
  'c password': 'password confirmation',
  'c_password': 'password confirmation',
  'confirm password': 'password confirmation',
  'new password': 'new password',
  'old password': 'current password',
  'city id': 'city',
  'area id': 'area',
  'user id': 'account',
  'profile image': 'photo',
  'fcm token': 'device',
};

/// Message for [status] when the server gave nothing usable.
String atomStatusMessage(int status, {Map<String, dynamic> data = const {}}) {
  final wait = _retryAfter(data['retry_after']);
  return switch (status) {
    0 => _offline,
    400 => 'Something in that request was not right. Please check and try again.',
    401 || 419 => 'Your session has ended. Please sign in again.',
    403 => 'You do not have access to this.',
    404 => 'We could not find what you were looking for.',
    408 || 504 => _slow,
    413 => 'That file is too big. Please choose a smaller photo.',
    422 => 'Please check the details and try again.',
    429 => wait == null ? 'Too many tries. Please wait a little and try again.' : 'Too many tries. Please wait $wait and try again.',
    503 => 'Atomshop is busy right now. Please try again shortly.',
    >= 500 => _serverTrouble,
    _ => 'Something went wrong. Please try again.',
  };
}

/// The sentence to show for a server answer: [message] cleaned up, or the
/// first field error, or a message for [status].
String atomFriendlyMessage(String? message, {int status = 0, Map<String, dynamic> data = const {}}) {
  var text = (message ?? '').trim();

  // Laravel's missing-route and wrong-method texts mean the endpoint the
  // app needs is not built yet.
  if (status == 404 && text.startsWith('The route ')) return _notYet;
  if (status == 405 || text.contains('method is not supported')) return _notYet;

  // "Validation Error." carries the real reason in the field errors.
  if (text.isEmpty || _key(text) == 'validation error') {
    final field = _firstFieldError(data);
    if (field != null) return _validation(field);
    return atomStatusMessage(status, data: data);
  }

  if (_looksTechnical(text)) return atomStatusMessage(status >= 400 ? status : 500, data: data);

  if (_key(text).startsWith('too many attempts')) {
    final wait = _retryAfter(data['retry_after']);
    return wait == null ? _rewrites['too many attempts']! : 'Too many tries. Please wait $wait and try again.';
  }
  final known = _rewrites[_key(text)];
  if (known != null) return known;
  if (text.startsWith('The ') && (text.contains(' field') || text.contains(' has already been taken'))) return _validation(text);
  return _sentence(text);
}

/// The server answered that this endpoint does not exist yet (a feature
/// the app has but the backend has not built). Optional sections hide.
bool atomNotBuiltYet(Object? error) => error is AtomApiException && error.message == _notYet;

/// What a screen shows when something did not load: icon, title, message.
({IconData icon, String title, String message}) atomLoadError(Object? error) {
  if (error is ProductNotFound) {
    return (icon: Icons.inventory_2_outlined, title: 'This product is not available', message: 'It may have sold out or been taken off the store.');
  }
  if (error is AtomApiException) {
    if (error.isOffline && error.message == _slow) return (icon: Icons.hourglass_empty_rounded, title: 'Taking too long', message: _slow);
    if (error.isOffline) return (icon: Icons.wifi_off_rounded, title: 'You are offline', message: _offline);
    if (error.message == _notYet) return (icon: Icons.construction_rounded, title: 'Coming soon', message: _notYet);
    if (error.isUnauthorised) return (icon: Icons.lock_outline_rounded, title: 'Please sign in again', message: error.message);
    if (error.statusCode == 404) return (icon: Icons.search_off_rounded, title: 'Not found', message: error.message);
    if (error.statusCode >= 500) return (icon: Icons.cloud_off_rounded, title: 'Something went wrong', message: _serverTrouble);
    return (icon: Icons.error_outline_rounded, title: 'Could not load this', message: error.message);
  }
  return (icon: Icons.error_outline_rounded, title: 'Could not load this', message: atomMessage(error ?? ''));
}

String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'[.!?…]+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

bool _looksTechnical(String s) {
  final l = s.toLowerCase();
  return l.contains('sqlstate') ||
      l.contains('exception') ||
      l.contains('stack trace') ||
      l.contains('call to ') ||
      l.contains('undefined ') ||
      l.contains('trying to ') ||
      l.contains('.php') ||
      l.contains('vendor/') ||
      l.contains('<html') ||
      l.contains('dioexception') ||
      l.startsWith('network error') ||
      l.startsWith('unexpected error') ||
      l.startsWith('null check') ||
      l.contains('socketexception') ||
      l.contains('handshake');
}

String? _firstFieldError(Map<String, dynamic> data) {
  for (final v in data.values) {
    if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
    if (v is String && v.startsWith('The ')) return v;
  }
  return null;
}

/// Laravel's "The c password field must match password." in customer words.
String _validation(String raw) {
  var text = raw.trim();
  final required = RegExp(r'^The (.+?) field is required\.?$').firstMatch(text);
  if (required != null) {
    final field = _field(required.group(1)!);
    final choose = field == 'city' || field == 'area';
    return choose ? 'Please choose your $field.' : 'Please enter your $field.';
  }
  if (RegExp(r'^The email has already been taken\.?$').hasMatch(text)) {
    return 'An account with this email already exists. Sign in, or use a different email.';
  }
  if (RegExp(r'^The phone has already been taken\.?$').hasMatch(text)) {
    return 'An account with this phone number already exists. Sign in instead.';
  }
  if (RegExp(r'must match password', caseSensitive: false).hasMatch(text)) return 'The two passwords do not match.';
  for (final e in _fields.entries) {
    text = text.replaceAll(RegExp('\\b${RegExp.escape(e.key)}\\b', caseSensitive: false), e.value);
  }
  text = text.replaceAll(' field ', ' ');
  return _sentence(text);
}

String _field(String raw) {
  final f = raw.replaceAll('_', ' ').trim().toLowerCase();
  return _fields[f] ?? f;
}

/// Capital first letter, one end mark.
String _sentence(String s) {
  var t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return 'Something went wrong. Please try again.';
  t = t[0].toUpperCase() + t.substring(1);
  t = t.replaceAll(RegExp(r'\.{2,}$'), '.');
  if (!RegExp(r'[.!?]$').hasMatch(t)) t = '$t.';
  return t;
}

/// "2 minutes" / "40 seconds" from a retry_after in seconds.
String? _retryAfter(Object? v) {
  final s = v is num ? v.toInt() : int.tryParse('$v');
  if (s == null || s <= 0) return null;
  if (s < 60) return '$s seconds';
  final m = (s / 60).ceil();
  return m == 1 ? '1 minute' : '$m minutes';
}
