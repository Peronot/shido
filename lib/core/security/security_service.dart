import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _notifEnabledKey = 'notifications_enabled';

  static Future<void> setNotificationsEnabled(bool value) async {
    await _storage.write(key: _notifEnabledKey, value: value ? '1' : '0');
  }

  static Future<bool> getNotificationsEnabled() async {
    final raw = await _storage.read(key: _notifEnabledKey);
    return raw != '0';
  }
}
