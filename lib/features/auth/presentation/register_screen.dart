import 'package:flutter/material.dart';

import '../../../core/auth/social_auth.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  String? _error;
  final _api = ResourceApi();

  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
  final _digitRegex = RegExp(r'\D');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validateForm() {
    final fullName = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    final phone = _phone.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPassword.text;

    if (fullName.length < 3) {
      return 'Full name must be at least 3 characters.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number (9-15 digits).';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _normalizePhone(String input) {
    return input.replaceAll(_digitRegex, '');
  }

  String _cleanError(dynamic e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _register() async {
    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _error = validationError);
      AppAlerts.warning(
        context,
        title: 'Validation Error',
        text: validationError,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    AppAlerts.loading(
      context,
      title: 'Loading',
      text: 'Creating your account...',
    );
    debugPrint('[AUTH][REGISTER] Attempt started');

    try {
      final email = _email.text.trim().toLowerCase();
      final phone = _normalizePhone(_phone.text.trim());
      await _api.register(
        fullName: _name.text.trim(),
        email: email,
        phone: phone,
        password: _password.text,
      );
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Account created successfully. Please login now.',
      );
      debugPrint('[AUTH][REGISTER] Success');
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      var message = _cleanError(e);
      final lower = message.toLowerCase();
      if (lower.contains('already exists') ||
          lower.contains('duplicate key') ||
          lower.contains('users_email_key')) {
        message = 'Email already registered. Please login instead.';
      }

      setState(() => _error = message);
      if (mounted) {
        AppAlerts.error(context, title: 'Register Failed', text: message);
      }
      debugPrint('[AUTH][REGISTER] Error: $message');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
              ),
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
              ),
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
              ),
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
              ),
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.verified_user_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
              ),
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  SocialAuth.loginWithGoogle(context).then((ok) {
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: scheme.primary),
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata_rounded, size: 26),
                    SizedBox(width: 8),
                    Text('Continue with Google'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  SocialAuth.loginWithFacebook(context).then((ok) {
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: scheme.primary),
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.facebook_rounded),
                    SizedBox(width: 8),
                    Text('Continue with Facebook'),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
