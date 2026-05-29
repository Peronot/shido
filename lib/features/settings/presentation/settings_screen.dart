import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Settings',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('app_settings'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final settings = snapshot.data ?? [];
            if (settings.isEmpty) return const EmptyState(message: 'No settings found');
            return Column(
              children: settings
                  .map((s) => ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text((s['setting_key'] ?? '-').toString()),
                        subtitle: Text((s['description'] ?? '-').toString()),
                        trailing: Text((s['setting_value'] ?? '-').toString()),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
