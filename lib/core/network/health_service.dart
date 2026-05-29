import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class HealthService {
  Future<String> check() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Backend not reachable');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['status'] ?? 'unknown').toString();
    } on Exception {
      return 'offline';
    }
  }
}
