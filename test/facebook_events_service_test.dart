import 'dart:convert';

import 'package:atompro/core/services/facebook_events_service.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [FacebookEventsService].
///
/// These intercept the plugin's MethodChannel and assert the exact payload that
/// would reach Meta's native SDK. Tests still marked BUG pin known-incorrect
/// behaviour that has not been fixed yet, so a later fix will visibly flip them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(channelName);
  final calls = <MethodCall>[];
  Object? Function(MethodCall call)? responder;

  setUp(() {
    calls.clear();
    responder = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final r = responder;
      if (r != null) return r(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Map<Object?, Object?> paramsOf(MethodCall call) =>
      (call.arguments as Map)['parameters'] as Map<Object?, Object?>;

  group('initialize', () {
    test('calls the two setup methods in order, not the deprecated setter '
        'or activateApp', () async {
      await FacebookEventsService.initialize();

      // setAdvertiserTracking is deprecated (superseded by
      // setAdvertiserIdCollectionEnabled) and activateApp is redundant once
      // auto-logging is on, per the plugin's own docs.
      expect(
        calls.map((c) => c.method),
        ['setAutoLogAppEventsEnabled', 'setAdvertiserIdCollectionEnabled'],
      );
      expect(calls[0].arguments, isTrue);
      expect(calls[1].arguments, isTrue);
    });

    test('enables auto-logging with no consent gate (GDPR risk)', () async {
      await FacebookEventsService.initialize();

      // Auto-logging is switched on unconditionally at startup: there is no
      // consent parameter and no call to setDataProcessingOptions /
      // setLimitEventAndDataUsage anywhere in the service.
      expect(calls.first.method, 'setAutoLogAppEventsEnabled');
      expect(calls.first.arguments, isTrue);
      expect(
        calls.map((c) => c.method),
        isNot(contains('setDataProcessingOptions')),
      );
    });

    test('swallows platform failures instead of throwing', () async {
      responder = (_) => throw PlatformException(code: 'boom');

      // Must not throw: startup should survive SDK failure.
      await expectLater(FacebookEventsService.initialize(), completes);
    });

    test('a failing call no longer skips the remaining setup', () async {
      responder = (call) {
        if (call.method == 'setAutoLogAppEventsEnabled') {
          throw PlatformException(code: 'boom');
        }
        return null;
      };

      await FacebookEventsService.initialize();

      // Each call is guarded independently, so a failure in the first still
      // lets the second run instead of leaving attribution silently dead.
      expect(
        calls.map((c) => c.method),
        ['setAutoLogAppEventsEnabled', 'setAdvertiserIdCollectionEnabled'],
      );
    });
  });

  group('logViewContent', () {
    test('sends fb_content as a JSON-encoded array of items', () async {
      await FacebookEventsService.logViewContent(
        contentId: 'SKU-1',
        contentName: 'Air Cooler',
        price: 42.0,
      );

      final raw = paramsOf(calls.single)['fb_content'] as String;
      final decoded = jsonDecode(raw) as List;

      expect(decoded, hasLength(1));
      expect(
        decoded.single,
        allOf(
          containsPair('id', 'SKU-1'),
          containsPair('quantity', 1),
          containsPair('item_name', 'Air Cooler'),
          containsPair('item_price', 42.0),
        ),
      );
    });

    test('sends fb_content_type', () async {
      await FacebookEventsService.logViewContent(contentId: 'SKU-1');

      expect(paramsOf(calls.single)['fb_content_type'], 'product');
    });

    test('keeps currency even when price is null', () async {
      await FacebookEventsService.logViewContent(contentId: 'SKU-1');

      expect(paramsOf(calls.single)['fb_currency'],
          FacebookEventsService.defaultCurrency);
    });

    test('uses the correct standard event name and content id', () async {
      await FacebookEventsService.logViewContent(contentId: 'SKU-1');

      expect(calls.single.method, 'logEvent');
      expect((calls.single.arguments as Map)['name'],
          FacebookAppEvents.eventNameViewedContent);
      expect(paramsOf(calls.single)['fb_content_id'], 'SKU-1');
    });
  });

  group('logAddToCart', () {
    test('sends id, type, currency and value correctly', () async {
      await FacebookEventsService.logAddToCart(
        contentId: 'SKU-9',
        price: 1500.0,
        currency: 'PKR',
      );

      final args = calls.single.arguments as Map;
      expect(args['name'], FacebookAppEvents.eventNameAddedToCart);
      expect(args['_valueToSum'], 1500.0);
      final p = paramsOf(calls.single);
      expect(p['fb_content_id'], 'SKU-9');
      expect(p['fb_content_type'], 'product');
      expect(p['fb_currency'], 'PKR');
    });
  });

  group('logInitiatedCheckout', () {
    test('omits fb_num_items when the caller omits it', () async {
      await FacebookEventsService.logInitiatedCheckout(totalPrice: 999.0);

      // Sending 0 would tell Meta the basket was empty; omitting the parameter
      // is what the plugin does and what Meta expects.
      expect(paramsOf(calls.single).containsKey('fb_num_items'), isFalse);
    });

    test('passes numItems through when supplied', () async {
      await FacebookEventsService.logInitiatedCheckout(
        totalPrice: 999.0,
        numItems: 3,
      );

      expect(paramsOf(calls.single)['fb_num_items'], 3);
    });
  });

  group('currency defaults', () {
    test('defaults to PKR, matching the currency the app displays', () async {
      expect(FacebookEventsService.defaultCurrency, 'PKR');

      await FacebookEventsService.logPurchase(amount: 5000.0);
      await FacebookEventsService.logAddToCart(
        contentId: 'SKU-2',
        price: 5000.0,
      );
      await FacebookEventsService.logInitiatedCheckout(totalPrice: 5000.0);
      await FacebookEventsService.logViewContent(contentId: 'SKU-2');

      expect((calls[0].arguments as Map)['currency'], 'PKR');
      expect(paramsOf(calls[1])['fb_currency'], 'PKR');
      expect(paramsOf(calls[2])['fb_currency'], 'PKR');
      expect(paramsOf(calls[3])['fb_currency'], 'PKR');
    });
  });

  group('error handling on log methods', () {
    test('platform errors are swallowed, not propagated to the caller',
        () async {
      responder = (_) => throw PlatformException(code: 'boom');

      // Analytics must never break the flow that logged the event.
      await expectLater(FacebookEventsService.logPurchase(amount: 1.0),
          completes);
      expect(calls, hasLength(1), reason: 'the call was still attempted');
    });

    test('MissingPluginException is swallowed on unsupported platforms',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      // The project ships web/windows/linux/macos targets where this plugin has
      // no implementation.
      await expectLater(
        FacebookEventsService.logAddToCart(contentId: 'x', price: 1.0),
        completes,
      );
    });

    test('non-scalar parameters are swallowed rather than thrown', () async {
      // The plugin raises ArgumentError synchronously while building the channel
      // arguments, so the guard has to wrap the call itself, not just await it.
      await expectLater(
        FacebookEventsService.logPurchase(
          amount: 1.0,
          parameters: {
            'items': ['a', 'b'],
          },
        ),
        completes,
      );
      expect(calls, isEmpty, reason: 'it never reached the channel');
    });
  });
}
