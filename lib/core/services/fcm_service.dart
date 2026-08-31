import 'dart:async';
import 'dart:convert';

import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/auth/seller_session_manager.dart';
import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/network/network_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/services/facebook_events_service.dart';
import 'package:atompro/firebase_options.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Receives messages while the app is backgrounded or terminated.
///
/// Must be a top-level (or static) function annotated with
/// `@pragma('vm:entry-point')`: the platform may invoke it in a fresh
/// background isolate that never ran `main()`, so Firebase needs to be
/// (re)initialized before anything else can touch it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('[FCM] Background message received — id: ${message.messageId}');
  debugPrint(
    '[FCM] Background notification — title: ${message.notification?.title}, '
    'body: ${message.notification?.body}',
  );
  debugPrint('[FCM] Background data payload: ${message.data}');
}

class FcmService {
  FcmService._();

  static final _network = NetworkManager.create();
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  static const _keyFcmToken = 'fcm_token';
  static StreamSubscription<String>? _refreshSubscription;
  static bool _listenersAttached = false;

  /// Android requires a registered channel before any notification can be
  /// shown on it (Android 8+). One "important updates" channel covers every
  /// push this app sends — orders, leads, dues, account activity.
  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important updates',
    description: 'Order, lead, dues and account notifications.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (!_isSupportedPlatform) return;

    await _requestPermission();
    await _initLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _attachMessageListeners();

    final token = await _fetchTokenWithRetry();
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _keyFcmToken, value: token);
      await syncToken(token);
      // Lets Meta attribute app opens driven by its own push campaigns —
      // independent of, and in addition to, the sync above.
      FacebookEventsService.setPushNotificationsDeviceToken(token);
    } else {
      debugPrint('[FCM] No token obtained — skipping initial sync.');
    }

    await _refreshSubscription?.cancel();
    _refreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed: $newToken');
      await _storage.write(key: _keyFcmToken, value: newToken);
      await syncToken(newToken);
      FacebookEventsService.setPushNotificationsDeviceToken(newToken);
    });
  }

  /// `getToken()` can transiently throw `SERVICE_NOT_AVAILABLE` — e.g. while
  /// a freshly created Firebase project finishes provisioning, or on a brief
  /// connectivity blip at cold start. Retry with backoff before giving up;
  /// `onTokenRefresh` will pick it up later regardless if every attempt fails.
  static Future<String?> _fetchTokenWithRetry({int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await _messaging.getToken();
        debugPrint('[FCM] Device token: $token');
        return token;
      } catch (e, st) {
        debugPrint(
          '[FCM] _messaging.getToken() threw on attempt $attempt/$maxAttempts: $e',
        );
        if (attempt == maxAttempts) {
          debugPrint('[FCM] $st');
          return null;
        }
        final delay = Duration(seconds: 2 * attempt);
        debugPrint('[FCM] Retrying getToken() in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    return null;
  }

  // ── Foreground display & tap-to-open ───────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('launcher_icon');
    // Permission is requested once via `_requestPermission()` (covers both
    // FCM and local alerts on iOS), so the plugin shouldn't prompt again.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // iOS stays silent for foreground pushes unless told otherwise.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _attachMessageListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // App is open: the OS won't surface a banner for us, so render one.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // App was backgrounded and the user tapped the system notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    // App was terminated and launched by tapping the notification.
    _messaging.getInitialMessage().then((message) {
      if (message != null) _openFromMessage(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    debugPrint('[FCM] Foreground message received — id: ${message.messageId}');
    debugPrint(
      '[FCM] Notification — title: ${notification?.title}, '
      'body: ${notification?.body}',
    );
    debugPrint('[FCM] Data payload: ${message.data}');
    if (notification == null) return;

    final body = notification.body;
    final imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;
    final bigPicture = imageUrl == null ? null : await _downloadBitmap(imageUrl);

    StyleInformation? styleInformation;
    if (bigPicture != null) {
      styleInformation = BigPictureStyleInformation(
        bigPicture,
        contentTitle: notification.title,
        summaryText: body,
        hideExpandedLargeIcon: true,
      );
    } else if (body != null && body.length > 40) {
      styleInformation = BigTextStyleInformation(body);
    }

    await _localNotifications.show(
      id: message.hashCode & 0x7fffffff,
      title: notification.title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: notification.android?.smallIcon ?? 'launcher_icon',
          largeIcon: const DrawableResourceAndroidBitmap('launcher_icon'),
          color: const Color(0xFFFFA500),
          styleInformation: styleInformation,
          groupKey: _androidChannel.id,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Downloads a remote image for the big-picture notification style.
  ///
  /// Best effort: a slow/failed fetch must not block the notification — the
  /// caller falls back to a plain text-style notification when this is null.
  static Future<AndroidBitmap<Object>?> _downloadBitmap(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return ByteArrayAndroidBitmap(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('[FCM] Failed to download notification image $url: $e');
      return null;
    }
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped — payload: ${response.payload}');
    _openNotificationsScreen();
  }

  static void _openFromMessage(RemoteMessage message) {
    final notification = message.notification;
    debugPrint(
      '[FCM] Notification opened app — title: ${notification?.title}, '
      'body: ${notification?.body}',
    );
    debugPrint('[FCM] Data payload: ${message.data}');
    _openNotificationsScreen();
  }

  /// Routes every tap to the in-app notifications list. The backend payload
  /// doesn't carry a typed deep-link target, so this is the one destination
  /// guaranteed to make sense for any push the app can receive.
  static void _openNotificationsScreen() {
    void attempt() {
      if (AppNavigator.navigatorKey.currentState != null) {
        AppNavigator.goToNotifications();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
      }
    }

    attempt();
  }

  static Future<String?> getToken() async {
    if (kIsWeb || !_isSupportedPlatform) return null;
    final existing = await _storage.read(key: _keyFcmToken);
    if (existing != null && existing.isNotEmpty) return existing;

    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] getToken() fetched fresh token: $token');
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _keyFcmToken, value: token);
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken() failed: $e');
      return null;
    }
  }

  static Future<void> syncToken([String? token]) async {
    final resolvedToken = token ?? await getToken();
    if (resolvedToken == null || resolvedToken.isEmpty) {
      debugPrint('[FCM] syncToken() — no token to sync, aborting.');
      return;
    }

    final sellerUserId = await SellerSessionManager.getUserId();
    if (sellerUserId != null && sellerUserId.isNotEmpty) {
      debugPrint('[FCM] syncToken() — routing as SELLER (userId=$sellerUserId) -> ${ApiEndpoints.fcmAttachUser}');
      await attachUser(userId: sellerUserId, fcmToken: resolvedToken);
      return;
    }

    final userId = await SessionManager.getUserId();
    if (userId != null && userId.isNotEmpty) {
      debugPrint('[FCM] syncToken() — routing as CUSTOMER (userId=$userId) -> ${ApiEndpoints.fcmAttachUser}');
      await attachUser(userId: userId, fcmToken: resolvedToken);
      return;
    }

    debugPrint('[FCM] syncToken() — no logged-in user, routing as GUEST -> ${ApiEndpoints.fcmStore}');
    await storeGuestToken(resolvedToken);
  }

  static Future<void> storeGuestToken(String fcmToken) async {
    await _safePost(ApiEndpoints.fcmStore, {
      'fcm_token': fcmToken,
      'device_type': _deviceType,
    });
  }

  static Future<void> attachUser({
    required String userId,
    String? fcmToken,
  }) async {
    final resolvedToken = fcmToken ?? await getToken();
    if (resolvedToken == null || resolvedToken.isEmpty || userId.isEmpty) {
      return;
    }
    await _safePost(ApiEndpoints.fcmAttachUser, {
      'user_id': userId,
      'fcm_token': resolvedToken,
    });
  }

  static Future<void> unlinkUser({String? userId, String? fcmToken}) async {
    final resolvedToken = fcmToken ?? await getToken();
    if (resolvedToken == null || resolvedToken.isEmpty) return;

    final resolvedUserId =
        userId ??
        await SellerSessionManager.getUserId() ??
        await SessionManager.getUserId();
    if (resolvedUserId == null || resolvedUserId.isEmpty) return;

    await _safePost(ApiEndpoints.fcmLogout, {
      'user_id': resolvedUserId,
      'fcm_token': resolvedToken,
    });
  }

  static Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      debugPrint(
        '[FCM] Permission request result: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('[FCM] Permission request threw: $e');
      // Permission prompts are platform-dependent; token sync remains best effort.
    }
  }

  static Future<void> _safePost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('[FCM] POST $endpoint -> $data');
      final response = await _network.postRequest(endpoint, data);
      debugPrint('[FCM] POST $endpoint <- $response');
    } catch (e) {
      debugPrint('[FCM] POST $endpoint threw: $e');
      // FCM sync must not block app launch, auth, or logout.
    }
  }

  static String get _deviceType {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'web';
  }

  static bool get _isSupportedPlatform {
    return Firebase.apps.isNotEmpty &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }
}
