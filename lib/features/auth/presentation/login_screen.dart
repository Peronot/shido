import 'package:flutter/material.dart';

import '../../../app/main_navigation.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/social_auth.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/async_state_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _api = ResourceApi();
  bool _loading = false;
  String? _error;
  final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _digitRegex = RegExp(r'\D');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    return input.replaceAll(_digitRegex, '');
  }

  String? _validateForm() {
    final loginInput = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final isEmail = loginInput.contains('@');

    if (loginInput.isEmpty) {
      return 'Please enter your email or phone number.';
    }
    if (isEmail && !_emailRegex.hasMatch(loginInput.toLowerCase())) {
      return 'Please enter a valid email address.';
    }
    if (!isEmail && _normalizePhone(loginInput).length < 9) {
      return 'Please enter a valid phone number.';
    }
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  String _cleanError(dynamic e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _login() async {
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
      text: 'Checking your account...',
    );
    debugPrint('[AUTH][LOGIN] Attempt started');

    try {
      final loginInput = _emailCtrl.text.trim();
      final result = await _api.login(
        loginInput: loginInput,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;

      final user = Map<String, dynamic>.from((result['user'] ?? {}) as Map);
      final token = (result['token'] ?? '').toString();
      if (user.isEmpty) {
        throw Exception('Login response is missing user data');
      }
      if (token.isEmpty) {
        throw Exception('Login response is missing access token');
      }

      AuthController.login(user, token: token);
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Login completed successfully.',
      );
      debugPrint('[AUTH][LOGIN] Success');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      final message = _cleanError(e);
      setState(() => _error = message);
      if (mounted) {
        AppAlerts.error(context, title: 'Server Error', text: message);
      }
      debugPrint('[AUTH][LOGIN] Error: $message');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                    Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF475569)),
                  ),
                  style: const TextStyle(color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Login'),
                  ),
                ),
                if (_loading) const LoadingState(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('or continue with'),
                const SizedBox(height: 10),
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
