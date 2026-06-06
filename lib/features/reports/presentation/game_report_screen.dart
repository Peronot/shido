import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/async_state_widgets.dart';

class GameReportScreen extends StatefulWidget {
  const GameReportScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameReportScreen> createState() => _GameReportScreenState();
}

class _GameReportScreenState extends State<GameReportScreen> {
  final ResourceApi _api = ResourceApi();
  final _team1Ctrl = TextEditingController();
  final _team2Ctrl = TextEditingController();
  final _score1Ctrl = TextEditingController();
  final _score2Ctrl = TextEditingController();
  late Future<_EditableGameReport> _reportFuture;
  String _status = 'active';
  String _winner = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  @override
  void dispose() {
    _team1Ctrl.dispose();
    _team2Ctrl.dispose();
    _score1Ctrl.dispose();
    _score2Ctrl.dispose();
    super.dispose();
  }

  Future<_EditableGameReport> _loadReport() async {
    final results = await Future.wait([
      _api.getById('games', widget.gameId),
      _api.list('game_teams', limit: 1000),
      _api.list('reports', limit: 1000),
    ]);
    final game = results[0] as Map<String, dynamic>;
    final teams = (results[1] as List<Map<String, dynamic>>)
        .where((team) => (team['game_id'] ?? '').toString() == widget.gameId)
        .toList();
    teams.sort((a, b) {
      final sideA = (a['side'] as num?)?.toInt() ?? 0;
      final sideB = (b['side'] as num?)?.toInt() ?? 0;
      return sideA.compareTo(sideB);
    });

    final reports = results[2] as List<Map<String, dynamic>>;
    final report = reports
        .where((item) => (item['game_id'] ?? '').toString() == widget.gameId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;

    final team1Name =
        (game['team1_name'] ??
                report?['team1_name'] ??
                (teams.isNotEmpty ? teams[0]['team_name'] : null) ??
                'Team 1')
            .toString();
    final team2Name =
        (game['team2_name'] ??
                report?['team2_name'] ??
                (teams.length > 1 ? teams[1]['team_name'] : null) ??
                'Team 2')
            .toString();
    final team1Score = _toInt(game['team1_score'] ?? report?['team1_score']);
    final team2Score = _toInt(game['team2_score'] ?? report?['team2_score']);
    final status = (game['status'] ?? 'active').toString();
    final winner = (game['winner'] ?? report?['winner'] ?? '').toString();

    _team1Ctrl.text = team1Name;
    _team2Ctrl.text = team2Name;
    _score1Ctrl.text = team1Score.toString();
    _score2Ctrl.text = team2Score.toString();
    _status = status;
    _winner = winner.isNotEmpty ? winner : _defaultWinner(team1Name, team2Name);

    return _EditableGameReport(
      game: game,
      report: report,
      teams: teams,
      team1Name: team1Name,
      team2Name: team2Name,
      team1Score: team1Score,
      team2Score: team2Score,
    );
  }

  String _defaultWinner(String team1Name, String team2Name) {
    final team1Score = int.tryParse(_score1Ctrl.text.trim()) ?? 0;
    final team2Score = int.tryParse(_score2Ctrl.text.trim()) ?? 0;
    if (team1Score == team2Score) return '';
    return team1Score > team2Score ? team1Name : team2Name;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  Future<void> _saveReport(_EditableGameReport report) async {
    final team1Name = _team1Ctrl.text.trim();
    final team2Name = _team2Ctrl.text.trim();
    final team1Score = int.tryParse(_score1Ctrl.text.trim());
    final team2Score = int.tryParse(_score2Ctrl.text.trim());

    if (team1Name.isEmpty || team2Name.isEmpty) {
      AppAlerts.warning(
        context,
        title: 'Validation',
        text: 'Both team names are required.',
      );
      return;
    }
    if (team1Name.toLowerCase() == team2Name.toLowerCase()) {
      AppAlerts.warning(
        context,
        title: 'Validation',
        text: 'Team names must be different.',
      );
      return;
    }
    if (team1Score == null ||
        team1Score < 0 ||
        team2Score == null ||
        team2Score < 0) {
      AppAlerts.warning(
        context,
        title: 'Validation',
        text: 'Scores must be valid positive numbers.',
      );
      return;
    }

    setState(() => _saving = true);
    AppAlerts.loading(context, title: 'Saving', text: 'Saving game report...');

    final savedAt = DateTime.now().toUtc().toIso8601String();
    final winner = _winner.trim();
    try {
      await _api.update('games', widget.gameId, {
        'team1_name': team1Name,
        'team2_name': team2Name,
        'team1_score': team1Score,
        'team2_score': team2Score,
        'winner': winner,
        'status': _status,
        if (_status == 'finished') 'finished_at': savedAt,
      });
      await _saveTeam(report, 1, team1Name);
      await _saveTeam(report, 2, team2Name);
      await _saveReportRow(
        report.report,
        team1Name,
        team2Name,
        team1Score,
        team2Score,
        winner,
        savedAt,
      );

      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Saved',
        text: 'Game report updated successfully.',
      );
      setState(() {
        _reportFuture = _loadReport();
      });
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(context, title: 'Save Failed', text: e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveTeam(
    _EditableGameReport report,
    int side,
    String teamName,
  ) async {
    final existing = report.teams
        .where((team) => ((team['side'] as num?)?.toInt() ?? 0) == side)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;
    if (existing != null) {
      await _api.update('game_teams', existing['id'].toString(), {
        'team_name': teamName,
        'side': side,
      });
      return;
    }

    await _api.create('game_teams', {
      'game_id': widget.gameId,
      'team_name': teamName,
      'side': side,
    });
  }

  Future<void> _saveReportRow(
    Map<String, dynamic>? existing,
    String team1Name,
    String team2Name,
    int team1Score,
    int team2Score,
    String winner,
    String savedAt,
  ) async {
    final payload = {
      'report_type': 'Game result',
      'format': 'local',
      'game_id': widget.gameId,
      'title': '$team1Name vs $team2Name',
      'summary': winner.isEmpty
          ? '$team1Score - $team2Score'
          : '$winner won $team1Score - $team2Score',
      'winner': winner,
      'team1_name': team1Name,
      'team2_name': team2Name,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'created_at': existing?['created_at'] ?? savedAt,
      'updated_at': savedAt,
    };

    final id = (existing?['id'] ?? '').toString();
    if (id.isEmpty) {
      await _api.create('reports', payload);
    } else {
      await _api.update('reports', id, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Report')),
      body: FutureBuilder<_EditableGameReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString());
          }
          final report = snapshot.data;
          if (report == null) {
            return const EmptyState(message: 'No report found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReportHeader(report: report),
                const SizedBox(height: 16),
                TextField(
                  controller: _team1Ctrl,
                  decoration: const InputDecoration(labelText: 'Team 1 Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _score1Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Team 1 Score'),
                  onChanged: (_) {
                    setState(
                      () => _winner = _defaultWinner(
                        _team1Ctrl.text,
                        _team2Ctrl.text,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _team2Ctrl,
                  decoration: const InputDecoration(labelText: 'Team 2 Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _score2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Team 2 Score'),
                  onChanged: (_) {
                    setState(
                      () => _winner = _defaultWinner(
                        _team1Ctrl.text,
                        _team2Ctrl.text,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('active')),
                    DropdownMenuItem(
                      value: 'finished',
                      child: Text('finished'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('cancelled'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _winner.isEmpty ? null : _winner,
                  decoration: const InputDecoration(labelText: 'Winner'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('No winner')),
                    DropdownMenuItem(
                      value: _team1Ctrl.text,
                      child: Text(_team1Ctrl.text),
                    ),
                    DropdownMenuItem(
                      value: _team2Ctrl.text,
                      child: Text(_team2Ctrl.text),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _winner = value ?? ''),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _saveReport(report),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Report'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final _EditableGameReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${report.team1Name} vs ${report.team2Name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${report.team1Score} - ${report.team2Score}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EditableGameReport {
  const _EditableGameReport({
    required this.game,
    required this.report,
    required this.teams,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
  });

  final Map<String, dynamic> game;
  final Map<String, dynamic>? report;
  final List<Map<String, dynamic>> teams;
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
}
