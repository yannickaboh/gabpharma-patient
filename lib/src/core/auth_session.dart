import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

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
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _accessTokenKey = 'gabpharma_access_token';
  static const _refreshTokenKey = 'gabpharma_refresh_token';

  final ApiClient api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthUser? currentUser;

  Future<bool> restoreSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) return false;

    api.accessToken = accessToken;
    try {
      currentUser = await me();
      return currentUser?.role == 'patient' && currentUser?.status == 'active';
    } on ApiException {
      await clear();
      return false;
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
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
}
