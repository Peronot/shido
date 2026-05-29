import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/security/security_service.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final api = ResourceApi();
  Timer? _timer;
  int _lastCount = 0;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.list('notifications');
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final enabled = await SecurityService.getNotificationsEnabled();
      if (!enabled || !mounted) return;
      try {
        final items = await api.list('notifications');
        if (!mounted) return;
        if (_lastCount > 0 && items.length > _lastCount) {
          AppAlerts.info(
            context,
            title: 'New Notification',
            text: 'Wax cusub ayaa lagu soo kordhiyay notifications.',
          );
        }
        _lastCount = items.length;
        setState(() => _future = Future.value(items));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Notifications',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final items = snapshot.data ?? [];
            _lastCount = items.length;
            if (items.isEmpty) return const EmptyState(message: 'No notifications found');
            return Column(
              children: items
                  .map((n) => ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text((n['title'] ?? '-').toString()),
                        subtitle: Text((n['message'] ?? '-').toString()),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
