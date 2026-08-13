import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Wraps the Meta SDK for app-events logging, used to attribute installs
/// and in-app conversions back to Facebook/Instagram ad campaigns.
class FacebookEventsService {
  FacebookEventsService._();

  static final FacebookAppEvents _events = FacebookAppEvents();

  static Future<void> initialize() async {
    try {
      await _events.setAutoLogAppEventsEnabled(true);
      await _events.setAdvertiserTracking(enabled: true);
      await _events.activateApp();
      debugPrint('[FacebookEvents] Initialized.');
    } catch (e, st) {
      debugPrint('[FacebookEvents] Initialization threw: $e');
      debugPrint('[FacebookEvents] $st');
      // Ad-attribution setup is best effort and must not block app startup.
    }
  }

  static Future<void> logViewContent({
    required String contentId,
    String? contentName,
    double? price,
    String currency = 'USD',
  }) {
    return _events.logEvent(
      name: 'fb_mobile_content_view',
      parameters: {
        'fb_content_id': contentId,
        if (contentName != null) 'fb_content': contentName,
        if (price != null) 'fb_currency': currency,
      },
      valueToSum: price,
    );
  }

  static Future<void> logAddToCart({
    required String contentId,
    required double price,
    String currency = 'USD',
  }) {
    return _events.logAddToCart(
      id: contentId,
      type: 'product',
      price: price,
      currency: currency,
    );
  }

  static Future<void> logInitiatedCheckout({
    required double totalPrice,
    String currency = 'USD',
    int? numItems,
  }) {
    return _events.logInitiatedCheckout(
      totalPrice: totalPrice,
      currency: currency,
      numItems: numItems ?? 0,
    );
  }

  static Future<void> logPurchase({
    required double amount,
    String currency = 'USD',
    Map<String, dynamic>? parameters,
  }) {
    return _events.logPurchase(
      amount: amount,
      currency: currency,
      parameters: parameters,
    );
  }
}
