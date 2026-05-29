import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../network/resource_api.dart';
import '../ui/app_alerts.dart';
import 'auth_controller.dart';

class SocialAuth {
  static final _api = ResourceApi();
  static const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static final _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    clientId: kIsWeb && _googleWebClientId.isNotEmpty ? _googleWebClientId : null,
  );

  static Future<bool> loginWithGoogle(BuildContext context) async {
    if (kIsWeb && _googleWebClientId.isEmpty) {
      AppAlerts.error(
        context,
        title: 'Google Login Setup Required',
        text:
            'Web Google Client ID is missing. Run with --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID',
      );
      return false;
    }

    AppAlerts.loading(context, title: 'Loading', text: 'Connecting Google...');
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (context.mounted) {
          AppAlerts.close(context);
          AppAlerts.info(context, title: 'Cancelled', text: 'Google sign-in cancelled.');
        }
        return false;
      }

      final auth = await _api.socialLogin(
        email: account.email.trim().toLowerCase(),
        fullName: (account.displayName ?? '').trim(),
        provider: 'google',
      );
      final user = Map<String, dynamic>.from((auth['user'] ?? {}) as Map);
      final token = (auth['token'] ?? '').toString();
      if (user.isEmpty || token.isEmpty) {
        throw Exception('Social login response is incomplete');
      }

      if (!context.mounted) return false;
      AuthController.login(user, token: token);
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Logged in with Google successfully.',
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      AppAlerts.close(context);
      AppAlerts.error(
        context,
        title: 'Google Login Failed',
        text: _cleanError(e),
      );
      return false;
    }
  }

  static Future<bool> loginWithFacebook(BuildContext context) async {
    AppAlerts.loading(context, title: 'Loading', text: 'Connecting Facebook...');
    try {
      await FacebookAuth.instance.logOut();
      final result = await FacebookAuth.instance.login(
        permissions: <String>['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        if (context.mounted) {
          AppAlerts.close(context);
          AppAlerts.info(context, title: 'Cancelled', text: 'Facebook sign-in cancelled.');
        }
        return false;
      }

      final data = await FacebookAuth.instance.getUserData(
        fields: 'name,email',
      );
      final rawEmail = (data['email'] ?? '').toString().trim().toLowerCase();
      if (rawEmail.isEmpty) {
        if (!context.mounted) return false;
        AppAlerts.close(context);
        AppAlerts.error(
          context,
          title: 'Facebook Login Failed',
          text: 'Email permission is required. Please allow email access in Facebook.',
        );
        return false;
      }

      final auth = await _api.socialLogin(
        email: rawEmail,
        fullName: (data['name'] ?? '').toString().trim(),
        provider: 'facebook',
      );
      final user = Map<String, dynamic>.from((auth['user'] ?? {}) as Map);
      final token = (auth['token'] ?? '').toString();
      if (user.isEmpty || token.isEmpty) {
        throw Exception('Social login response is incomplete');
      }

      if (!context.mounted) return false;
      AuthController.login(user, token: token);
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Logged in with Facebook successfully.',
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      AppAlerts.close(context);
      AppAlerts.error(
        context,
        title: 'Facebook Login Failed',
        text: _cleanError(e),
      );
      return false;
    }
  }

  static String _cleanError(Object e) {
    final raw = e.toString();
    return raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;
  }
}
