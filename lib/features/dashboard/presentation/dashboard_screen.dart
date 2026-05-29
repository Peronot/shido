import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    final userId = (AuthController.currentUser.value?['id'] ?? '').toString();

    bool belongsToUser(Map<String, dynamic> row, String foreignKey) {
      if (userId.isEmpty) return false;
      final value = row[foreignKey];
      return value != null && value.toString() == userId;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFEFF), Color(0xFFCCFBF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overview of your games, players, and notifications.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: Future.wait([
              api.list('games'),
              api.list('players'),
              api.list('notifications'),
              api.list('game_teams', limit: 500),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }
              final allGames = snapshot.data?[0] ?? [];
              final allPlayers = snapshot.data?[1] ?? [];
              final allNotifications = snapshot.data?[2] ?? [];
              final allTeams = snapshot.data?[3] ?? [];

              final games = allGames
                  .where((g) => belongsToUser(g, 'created_by_user_id'))
                  .toList();
              final players = allPlayers
                  .where((p) => belongsToUser(p, 'user_id'))
                  .toList();
              final totalNotifications = allNotifications
                  .where((n) => belongsToUser(n, 'user_id'))
                  .length;
              final activeGames = games
                  .where((g) => (g['status'] ?? '').toString() == 'active')
                  .length;

              final teamsByGame = <String, List<String>>{};
              for (final t in allTeams) {
                final gameId = (t['game_id'] ?? '').toString();
                final teamName = (t['team_name'] ?? '').toString().trim();
                if (gameId.isEmpty || teamName.isEmpty) continue;
                teamsByGame.putIfAbsent(gameId, () => <String>[]).add(teamName);
              }

              return Column(
                children: [
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 96,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    children: [
                      MetricTile(
                        label: 'Total Games',
                        value: '${games.length}',
                        icon: Icons.sports_esports,
                        color: const Color(0xFF2563EB),
                      ),
                      MetricTile(
                        label: 'Active Games',
                        value: '$activeGames',
                        icon: Icons.play_circle,
                        color: const Color(0xFF16A34A),
                      ),
                      MetricTile(
                        label: 'Total Players',
                        value: '${players.length}',
                        icon: Icons.people,
                        color: const Color(0xFF7C3AED),
                      ),
                      MetricTile(
                        label: 'Notifications',
                        value: '$totalNotifications',
                        icon: Icons.notifications,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Live Games',
                    child: games.isEmpty
                        ? const EmptyState(message: 'No games found')
                        : Column(
                            children: games.take(5).map((g) {
                              final gameId = (g['id'] ?? '').toString();
                              final teams = teamsByGame[gameId] ?? const <String>[];
                              final title = teams.length >= 2
                                  ? '${teams[0]} vs ${teams[1]}'
                                  : gameId.substring(0, 8);
                              final isActive =
                                  (g['status'] ?? '').toString() == 'active';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Winning score: ${(g['winning_score'] ?? 101)}',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        (g['status'] ?? '-').toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isActive
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Recent Notifications',
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: api.list('notifications'),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(message: snapshot.error.toString());
                }
                final notes = (snapshot.data ?? [])
                    .where((n) => belongsToUser(n, 'user_id'))
                    .toList();
                if (notes.isEmpty) {
                  return const EmptyState(message: 'No notifications found');
                }
                return Column(
                  children: notes
                      .take(5)
                      .map(
                        (n) => ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text((n['title'] ?? '-').toString()),
                          subtitle: Text((n['message'] ?? '-').toString()),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
