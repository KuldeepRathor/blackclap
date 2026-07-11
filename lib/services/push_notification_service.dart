import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_url.dart';
import 'api_service.dart';

/// Global navigator key. Attached to every GoRouter created in main.dart so a
/// notification tap can navigate from outside the widget tree.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Single Android notification channel for all app notifications.
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'blackclap_default',
  'Notifications',
  description: 'Messages, likes, comments and follows',
  importance: Importance.high,
);

/// Top-level background message handler. FCM requires this to be a top-level or
/// static function annotated with @pragma('vm:entry-point') — it runs in its
/// own isolate when a data message arrives while the app is backgrounded or
/// terminated. We render it as a local notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.instance._showLocal(message.data);
}

/// Handles a tap on a locally-shown notification from a background isolate
/// (app was terminated). Must be top-level.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  PushNotificationService.instance._routeFromPayload(response.payload);
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  bool _initialized = false;
  bool _localReady = false;
  String? _currentToken;

  /// Set by ChatScreen while a conversation is open so we don't double-alert a
  /// message the user is already watching arrive over the WebSocket.
  String? activeConversationId;

  /// One-time setup: permission, local-notification channel, and FCM listeners.
  /// Safe to call once at startup (before login). Token registration happens
  /// separately in [registerToken] once the user is authenticated.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _ensureLocalReady();
    await _requestPermission();

    // Foreground messages: show locally unless the user is on that chat.
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      if (data['type'] == 'chat' &&
          data['conversation_id'] == activeConversationId) {
        return; // already visible via the live WebSocket update
      }
      _showLocal(data);
    });

    // Tap that brought the app from background → foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigate(_routeFromData(message.data));
    });

    // Cold start from a tap on a locally-shown notification (terminated app).
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _routeFromPayload(launch!.notificationResponse?.payload);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      _sendTokenToBackend(token);
    });
  }

  Future<void> _ensureLocalReady() async {
    if (_localReady) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _routeFromPayload(response.payload),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _localReady = true;
  }

  Future<void> _requestPermission() async {
    // iOS/Android 13+ runtime prompt. permission_handler covers Android 13+
    // POST_NOTIFICATIONS; FirebaseMessaging.requestPermission covers iOS.
    await FirebaseMessaging.instance.requestPermission();
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Fetch the FCM token and register it with the backend. Call after login.
  Future<void> registerToken() async {
    try {
      await initialize();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _currentToken = token;
      await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('Push: registerToken failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _api.post(AppUrl.registerDevice, {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
    } catch (e) {
      debugPrint('Push: token registration failed: $e');
    }
  }

  /// Unregister the current token on logout, then delete it locally so a new
  /// login on the same device gets a fresh token.
  Future<void> unregisterToken() async {
    final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null) {
      try {
        await _api.delete(AppUrl.unregisterDevice(token));
      } catch (e) {
        debugPrint('Push: token unregister failed: $e');
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  /// Render a data-only message as a local notification. Used by both the
  /// foreground listener and the background isolate handler.
  Future<void> _showLocal(Map<String, dynamic> data) async {
    await _ensureLocalReady();
    final title = (data['title'] ?? 'BlackClap').toString();
    final body = (data['body'] ?? '').toString();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    // Stable-ish id from the target so repeat notifications from the same
    // source collapse rather than stack endlessly.
    final id = (data['conversation_id'] ?? data['post_id'] ?? data['user_id'] ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000))
        .hashCode;
    await _local.show(id, title, body, details, payload: jsonEncode(data));
  }

  void _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
      _navigate(_routeFromData(data));
    } catch (_) {}
  }

  /// Map a notification's data block to an in-app route.
  String? _routeFromData(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'chat':
        final id = data['conversation_id'];
        return id != null ? '/chat/$id' : null;
      case 'follow':
        final username = data['username'];
        return username != null ? '/profile/$username' : '/home';
      case 'like':
      case 'comment':
        // No post-detail route exists yet; land on the feed. Revisit when a
        // /post/:id route is added.
        return '/home';
      default:
        return null;
    }
  }

  /// Navigate via the global navigator key, retrying briefly if the router is
  /// not mounted yet (e.g. cold start from a notification tap).
  void _navigate(String? route) {
    if (route == null) return;
    var attempts = 0;
    void tryNav() {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ctx.go(route);
      } else if (attempts++ < 20) {
        Future.delayed(const Duration(milliseconds: 200), tryNav);
      }
    }
    tryNav();
  }
}
