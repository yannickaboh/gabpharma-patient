import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'auth_session.dart';
import 'patient_catalog.dart' show registerDevice, unregisterDevice;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_supportsFirebaseMessaging) return;
  await _ensureFirebaseInitialized();
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  const PushNotificationService._();

  // Dernier token FCM connu localement, gardé pour pouvoir (dé)senregistrer
  // l'appareil sans re-demander à Firebase (utile notamment à la
  // déconnexion, où on veut le dernier token envoyé au backend).
  static String? _lastToken;

  /// Câblé depuis main.dart (pas depuis ce fichier core/, qui ne connaît
  /// pas les écrans) : reçoit le `data` d'un message FCM tapé par
  /// l'utilisateur pour naviguer vers le bon écran.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

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
    _lastToken = token;
    debugPrint('FCM token: $token');
    // Au démarrage de l'app, la session n'est pas forcément restaurée
    // (SplashScreen appelle restoreSession() après initialize()) —
    // _registerIfLoggedIn est un no-op silencieux si personne n'est encore
    // connecté ; AuthSession appelle registerCurrentDevice() une fois la
    // session restaurée/la connexion effectuée pour rattraper ce cas.
    if (token != null) await _registerIfLoggedIn(token);

    messaging.onTokenRefresh.listen((refreshedToken) {
      debugPrint('FCM token refreshed: $refreshedToken');
      _lastToken = refreshedToken;
      _registerIfLoggedIn(refreshedToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _registerIfLoggedIn(String token) async {
    if (AuthSession.instance.currentUser == null) return;
    try {
      await registerDevice(pushToken: token, platform: 'android');
    } on Object catch (error) {
      debugPrint('FCM device registration failed: $error');
    }
  }

  /// À appeler juste après une connexion réussie ou une restauration de
  /// session : le token FCM est déjà récupéré localement depuis
  /// [initialize] mais n'a pas pu être envoyé au backend tant que
  /// personne n'était authentifié.
  static Future<void> registerCurrentDevice() async {
    final token = _lastToken;
    if (token != null) await _registerIfLoggedIn(token);
  }

  /// À appeler à la déconnexion, avant que le token d'accès ne soit effacé.
  static Future<void> unregisterCurrentDevice() async {
    final token = _lastToken;
    if (token == null) return;
    try {
      await unregisterDevice(pushToken: token);
    } on Object catch (error) {
      debugPrint('FCM device unregistration failed: $error');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    onNotificationTap?.call(message.data);
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
