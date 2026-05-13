import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Central HTTP client for all backend API calls.
///
/// Usage:
///   final api = ApiService();
///   final data = await api.get('/courses');
///   final result = await api.post('/auth/login', body: {...});
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _accessToken;
  String? _refreshToken;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}/api$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = queryParams != null
        ? _uri(path).replace(queryParameters: queryParams)
        : _uri(path);
    final response = await http
        .get(uri, headers: _headers)
        .timeout(ApiConfig.receiveTimeout);
    return _handle(response);
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.receiveTimeout);
    return _handle(response);
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.receiveTimeout);
    return _handle(response);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _headers)
        .timeout(ApiConfig.receiveTimeout);
    return _handle(response);
  }

  // ── Direct S3 Upload (presigned PUT) ─────────────────────────────────────
  /// First call POST /upload/presigned → get uploadUrl + publicUrl
  /// Then call this to PUT the file bytes directly to S3
  Future<void> uploadToS3({
    required String presignedUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {'Content-Type': mimeType},
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw ApiException('S3 upload failed: ${response.statusCode}', response.statusCode);
    }
  }

  // ── Token Refresh ─────────────────────────────────────────────────────────
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) throw ApiException('Not authenticated', 401);
    final response = await http.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    final data = _handle(response);
    _accessToken = data['data']['accessToken'];
  }

  // ── Response Handler ──────────────────────────────────────────────────────
  Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid server response', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Request failed';
    throw ApiException(message, response.statusCode);
  }
}

// ── Auth Helper Methods ────────────────────────────────────────────────────────

extension AuthApi on ApiService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await post('/auth/login', body: {'email': email, 'password': password});
    final data = result['data'] as Map<String, dynamic>;
    setTokens(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    return data;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String? grade,
  }) async {
    final result = await post('/auth/signup',
        body: {'name': name, 'email': email, 'password': password, 'grade': grade});
    final data = result['data'] as Map<String, dynamic>;
    setTokens(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    return data;
  }

  Future<void> sendOtp(String email) =>
      post('/auth/otp/send', body: {'email': email});

  Future<void> verifyOtp(String email, String otp) =>
      post('/auth/otp/verify', body: {'email': email, 'otp': otp});

  Future<void> logout() async {
    await post('/auth/logout', body: {'refreshToken': _refreshToken});
    clearTokens();
  }
}

// ── Typed Exception ───────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
