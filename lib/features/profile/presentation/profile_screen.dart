import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/security/security_service.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/async_state_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ResourceApi();
  bool _pushNotifications = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final notif = await SecurityService.getNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _pushNotifications = notif;
    });
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final users = await _api.list('users', limit: 1);
    if (users.isNotEmpty) return users.first;

    return _api.create('users', {
      'full_name': 'Local User',
      'email': 'local@shido.app',
      'phone': '',
      'role': 'user',
      'is_active': true,
    });
  }

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    final id = (user['id'] ?? '').toString();
    if (id.isEmpty) {
      AppAlerts.error(context, title: 'Error', text: 'User id not found.');
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
                        await _api.update('users', id, {
                          'full_name': fullNameCtrl.text.trim(),
                          'email': emailCtrl.text.trim().toLowerCase(),
                          'phone': phoneCtrl.text.trim(),
                        });
                        if (!mounted || !sheetContext.mounted) return;
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
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    if (!mounted || !context.mounted) return;

    AppAlerts.loading(
      context,
      title: 'Uploading',
      text: 'Saving profile photo...',
    );
    try {
      final bytes = await image.readAsBytes();
      final mime = image.mimeType ?? 'image/jpeg';
      final base64Data = base64Encode(bytes);
      final dataUrl = 'data:$mime;base64,$base64Data';

      await _api.update('users', id, {'profile_photo_url': dataUrl});
      if (!mounted) return;
      AppAlerts.close(context);
      setState(() {});
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Profile photo updated.',
      );
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(context, title: 'Photo Failed', text: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: FilledButton(
                  onPressed: () => _openEditProfile(user),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Preferences',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
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
                          text:
                              'Push notifications ${value ? 'enabled' : 'disabled'}.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('WhatsApp Support'),
                      subtitle: const Text('0615270078'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openWhatsApp,
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
