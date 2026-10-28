// Form rules shared by every customer form (order, custom order, offer,
// sign-up, sign-in). They match the server's rules, so a form the app
// accepts is one the server accepts too.

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Letters and spaces only (the server's `person_name` rule).
String? validatePersonName(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Enter your full name.';
  if (!RegExp(r'^[\p{L} ]+$', unicode: true).hasMatch(t)) return 'Use letters and spaces only.';
  return null;
}

/// 10 to 13 digits: 0300 1234567, +92 300 1234567.
String? validatePhone(String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Enter your phone number.';
  if (digits.length < 10 || digits.length > 13) return 'Enter a valid phone number, e.g. 0300 1234567.';
  return null;
}

String? validateOptionalEmail(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  return _email.hasMatch(t) ? null : 'Enter a valid email or leave it empty.';
}

/// Phone (03xx…, +92…, 3xx…) or email, for signing in.
String? validateLogin(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Enter your phone number or email.';
  if (t.contains('@')) return _email.hasMatch(t) ? null : 'Enter a valid email.';
  final digits = t.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 13) return 'Enter a valid phone number, e.g. 0300 1234567.';
  return null;
}

String? validateNewPassword(String? v) => (v ?? '').length < 8 ? 'Use at least 8 characters.' : null;
