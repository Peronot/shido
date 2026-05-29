import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Teams',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('game_teams'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final teams = snapshot.data ?? [];
            if (teams.isEmpty) return const EmptyState(message: 'No teams found');
            return Column(
              children: teams
                  .map((t) => ListTile(
                        title: Text((t['team_name'] ?? '-').toString()),
                        subtitle: Text('Score: ${t['total_score'] ?? 0}'),
                        trailing: Text((t['is_winner'] == true) ? 'Winner' : 'Playing'),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
