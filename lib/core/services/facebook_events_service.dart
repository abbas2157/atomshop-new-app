import 'dart:convert';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Wraps the Meta SDK for app-events logging, used to attribute installs
/// and in-app conversions back to Facebook/Instagram ad campaigns.
class FacebookEventsService {
  FacebookEventsService._();

  static final FacebookAppEvents _events = FacebookAppEvents();

  /// ISO 4217 code for the only currency this app transacts in.
  ///
  /// Meta interprets every event value in the currency sent alongside it, so
  /// this must match what the UI displays (see `formatPKR`). Reporting PKR
  /// amounts as USD would overstate conversion value by the FX rate and corrupt
  /// ROAS and value-based bidding.
  static const String defaultCurrency = 'PKR';

  /// Meta's generic content family for everything in this catalogue.
  static const String _productContentType = 'product';

  static Future<void> initialize() async {
    // Each call is guarded independently: a failure in one (e.g. the
    // platform channel rejecting advertiser-ID collection) must not skip
    // the other, or attribution silently degrades with no signal.
    await _guard(
      'setAutoLogAppEventsEnabled',
      () => _events.setAutoLogAppEventsEnabled(true),
    );
    await _guard(
      'setAdvertiserIdCollectionEnabled',
      // Not activateApp(): the plugin docs say it's only needed when
      // auto-logging is disabled or deliberately deferred for consent,
      // which isn't the case here — calling both risks double-counting
      // the activation event.
      () async => _events.setAdvertiserIdCollectionEnabled(
        await _advertiserIdCollectionAllowed(),
      ),
    );
    debugPrint('[FacebookEvents] Initialized.');
  }

  /// On iOS, advertiser-ID (IDFA) collection is only legitimate once the
  /// user has granted the system App Tracking Transparency prompt — asking
  /// the SDK to collect it without ever showing that prompt (the previous
  /// state of this code) is an App Store review risk and silently yields no
  /// IDFA anyway on iOS 17+, which derives consent from ATT regardless of
  /// this setter.
  ///
  /// `trackingAuthorizationStatus`/`requestTrackingAuthorization` both
  /// resolve to [TrackingStatus.notSupported] on Android and other
  /// non-iOS platforms, which this treats as "allowed" — Android has no ATT
  /// gate; collection there is controlled solely by the AD_ID manifest
  /// permission.
  static Future<bool> _advertiserIdCollectionAllowed() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      final requested =
          await AppTrackingTransparency.requestTrackingAuthorization();
      return requested == TrackingStatus.authorized;
    }
    return status == TrackingStatus.authorized ||
        status == TrackingStatus.notSupported;
  }

  /// Runs [action], reporting but never rethrowing a failure.
  ///
  /// Analytics must not be able to break a user flow. Three distinct failures
  /// are possible here: `MissingPluginException` on the web/desktop targets this
  /// project ships (where the plugin has no implementation),
  /// `PlatformException` when the native SDK rejects a call, and `ArgumentError`
  /// for non-scalar parameter values — the last raised *synchronously* while the
  /// channel arguments are built. Invoking [action] inside the try block catches
  /// the synchronous case as well as the asynchronous ones.
  static Future<void> _guard(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('[FacebookEvents] $label failed: $e');
      debugPrint('[FacebookEvents] $st');
    }
  }

  static Future<void> logViewContent({
    required String contentId,
    String? contentName,
    double? price,
    String currency = defaultCurrency,
    String contentType = _productContentType,
  }) {
    return _guard(
      'logViewContent',
      () => _events.logViewContent(
        id: contentId,
        type: contentType,
        currency: currency,
        price: price,
        parameters: {
          // Meta expects fb_content as a JSON-encoded *array* of item objects.
          // The plugin's `content:` argument encodes a bare object instead, so
          // the array is built here and passed through `parameters`.
          FacebookAppEvents.paramNameContent: jsonEncode([
            <String, dynamic>{
              'id': contentId,
              'quantity': 1,
              'item_name': ?contentName,
              'item_price': ?price,
            },
          ]),
        },
      ),
    );
  }

  static Future<void> logAddToCart({
    required String contentId,
    required double price,
    String currency = defaultCurrency,
  }) {
    return _guard(
      'logAddToCart',
      () => _events.logAddToCart(
        id: contentId,
        type: _productContentType,
        price: price,
        currency: currency,
      ),
    );
  }

  static Future<void> logInitiatedCheckout({
    required double totalPrice,
    String currency = defaultCurrency,
    int? numItems,
  }) {
    return _guard(
      'logInitiatedCheckout',
      () => _events.logInitiatedCheckout(
        totalPrice: totalPrice,
        currency: currency,
        // Passed through as-is: the plugin omits fb_num_items when null, which
        // is correct. Coercing null to 0 would report an empty basket.
        numItems: numItems,
      ),
    );
  }

  static Future<void> logPurchase({
    required double amount,
    String currency = defaultCurrency,
    Map<String, dynamic>? parameters,
  }) {
    return _guard(
      'logPurchase',
      () => _events.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters,
      ),
    );
  }

  /// Log this once, at the point the user's account actually becomes usable
  /// (i.e. after email/OTP verification, not at the signup form submit) —
  /// see the call site for why.
  static Future<void> logCompletedRegistration({String? registrationMethod}) {
    return _guard(
      'logCompletedRegistration',
      () => _events.logCompletedRegistration(
        registrationMethod: registrationMethod,
      ),
    );
  }

  /// Advanced matching: associates this device's future events with a stable
  /// user id, improving Meta's ability to match events to a real person
  /// (and therefore match rates for ad optimisation) beyond device signals
  /// alone. Call on login/signup once the user id is known.
  static Future<void> setUserId(String id) {
    return _guard('setUserId', () => _events.setUserID(id));
  }

  /// Advanced matching via hashed PII — the plugin hashes these before they
  /// leave the device. Only pass fields you actually have; omitted fields
  /// keep whatever was set before (plugin's merge semantics), so this is
  /// safe to call with partial data.
  static Future<void> setUserData({
    String? email,
    String? phone,
    String? externalId,
  }) {
    return _guard(
      'setUserData',
      () => _events.setUserData(
        email: email,
        phone: phone,
        externalId: externalId,
      ),
    );
  }

  /// Clears advanced-matching identity set via [setUserId]/[setUserData].
  /// Call on logout — otherwise the next person to use this device/session
  /// keeps inheriting the previous user's identity on their events.
  static Future<void> clearUser() {
    return _guard('clearUser', () async {
      await _events.clearUserID();
      await _events.clearUserData();
    });
  }

  /// Gives Meta's SDK this device's push token so it can attribute app opens
  /// driven by Facebook/Instagram push campaigns and measure push delivery —
  /// separate from this app's own FCM backend sync (`FcmService`), which
  /// this does not replace or interact with.
  static Future<void> setPushNotificationsDeviceToken(String token) {
    return _guard(
      'setPushNotificationsDeviceToken',
      () => _events.setPushNotificationsDeviceToken(token),
    );
  }
}
