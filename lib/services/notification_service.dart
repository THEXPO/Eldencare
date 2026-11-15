import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;

  /// Initializes FCM listeners, permissions, and token retrieval.
  Future<void> initialize({
    Function(RemoteMessage message)? onForegroundMessage,
    Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    if (_initialized) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (Android 13+ / iOS / Web)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // 2. Retrieve FCM Device Registration Token
      try {
        if (kIsWeb) {
          const vapidKey =
              String.fromEnvironment('FIREBASE_VAPID_KEY', defaultValue: '');
          _currentToken = await _messaging!.getToken(
            vapidKey: vapidKey.isNotEmpty ? vapidKey : null,
          );
        } else {
          _currentToken = await _messaging!.getToken();
        }
      } catch (tokenErr) {
        debugPrint('FCM token retrieval note (web/platform): $tokenErr');
      }

      if (_currentToken != null) {
        debugPrint('FCM Registration Token: $_currentToken');
        await _saveTokenLocally(_currentToken!);
      }

      // 3. Listen to token refresh events
      _messaging!.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _saveTokenLocally(newToken);
      });

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground Push Received: ${message.notification?.title}');
        onForegroundMessage?.call(message);
      });

      // 5. App opened from background / system tray notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification Opened App: ${message.notification?.title}');
        onNotificationOpened?.call(message);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization note: $e');
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('eldencare_fcm_token', token);
    } catch (_) {}
  }

  /// Deactivates FCM token on account logout
  Future<void> clearOnLogout() async {
    try {
      if (_messaging != null) {
        await _messaging!.deleteToken();
      }
      _currentToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('eldencare_fcm_token');
    } catch (e) {
      debugPrint('Error clearing FCM token on logout: $e');
    }
  }
}
