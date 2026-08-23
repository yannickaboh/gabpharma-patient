import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'app_config.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
  });

  final int id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;
  final String status;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final combined =
        '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
            .toUpperCase();
    if (combined.isNotEmpty) return combined;
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
}

class AuthChallenge {
  const AuthChallenge({
    required this.id,
    required this.method,
    required this.expiresIn,
    required this.canResend,
    this.user,
  });

  final String id;
  final String method;
  final int expiresIn;
  final bool canResend;
  final AuthUser? user;

  bool get isEmail => method == 'email';

  factory AuthChallenge.fromJson(
    Map<String, dynamic> json, {
    AuthUser? user,
  }) =>
      AuthChallenge(
        id: json['id']?.toString() ?? '',
        method: json['method']?.toString() ?? 'email',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 300,
        canResend: json['can_resend'] == true,
        user: user,
      );

  AuthChallenge copyWith({AuthUser? user}) => AuthChallenge(
        id: id,
        method: method,
        expiresIn: expiresIn,
        canResend: canResend,
        user: user ?? this.user,
      );
}

class AuthSession {
  AuthSession._() {
    api.onUnauthorized = _handleUnauthorized;
  }

  static final AuthSession instance = AuthSession._();

  static const _accessTokenKey = 'gabpharma_access_token';
  static const _refreshTokenKey = 'gabpharma_refresh_token';

  final ApiClient api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthUser? currentUser;

  // Le token d'accès n'a pas de rafraîchissement automatique côté API pour
  // l'instant (pas d'endpoint /mobile/auth/refresh/) : il expire au bout de
  // 20 min et toute requête échoue alors en 401. On détecte ça ici pour
  // renvoyer proprement au login plutôt que de laisser chaque écran afficher
  // une erreur générique qui ne se résoudra jamais toute seule.
  bool _handlingUnauthorized = false;
  // Pendant restoreSession(), un 401 sur /me/ est un cas normal (token
  // périmé depuis la dernière ouverture) déjà géré par son propre
  // catch — on évite que _handleUnauthorized navigue en double par-dessus.
  bool _restoring = false;

  void _handleUnauthorized() {
    if (_handlingUnauthorized || _restoring) return;
    _handlingUnauthorized = true;
    clear();
    AppConfig.navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<bool> restoreSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) return false;

    api.accessToken = accessToken;
    _restoring = true;
    try {
      currentUser = await me();
      _handlingUnauthorized = false;
      return currentUser?.role == 'patient' && currentUser?.status == 'active';
    } on ApiException {
      await clear();
      return false;
    } finally {
      _restoring = false;
    }
  }

  Future<AuthChallenge> login({
    required String identifier,
    required String password,
  }) async {
    final response = await api.postJson('mobile/auth/login/', {
      'identifier': identifier,
      'password': password,
      'app': 'patient',
    });
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    final challenge = AuthChallenge.fromJson(
      Map<String, dynamic>.from(response['challenge'] as Map),
      user: user,
    );
    return challenge;
  }

  Future<AuthUser> verifyTwoFactor({
    required AuthChallenge challenge,
    required String code,
  }) async {
    final response = await api.postJson('mobile/auth/verify-2fa/', {
      'challenge_id': challenge.id,
      'method': challenge.method,
      'code': code,
    });
    await _storeTokens(response);
    currentUser = AuthUser.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    return currentUser!;
  }

  Future<AuthChallenge> resendTwoFactor(AuthChallenge challenge) async {
    final response = await api.postJson('mobile/auth/resend-2fa/', {
      'challenge_id': challenge.id,
    });
    return AuthChallenge.fromJson(
      Map<String, dynamic>.from(response['challenge'] as Map),
      user: challenge.user,
    );
  }

  Future<AuthChallenge> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required bool termsAccepted,
  }) async {
    final response = await api.postJson('mobile/auth/register/', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'terms_accepted': termsAccepted,
    });
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    return AuthChallenge.fromJson(
      Map<String, dynamic>.from(response['challenge'] as Map),
      user: user,
    );
  }

  Future<AuthUser> verifyRegistration({
    required String challengeId,
    required String code,
  }) async {
    final response = await api.postJson('mobile/auth/register/verify/', {
      'challenge_id': challengeId,
      'code': code,
    });
    await _storeTokens(response);
    currentUser = AuthUser.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    return currentUser!;
  }

  Future<AuthChallenge> requestPasswordReset(String identifier) async {
    final response = await api.postJson('mobile/auth/password-reset/', {
      'identifier': identifier,
    });
    return AuthChallenge.fromJson(
      Map<String, dynamic>.from(response['challenge'] as Map),
    );
  }

  Future<String> verifyPasswordReset({
    required String challengeId,
    required String code,
  }) async {
    final response = await api.postJson('mobile/auth/password-reset/verify/', {
      'challenge_id': challengeId,
      'code': code,
    });
    final resetToken = response['reset_token']?.toString();
    if (resetToken == null || resetToken.isEmpty) {
      throw const ApiException('La réponse de vérification est incomplète.');
    }
    return resetToken;
  }

  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword1,
    required String newPassword2,
  }) async {
    await api.postJson('mobile/auth/password-reset/confirm/', {
      'reset_token': resetToken,
      'new_password1': newPassword1,
      'new_password2': newPassword2,
    });
  }

  Future<AuthUser> me() async {
    final response = await api.getJson('mobile/auth/me/');
    return AuthUser.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
  }

  Future<void> clear() async {
    api.accessToken = null;
    currentUser = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> _storeTokens(Map<String, dynamic> response) async {
    final accessToken = response['access']?.toString();
    final refreshToken = response['refresh']?.toString();
    if (accessToken == null || refreshToken == null) {
      throw const ApiException('La réponse de connexion est incomplète.');
    }
    api.accessToken = accessToken;
    _handlingUnauthorized = false;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
}
