import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

/// Mengelola inisialisasi Firebase Cloud Messaging (FCM), registrasi token perangkat,
/// dan tampilan notifikasi lokal saat aplikasi berjalan di foreground.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastRegisteredToken;
  VoidCallback? onNotificationReceived;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dekorin_collaboration',
    'Kolaborasi & Agenda Dekorin',
    description: 'Notifikasi undangan kolaborasi antar vendor dan update agenda.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);
        await _localNotifications.initialize(initSettings);
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
        onNotificationReceived?.call();
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('FCM initialization skipped: $e');
    }
  }

  Future<void> syncDeviceTokenAfterLogin() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM token sync skipped: $e');
    }
  }

  Future<void> unregisterTokenOnLogout() async {
    final token = _lastRegisteredToken;
    if (token == null || token.isEmpty) return;
    try {
      await ApiClient.delete('/devices/token?token=${Uri.encodeQueryComponent(token)}');
    } catch (_) {}
    _lastRegisteredToken = null;
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.post(
        '/devices/token',
        body: {
          'token': token,
          'platform': kIsWeb ? 'web' : 'android',
        },
      );
      _lastRegisteredToken = token;
    } catch (e) {
      debugPrint('Failed registering FCM token to backend: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Dekorin',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
