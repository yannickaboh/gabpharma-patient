import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Verrou biométrique purement local (Face ID / Touch ID / empreinte) : ne
/// protège que l'accès à la session déjà stockée sur l'appareil
/// (`flutter_secure_storage`), aucune donnée biométrique ni "appareil de
/// confiance" côté backend. Version minimale volontairement choisie plutôt
/// qu'un vrai second facteur lié au compte (voir propositions_backend.md §6).
class BiometricLockService {
  BiometricLockService._();

  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'biometric_lock_enabled';
  static final _localAuth = LocalAuthentication();

  /// `true` si le patient a activé le verrou dans Sécurité — n'implique pas
  /// que l'appareil supporte encore la biométrie (voir [isDeviceSupported]).
  static Future<bool> isEnabled() async =>
      (await _storage.read(key: _enabledKey)) == '1';

  static Future<void> setEnabled(bool value) async {
    await _storage.write(key: _enabledKey, value: value ? '1' : '0');
  }

  /// Ne lève jamais d'exception : renvoie `false` si le plugin échoue à
  /// interroger le matériel (repli honnête, cohérent avec la position).
  static Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } on Object {
      return false;
    }
  }

  /// Déclenche l'invite biométrique native. Renvoie `false` sur échec,
  /// annulation ou absence de capteur — ne lève jamais d'exception pour que
  /// l'appelant puisse toujours décider d'un repli (réessayer, ou laisser
  /// passer si la biométrie n'est plus disponible sur l'appareil).
  static Future<bool> authenticate(String reason) async {
    try {
      if (!await isDeviceSupported()) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on Object {
      return false;
    }
  }
}
