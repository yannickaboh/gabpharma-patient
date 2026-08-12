import 'dart:convert';
import 'dart:io';

import 'app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  String? accessToken;

  Future<Map<String, dynamic>> getJson(String path) => _send('GET', path);

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(method, _uriFor(path));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (accessToken case final token?) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) request.write(jsonEncode(body));

    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              _firstValidationError(decoded) ??
              'Une erreur est survenue.'
          : 'Une erreur est survenue.';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  Uri _uriFor(String path) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl
        : '${AppConfig.apiBaseUrl}/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base$normalizedPath');
  }

  String? _firstValidationError(Map<String, dynamic> decoded) {
    for (final value in decoded.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        final nested = _firstValidationError(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  void close() => _httpClient.close(force: true);
}
