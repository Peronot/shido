import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import 'social_auth.dart';
import '../ui/app_alerts.dart';
import 'auth_controller.dart';

Future<bool> requireLogin(BuildContext context) async {
  if (AuthController.isLoggedIn) return true;

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF0B1220),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Fadlan login samee si aad action-kan u isticmaasho.'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, 'login'),
                  child: const Text('Login with Email'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'google'),
                  child: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'facebook'),
                  child: const Text('Continue with Facebook'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == 'google') {
    if (!context.mounted) return false;
    return SocialAuth.loginWithGoogle(context);
  }

  if (choice == 'facebook') {
    if (!context.mounted) return false;
    return SocialAuth.loginWithFacebook(context);
  }

  if (choice == 'login') {
    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return AuthController.isLoggedIn;
  }

  if (context.mounted) {
    AppAlerts.info(
      context,
      title: 'Info',
      text: 'Action cancelled. Login is required to continue.',
    );
  }
  return false;
}
