import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_controller.dart';
import 'api_config.dart';

class ResourceApi {
  Map<String, String> _authHeaders({bool withJson = false}) {
    final token = AuthController.accessToken.value;
    final headers = <String, String>{};
    if (withJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (decoded['error'] ?? decoded['message'] ?? '')
          .toString()
          .trim();
      if (message.isNotEmpty) {
        return message;
      }
    } catch (_) {}
    return fallback;
  }

  Future<List<Map<String, dynamic>>> list(
    String resource, {
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/resources/$resource?limit=$limit');
      final response = await http
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(
            response,
            'Request failed (${response.statusCode}) for $resource',
          ),
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (decoded['data'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return data;
    } on FormatException {
      throw Exception('Invalid response format from server for $resource');
    } on Exception catch (e) {
      throw Exception(
        'Server connection failed. Hubi backend inuu socdo, kadib isku day mar kale. ($e)',
      );
    }
  }

  Future<Map<String, dynamic>> create(
    String resource,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/resources/$resource');
    final response = await http
        .post(
          uri,
          headers: _authHeaders(withJson: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Create failed (${response.statusCode}) for $resource',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> getById(String resource, String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/resources/$resource/$id');
    final response = await http
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Fetch failed (${response.statusCode}) for $resource/$id',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> update(
    String resource,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/resources/$resource/$id');
    final response = await http
        .put(
          uri,
          headers: _authHeaders(withJson: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Update failed (${response.statusCode}) for $resource',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<void> remove(String resource, String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/resources/$resource/$id');
    final response = await http
        .delete(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Delete failed (${response.statusCode}) for $resource',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'phone': phone,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Register failed (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> login({
    required String loginInput,
    required String password,
  }) async {
    final isEmail = loginInput.contains('@');
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final payload = <String, dynamic>{'password': password};
    if (isEmail) {
      payload['email'] = loginInput;
    } else {
      payload['phone'] = loginInput;
    }

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, 'Login failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String fullName,
    required String provider,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/social-login');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'full_name': fullName.trim(),
            'provider': provider,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Social login failed (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/change-password');
    final response = await http
        .post(
          uri,
          headers: _authHeaders(withJson: true),
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Change password failed (${response.statusCode})',
        ),
      );
    }
  }
}
