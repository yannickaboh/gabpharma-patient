// File generated from the Firebase Android app config.
// Re-run `flutterfire configure` when adding iOS, web, or another Firebase app.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions are only configured for Android. '
          'Run `flutterfire configure` to add this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIqdf4lyV6nU-cSNaCIZH2BMjDnb09n4o',
    appId: '1:175902119418:android:dcd0e611c89b505cd18043',
    messagingSenderId: '175902119418',
    projectId: 'gabpharma-fcm',
    storageBucket: 'gabpharma-fcm.firebasestorage.app',
  );
}
