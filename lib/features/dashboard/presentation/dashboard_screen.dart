import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ResourceApi _api = ResourceApi();
  late Future<List<List<Map<String, dynamic>>>> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = Future.wait([
      _api.list('games'),
      _api.list('players'),
      _api.list('notifications'),
      _api.list('game_teams', limit: 500),
    ]);
    _notificationsFuture = _api.list('notifications');
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E7490),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shido App',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    'Milkiilaha waa Zakariye Abdulahi Gaaldiid',
                    style: TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: _dashboardFuture,
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

              final games = allGames;
              final players = allPlayers;
              final totalNotifications = allNotifications.length;
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
                              final teams =
                                  teamsByGame[gameId] ?? const <String>[];
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
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(message: snapshot.error.toString());
                }
                final notes = snapshot.data ?? [];
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
