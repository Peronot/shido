import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Tournaments',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('tournaments'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final tournaments = snapshot.data ?? [];
            if (tournaments.isEmpty) return const EmptyState(message: 'No tournaments found');
            return Column(
              children: tournaments
                  .map((t) => ListTile(
                        title: Text((t['name'] ?? '-').toString()),
                        subtitle: Text('${t['teams_count'] ?? 0} teams • ${t['status'] ?? '-'}'),
                        trailing: Text('\$${t['prize'] ?? 0}'),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
