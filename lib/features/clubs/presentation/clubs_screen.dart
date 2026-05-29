import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Clubs',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('clubs'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final clubs = snapshot.data ?? [];
            if (clubs.isEmpty) return const EmptyState(message: 'No clubs found');
            return Column(
              children: clubs
                  .map((c) => ListTile(
                        leading: CircleAvatar(child: Text((c['name'] ?? 'C').toString().substring(0, 1))),
                        title: Text((c['name'] ?? '-').toString()),
                        subtitle: Text((c['location'] ?? 'Unknown location').toString()),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
