import 'package:flutter/foundation.dart';

class AuthController {
  static final ValueNotifier<Map<String, dynamic>?> currentUser =
      ValueNotifier<Map<String, dynamic>?>(null);
  static final ValueNotifier<String?> accessToken = ValueNotifier<String?>(null);
  static bool skipNextSecurityUnlock = false;

  static bool get isLoggedIn => currentUser.value != null;

  static void login(Map<String, dynamic> user, {String? token}) {
    currentUser.value = user;
    accessToken.value = token;
    skipNextSecurityUnlock = true;
  }

  static void logout() {
    currentUser.value = null;
    accessToken.value = null;
    skipNextSecurityUnlock = false;
  }
}
