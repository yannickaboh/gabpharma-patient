import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_supportsFirebaseMessaging) return;
  await _ensureFirebaseInitialized();
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  const PushNotificationService._();

  static Future<void> initialize() async {
    if (!_supportsFirebaseMessaging) return;

    await _ensureFirebaseInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus.name}');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    debugPrint('FCM token: $token');

    messaging.onTokenRefresh.listen((refreshedToken) {
      debugPrint('FCM token refreshed: $refreshedToken');
      // TODO: Send this token to the Gab'Pharma API when the backend endpoint is ready.
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM notification opened: ${message.messageId}');
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial notification: ${initialMessage.messageId}');
    }
  }
}

bool get _supportsFirebaseMessaging =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
