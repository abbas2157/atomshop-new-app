import 'package:atompro/data/atom_http.dart';
import 'package:atompro/data/atom_product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every error a customer reads is a whole, plain sentence.
void main() {
  group('atomFriendlyMessage', () {
    test('rewrites short account answers into full sentences', () {
      expect(atomFriendlyMessage('Invalid login credentials', status: 200), 'Your phone number, email or password is not right. Check them and try again.');
      expect(atomFriendlyMessage('Code is invalid', status: 200), startsWith('That code is not right.'));
      expect(atomFriendlyMessage('User not found.', status: 200), startsWith('We could not find an account'));
      expect(atomFriendlyMessage('Profile not updated Error...', status: 500), 'We could not save your profile. Please try again.');
    });

    test('uses the first field error, in customer words', () {
      expect(
        atomFriendlyMessage('Validation Error.', status: 200, data: {
          'email': ['The email has already been taken.'],
        }),
        'An account with this email already exists. Sign in, or use a different email.',
      );
      expect(
        atomFriendlyMessage('Validation Error.', status: 200, data: {
          'c_password': ['The c password field must match password.'],
        }),
        'The two passwords do not match.',
      );
      expect(
        atomFriendlyMessage('Validation Error.', status: 422, data: {
          'city_id': ['The city id field is required.'],
        }),
        'Please choose your city.',
      );
      expect(
        atomFriendlyMessage('Validation Error.', status: 200, data: {
          'name': ['The name may only contain letters and spaces.'],
        }),
        'The name may only contain letters and spaces.',
      );
    });

    test('never shows framework text', () {
      expect(atomFriendlyMessage('SQLSTATE[23000]: Integrity constraint violation', status: 500), 'Something went wrong on our side. Please try again in a moment.');
      expect(atomFriendlyMessage('The route api/app/x could not be found.', status: 404), 'This is not available in the app yet. Please try again later.');
      expect(atomFriendlyMessage('Unexpected Error: Null check operator used on a null value', status: 500), 'Something went wrong on our side. Please try again in a moment.');
    });

    test('keeps messages already written for customers, ending them properly', () {
      expect(atomFriendlyMessage('That installment tenure is not available.', status: 422), 'That installment tenure is not available.');
      expect(atomFriendlyMessage('please choose a delivery area', status: 422), 'Please choose a delivery area.');
    });

    test('says how long to wait after too many tries', () {
      expect(atomFriendlyMessage('Too many attempts. Please request a new code in a few minutes.', status: 429, data: {'retry_after': 120}), 'Too many tries. Please wait 2 minutes and try again.');
      expect(atomStatusMessage(429, data: {'retry_after': 30}), 'Too many tries. Please wait 30 seconds and try again.');
    });

    test('has a sentence for every status', () {
      for (final s in [0, 400, 401, 403, 404, 408, 413, 419, 422, 429, 500, 502, 503, 504, 418]) {
        final m = atomStatusMessage(s);
        expect(m, matches(RegExp(r'^[A-Z].*[.!?]$')), reason: 'status $s');
      }
    });
  });

  test('field errors ignore request data echoed back by older endpoints', () {
    const e = AtomApiException('Invalid login credentials', data: {'email': 'someone@example.com'});
    expect(e.fieldError('email'), isNull);
  });

  test('load errors say what happened', () {
    expect(atomLoadError(const AtomApiException('Check your internet connection and try again.')).title, 'You are offline');
    expect(atomLoadError(const AtomApiException('x', statusCode: 503)).icon, Icons.cloud_off_rounded);
    expect(atomLoadError(const ProductNotFound(7)).title, 'This product is not available');
    expect(atomMessage(Exception('Network Error: Failed host lookup')), startsWith('You seem to be offline.'));
  });
}
