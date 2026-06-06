import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';
import 'game_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ResourceApi _api = ResourceApi();
  late Future<List<_GameReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<_GameReport>> _loadReports() async {
    final results = await Future.wait([
      _api.list('games', limit: 500),
      _api.list('game_teams', limit: 1000),
      _api.list('reports', limit: 500),
    ]);
    final games = results[0];
    final teams = results[1];
    final savedReports = results[2];

    final teamsByGame = <String, List<Map<String, dynamic>>>{};
    for (final team in teams) {
      final gameId = (team['game_id'] ?? '').toString();
      if (gameId.isEmpty) continue;
      teamsByGame.putIfAbsent(gameId, () => <Map<String, dynamic>>[]).add(team);
    }

    final savedByGame = <String, Map<String, dynamic>>{};
    for (final report in savedReports) {
      final gameId = (report['game_id'] ?? '').toString();
      if (gameId.isNotEmpty) savedByGame[gameId] = report;
    }

    final reports = <_GameReport>[];
    for (final game in games) {
      final gameId = (game['id'] ?? '').toString();
      final gameTeams = teamsByGame[gameId] ?? const <Map<String, dynamic>>[];
      gameTeams.sort((a, b) {
        final sideA = (a['side'] as num?)?.toInt() ?? 0;
        final sideB = (b['side'] as num?)?.toInt() ?? 0;
        return sideA.compareTo(sideB);
      });

      final saved = savedByGame[gameId] ?? const <String, dynamic>{};
      final team1Name =
          (game['team1_name'] ??
                  saved['team1_name'] ??
                  (gameTeams.isNotEmpty ? gameTeams[0]['team_name'] : null) ??
                  'Team 1')
              .toString();
      final team2Name =
          (game['team2_name'] ??
                  saved['team2_name'] ??
                  (gameTeams.length > 1 ? gameTeams[1]['team_name'] : null) ??
                  'Team 2')
              .toString();
      final team1Score =
          ((game['team1_score'] ?? saved['team1_score'] ?? 0) as num).toInt();
      final team2Score =
          ((game['team2_score'] ?? saved['team2_score'] ?? 0) as num).toInt();
      final roundCount =
          ((saved['round_count'] ?? (game['rounds'] as List?)?.length ?? 0)
                  as num)
              .toInt();
      final status = (game['status'] ?? 'active').toString();
      final winner = (game['winner'] ?? saved['winner'] ?? '').toString();
      final date =
          (game['finished_at'] ??
                  saved['created_at'] ??
                  game['started_at'] ??
                  game['created_at'] ??
                  '')
              .toString();

      reports.add(
        _GameReport(
          gameId: gameId,
          title: '$team1Name vs $team2Name',
          status: status,
          team1Name: team1Name,
          team2Name: team2Name,
          team1Score: team1Score,
          team2Score: team2Score,
          winner: winner,
          roundCount: roundCount,
          date: date,
        ),
      );
    }

    reports.sort((a, b) => b.date.compareTo(a.date));
    return reports;
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _loadReports();
    });
    await _reportsFuture;
  }

  Future<void> _openReport(String gameId) async {
    if (gameId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameReportScreen(gameId: gameId)),
    );
    if (!mounted) return;
    await _refreshReports();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Reports',
        child: FutureBuilder<List<_GameReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState();
            }
            if (snapshot.hasError) {
              return ErrorState(message: snapshot.error.toString());
            }
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return const EmptyState(message: 'No game reports found');
            }
            return RefreshIndicator(
              onRefresh: _refreshReports,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: reports.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final isFinished = report.status == 'finished';
                  return ListTile(
                    onTap: () => _openReport(report.gameId),
                    leading: CircleAvatar(
                      backgroundColor: isFinished
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE0F2FE),
                      child: Icon(
                        isFinished
                            ? Icons.emoji_events_outlined
                            : Icons.play_circle_outline,
                        color: isFinished
                            ? const Color(0xFF15803D)
                            : const Color(0xFF0369A1),
                      ),
                    ),
                    title: Text(report.title),
                    subtitle: Text(report.subtitle),
                    trailing: Text(
                      '${report.team1Score} - ${report.team2Score}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameReport {
  const _GameReport({
    required this.gameId,
    required this.title,
    required this.status,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.winner,
    required this.roundCount,
    required this.date,
  });

  final String gameId;
  final String title;
  final String status;
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final String winner;
  final int roundCount;
  final String date;

  String get subtitle {
    final parts = <String>[
      status,
      if (winner.isNotEmpty) 'Winner: $winner',
      'Rounds: $roundCount',
      if (date.isNotEmpty) date.split('T').first,
    ];
    return parts.join(' • ');
  }
}
