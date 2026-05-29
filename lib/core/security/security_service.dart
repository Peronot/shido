import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_pin_code';
  static const _bioEnabledKey = 'biometric_enabled';
  static const _notifEnabledKey = 'notifications_enabled';

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<bool> verifyPin(String pin) async {
    final saved = await _storage.read(key: _pinKey);
    return saved != null && saved == pin;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(key: _bioEnabledKey, value: value ? '1' : '0');
  }

  static Future<bool> getBiometricEnabled() async {
    final raw = await _storage.read(key: _bioEnabledKey);
    return raw == '1';
  }

  static Future<bool> canUseBiometric() async {
    if (kIsWeb) return false;
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final supported = await auth.isDeviceSupported();
    return canCheck || supported;
  }

  static Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    final auth = LocalAuthentication();
    final canUse = await canUseBiometric();
    if (!canUse) return false;
    return auth.authenticate(
      localizedReason: 'Please verify your identity to open Shido App',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _storage.write(key: _notifEnabledKey, value: value ? '1' : '0');
  }

  static Future<bool> getNotificationsEnabled() async {
    final raw = await _storage.read(key: _notifEnabledKey);
    return raw != '0';
  }
}
