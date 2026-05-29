import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../core/security/security_service.dart';
import '../core/ui/app_alerts.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/clubs/presentation/clubs_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/games/presentation/games_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/payments/presentation/payments_screen.dart';
import '../features/players/presentation/players_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/teams/presentation/teams_screen.dart';
import '../features/tournaments/presentation/tournaments_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  bool _unlockChecked = false;

  final items = const [
    _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
    _NavItem('Games', Icons.sports_esports_outlined, GamesScreen()),
    _NavItem('Players', Icons.people_outline, PlayersScreen()),
    _NavItem('Teams', Icons.groups_2_outlined, TeamsScreen()),
    _NavItem('Clubs', Icons.apartment_outlined, ClubsScreen()),
    _NavItem('Tournaments', Icons.emoji_events_outlined, TournamentsScreen()),
    _NavItem('Reports', Icons.description_outlined, ReportsScreen()),
    _NavItem('Payments', Icons.payments_outlined, PaymentsScreen()),
    _NavItem('Notifications', Icons.notifications_none, NotificationsScreen()),
    _NavItem('Messages', Icons.chat_bubble_outline, MessagesScreen()),
    _NavItem('Support', Icons.support_agent_outlined, SupportScreen()),
    _NavItem('Profile', Icons.person_outline, ProfileScreen()),
    _NavItem('Settings', Icons.settings_outlined, SettingsScreen()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSecurityUnlock());
  }

  Future<void> _runSecurityUnlock() async {
    if (!mounted || _unlockChecked || !AuthController.isLoggedIn) return;
    _unlockChecked = true;
    if (AuthController.skipNextSecurityUnlock) {
      AuthController.skipNextSecurityUnlock = false;
      return;
    }

    final bioEnabled = await SecurityService.getBiometricEnabled();
    final pinEnabled = await SecurityService.hasPin();
    final canUseBio = await SecurityService.canUseBiometric();

    if (bioEnabled) {
      if (canUseBio) {
        final ok = await SecurityService.authenticateBiometric();
        if (ok || !mounted) return;
      } else if (!pinEnabled) {
        // Do not lock users out when biometric is enabled but unavailable on this device/browser.
        await SecurityService.setBiometricEnabled(false);
        if (!mounted) return;
        AppAlerts.info(
          context,
          title: 'Biometric Disabled',
          text: 'This device/browser does not support biometric unlock.',
        );
        return;
      }
    }

    if (pinEnabled && mounted) {
      final pinOk = await _askPinDialog();
      if (pinOk || !mounted) return;
    }

    if (mounted) {
      AppAlerts.error(
        context,
        title: 'Access Denied',
        text: 'Authentication failed. Please login again.',
      );
      AuthController.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<bool> _askPinDialog() async {
    final pinCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: TextField(
            controller: pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    if (ok != true) return false;
    return SecurityService.verifyPin(pinCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final currentUser = AuthController.currentUser.value;
    final isAdmin =
        (currentUser?['is_admin'] == true) ||
        (currentUser?['role'] ?? '').toString().toLowerCase() == 'admin';

    if (isDesktop) {
      if (!isAdmin) {
        return Scaffold(
          appBar: AppBar(title: Text(items[_index].title)),
          body: items[_index].screen,
        );
      }

      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'SHIDO APP',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              destinations: items
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(
                        item.icon,
                        color: const Color(0xFF1D4ED8),
                      ),
                      label: Text(item.title),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: items[_index].screen),
          ],
        ),
      );
    }

    const mobileIndexes = [0, 1, 2, 8, 11];
    final current = mobileIndexes.contains(_index) ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(items[_index].title),
        automaticallyImplyLeading: isAdmin,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFECFEFF), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: isAdmin
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF1D4ED8)),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Shido App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < items.length; i++)
                    ListTile(
                      leading: Icon(items[i].icon),
                      title: Text(items[i].title),
                      selected: _index == i,
                      onTap: () {
                        if (items[i].title == 'Profile' &&
                            !AuthController.isLoggedIn) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                          return;
                        }
                        setState(() => _index = i);
                        Navigator.pop(context);
                      },
                    ),
                  const Divider(),
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: AuthController.currentUser,
                    builder: (context, user, _) {
                      if (user == null) {
                        return ListTile(
                          leading: const Icon(Icons.login),
                          title: const Text('Login'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        );
                      }

                      return ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () {
                          AuthController.logout();
                          setState(() => _index = 0);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
      body: items[_index].screen,
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: mobileIndexes.indexOf(current),
        onDestinationSelected: (value) {
          final target = mobileIndexes[value];
          if (items[target].title == 'Profile' && !AuthController.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }
          setState(() => _index = target);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.title, this.icon, this.screen);

  final String title;
  final IconData icon;
  final Widget screen;
}
