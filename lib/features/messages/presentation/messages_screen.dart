import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Messages',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('audit_logs'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) return const EmptyState(message: 'No messages/logs found');
            return Column(
              children: logs
                  .map((l) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.message)),
                        title: Text((l['action'] ?? '-').toString()),
                        subtitle: Text((l['entity_name'] ?? '-').toString()),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
