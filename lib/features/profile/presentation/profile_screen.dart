import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/security/security_service.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/async_state_widgets.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ResourceApi();
  bool _pushNotifications = true;
  bool _faceId = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final notif = await SecurityService.getNotificationsEnabled();
    final face = await SecurityService.getBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _pushNotifications = notif;
      _faceId = face;
    });
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final currentUser = AuthController.currentUser.value;
    final userId = (currentUser?['id'] ?? '').toString().trim();
    if (userId.isEmpty) return null;

    final fresh = await _api.getById('users', userId);
    AuthController.login(
      {
        ...(currentUser ?? <String, dynamic>{}),
        ...fresh,
      },
      token: AuthController.accessToken.value,
    );
    return fresh;
  }

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    final id = (user['id'] ?? '').toString();
    if (id.isEmpty) {
      AppAlerts.error(
        context,
        title: 'Error',
        text: 'User id not found.',
      );
      return;
    }

    final fullNameCtrl = TextEditingController(
      text: (user['full_name'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (user['email'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (user['phone'] ?? '').toString(),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (fullNameCtrl.text.trim().isEmpty) {
                        AppAlerts.warning(
                          sheetContext,
                          title: 'Validation',
                          text: 'Full name is required.',
                        );
                        return;
                      }
                      AppAlerts.loading(
                        sheetContext,
                        title: 'Saving',
                        text: 'Updating profile...',
                      );
                      try {
                        final updated = await _api.update('users', id, {
                          'full_name': fullNameCtrl.text.trim(),
                          'email': emailCtrl.text.trim().toLowerCase(),
                          'phone': phoneCtrl.text.trim(),
                        });
                        if (!mounted || !sheetContext.mounted) return;
                        AuthController.login(
                          {
                            ...(AuthController.currentUser.value ?? <String, dynamic>{}),
                            ...updated,
                          },
                          token: AuthController.accessToken.value,
                        );
                        AppAlerts.close(sheetContext);
                        Navigator.pop(sheetContext, true);
                      } catch (e) {
                        if (!mounted || !sheetContext.mounted) return;
                        AppAlerts.close(sheetContext);
                        AppAlerts.error(
                          sheetContext,
                          title: 'Update Failed',
                          text: e.toString(),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Profile updated successfully.',
      );
      setState(() {});
    }
  }

  Future<void> _openPinDialog() async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set PIN Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN (4+ digits)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    if (!mounted) return;

    final pin = pinCtrl.text.trim();
    if (pin.length < 4 || pin != confirmCtrl.text.trim()) {
      AppAlerts.error(
        context,
        title: 'PIN Error',
        text: 'PIN is invalid or does not match.',
      );
      return;
    }
    await SecurityService.setPin(pin);
    if (!mounted) return;
    AppAlerts.success(context, title: 'Success', text: 'PIN code saved.');
  }

  Future<void> _openChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    if (!mounted) return;
    if (newCtrl.text.trim().length < 6 || newCtrl.text.trim() != confirmCtrl.text.trim()) {
      AppAlerts.error(context, title: 'Error', text: 'New password is invalid.');
      return;
    }

    AppAlerts.loading(context, title: 'Saving', text: 'Changing password...');
    try {
      await _api.changePassword(
        currentPassword: currentCtrl.text,
        newPassword: newCtrl.text.trim(),
      );
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.success(context, title: 'Success', text: 'Password changed.');
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(context, title: 'Failed', text: e.toString());
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/252615270078');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    AppAlerts.error(
      context,
      title: 'WhatsApp',
      text: 'Unable to open WhatsApp now.',
    );
  }

  Future<void> _pickProfilePhoto(Map<String, dynamic> user) async {
    final id = (user['id'] ?? '').toString();
    if (id.isEmpty) return;
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    if (!mounted || !context.mounted) return;

    AppAlerts.loading(context, title: 'Uploading', text: 'Saving profile photo...');
    try {
      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? 'image/jpeg';
      final base64Data = base64Encode(bytes);
      final dataUrl = 'data:$mime;base64,$base64Data';

      final updated = await _api.update('users', id, {
        'profile_photo_url': dataUrl,
      });
      if (!mounted) return;
      AuthController.login(
        {...(AuthController.currentUser.value ?? <String, dynamic>{}), ...updated},
        token: AuthController.accessToken.value,
      );
      AppAlerts.close(context);
      setState(() {});
      AppAlerts.success(context, title: 'Success', text: 'Profile photo updated.');
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(context, title: 'Photo Failed', text: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthController.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 52),
              const SizedBox(height: 12),
              const Text('Profile is available only after login'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: LoadingState());
        }
        if (snapshot.hasError) {
          return Center(child: ErrorState(message: snapshot.error.toString()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: EmptyState(message: 'No user found'));
        }

        final name = (user['full_name'] ?? 'User').toString();
        final email = (user['email'] ?? '-').toString();
        final phone = (user['phone'] ?? '-').toString();
        final photo = (user['profile_photo_url'] ?? '').toString().trim();
        ImageProvider? avatarImage;
        if (photo.isNotEmpty) {
          if (photo.startsWith('data:image')) {
            final commaIndex = photo.indexOf(',');
            if (commaIndex > 0) {
              final raw = photo.substring(commaIndex + 1);
              avatarImage = MemoryImage(base64Decode(raw));
            }
          } else {
            avatarImage = NetworkImage(photo);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFFC6F6D5),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(Icons.person, size: 58, color: Colors.black87)
                    : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => _pickProfilePhoto(user),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Upload photo'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: FilledButton(
                  onPressed: () => _openEditProfile(user),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  ),
                  child: const Text('Edit profile'),
                ),
              ),
              const SizedBox(height: 26),
              Text('Preferences', style: TextStyle(color: Colors.grey.shade600, fontSize: 22)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_none),
                      title: const Text('Push notifications'),
                      value: _pushNotifications,
                      onChanged: (value) async {
                        await SecurityService.setNotificationsEnabled(value);
                        if (!mounted || !context.mounted) return;
                        setState(() => _pushNotifications = value);
                        AppAlerts.info(
                          context,
                          title: 'Preference Updated',
                          text: 'Push notifications ${value ? 'enabled' : 'disabled'}.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.face_outlined),
                      title: const Text('Face ID'),
                      value: _faceId,
                      onChanged: (value) async {
                        if (value) {
                          final ok = await SecurityService.authenticateBiometric();
                          if (!ok) {
                            if (!mounted || !context.mounted) return;
                            AppAlerts.error(
                              context,
                              title: 'Face ID',
                              text: 'Biometric verification failed.',
                            );
                            return;
                          }
                        }
                        await SecurityService.setBiometricEnabled(value);
                        if (!mounted || !context.mounted) return;
                        setState(() => _faceId = value);
                        AppAlerts.info(
                          context,
                          title: 'Preference Updated',
                          text: 'Face ID ${value ? 'enabled' : 'disabled'}.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.pin_outlined),
                      title: const Text('PIN Code'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPinDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_outlined),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openChangePasswordDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('WhatsApp Support'),
                      subtitle: const Text('0615270078'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openWhatsApp,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        final ok = await AppAlerts.confirmBool(
                          context,
                          title: 'Logout',
                          text: 'Are you sure you want to logout?',
                          confirmText: 'Logout',
                        );
                        if (!ok || !mounted || !context.mounted) return;
                        AuthController.logout();
                        if (!mounted || !context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
