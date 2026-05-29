import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:4000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }

    return 'http://localhost:4000/api';
  }
}
