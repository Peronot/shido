import 'package:flutter/material.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';
import '../../game/presentation/new_game_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final ResourceApi _api = ResourceApi();
  late Future<List<Map<String, dynamic>>> _gamesFuture;
  Map<String, List<String>> _teamsByGameId = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    _gamesFuture = _loadGames();
  }

  Future<List<Map<String, dynamic>>> _loadGames() async {
    final results = await Future.wait([
      _api.list('games'),
      _api.list('game_teams', limit: 500),
    ]);
    final games = results[0];
    final teams = results[1];

    final mapped = <String, List<String>>{};
    for (final team in teams) {
      final gameId = (team['game_id'] ?? '').toString();
      final name = (team['team_name'] ?? '').toString().trim();
      if (gameId.isEmpty || name.isEmpty) continue;
      mapped.putIfAbsent(gameId, () => <String>[]).add(name);
    }
    _teamsByGameId = mapped;
    return games;
  }

  Future<void> _refreshGames() async {
    setState(() {
      _gamesFuture = _loadGames();
    });
    await _gamesFuture;
  }

  Future<void> _editGame(Map<String, dynamic> game) async {
    final id = (game['id'] ?? '').toString();
    if (id.isEmpty) return;
    final scoreCtrl = TextEditingController(
      text: (game['winning_score'] ?? 101).toString(),
    );
    String status = (game['status'] ?? 'active').toString();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('active')),
                  DropdownMenuItem(value: 'finished', child: Text('finished')),
                  DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                ],
                onChanged: (v) => status = v ?? 'active',
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Winning Score'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final parsed = int.tryParse(scoreCtrl.text.trim());
                      if (parsed == null || parsed <= 0) {
                        AppAlerts.warning(
                          sheetContext,
                          title: 'Validation',
                          text: 'Winning score must be a valid number.',
                        );
                        return;
                      }
                    AppAlerts.loading(sheetContext, title: 'Updating', text: 'Updating game...');
                    try {
                      await _api.update('games', id, {
                        'status': status,
                        'winning_score': parsed,
                      });
                      if (!mounted || !sheetContext.mounted) return;
                      AppAlerts.close(sheetContext);
                      Navigator.pop(sheetContext, true);
                    } catch (e) {
                      if (!mounted || !sheetContext.mounted) return;
                      AppAlerts.close(sheetContext);
                      AppAlerts.error(
                        sheetContext,
                        title: 'Update Failed',
                        text: e.toString(),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (updated == true && mounted) {
      AppAlerts.success(context, title: 'Success', text: 'Game updated successfully.');
      await _refreshGames();
    }
  }

  Future<void> _deleteGame(Map<String, dynamic> game) async {
    final id = (game['id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok = await AppAlerts.confirmBool(
      context,
      title: 'Delete Game',
      text: 'Are you sure you want to delete this game?',
      confirmText: 'Delete',
    );
    if (!ok) return;
    if (!mounted) return;

    AppAlerts.loading(context, title: 'Deleting', text: 'Deleting game...');
    try {
      await _api.remove('games', id);
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.success(context, title: 'Deleted', text: 'Game deleted successfully.');
      await _refreshGames();
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(context, title: 'Delete Failed', text: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Games',
        action: FilledButton.icon(
          onPressed: () async {
            final allowed = await requireLogin(context);
            if (!context.mounted || !allowed) return;
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewGameScreen()),
            );
            if (!context.mounted) return;
            await _refreshGames();
          },
          icon: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.white),
          ),
          label: const Text(
            'New Game',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0E7490),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _gamesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final games = snapshot.data ?? [];
            if (games.isEmpty) return const EmptyState(message: 'No games found');
            return RefreshIndicator(
              onRefresh: _refreshGames,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: games.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final g = games[index];
                  final gameId = (g['id'] ?? '-').toString();
                  final shortId = gameId.length >= 8 ? gameId.substring(0, 8) : gameId;
                  final startedAt = (g['started_at'] ?? '').toString();
                  final teamNames = _teamsByGameId[gameId] ?? const <String>[];
                  final gameTitle = teamNames.length >= 2
                      ? '${teamNames[0]} vs ${teamNames[1]}'
                      : 'Game $shortId';

                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(gameTitle),
                    subtitle: Text(
                      startedAt.isEmpty
                          ? 'Status: ${g['status'] ?? '-'}'
                          : 'Status: ${g['status'] ?? '-'} • Date: ${startedAt.split('T').first}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _editGame(g);
                        } else if (value == 'delete') {
                          await _deleteGame(g);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
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
