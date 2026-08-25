import 'package:geolocator/geolocator.dart';

/// Position patient, mise en cache en mémoire pour la durée de la session
/// (évite de redemander/re-géolocaliser à chaque écran). Repli honnête sur
/// `null` si permission refusée, service désactivé ou position indisponible
/// — les écrans doivent alors se comporter comme si aucune position n'était
/// fournie (pas de distance affichée, tri par nom), exactement comme le fait
/// déjà l'API côté serveur quand `lat`/`lng` sont absents.
class PatientLocationService {
  PatientLocationService._();

  static (double, double)? _cached;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  static (double, double)? get cachedPosition => _cached;

  /// Tente d'obtenir la position patient. Ne lève jamais d'exception : toute
  /// erreur (permission refusée, GPS coupé, timeout) renvoie `null`.
  static Future<(double, double)?> currentPosition({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cached;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _cached = (position.latitude, position.longitude);
      _cachedAt = DateTime.now();
      return _cached;
    } on Object {
      return null;
    }
  }
}

/// Formate une distance en km renvoyée par l'API ("850 m" sous 1 km,
/// "1,2 km" au-delà) — même convention d'affichage que le mockup d'origine.
String formatDistanceKm(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m';
  }
  return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
}
