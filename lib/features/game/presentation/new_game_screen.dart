import 'package:flutter/material.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/network/resource_api.dart';
import 'game_play_screen.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _api = ResourceApi();
  final TextEditingController _teamAController = TextEditingController(
    text: 'Team A',
  );
  final TextEditingController _teamBController = TextEditingController(
    text: 'Team B',
  );
  bool _starting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETUP NEW GAME')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Names',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildTeamNameField(_teamAController, 'Team A Name'),
            const SizedBox(height: 20),
            _buildTeamNameField(_teamBController, 'Team B Name'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _starting
                    ? null
                    : () async {
                        final teamA = _teamAController.text.trim();
                        final teamB = _teamBController.text.trim();
                        if (teamA.isEmpty || teamB.isEmpty) {
                          AppAlerts.warning(
                            context,
                            title: 'Missing Team Name',
                            text: 'Please enter both Team A and Team B names.',
                          );
                          return;
                        }
                        if (teamA.toLowerCase() == teamB.toLowerCase()) {
                          AppAlerts.warning(
                            context,
                            title: 'Invalid Team Names',
                            text: 'Team names must be different.',
                          );
                          return;
                        }

                        setState(() => _starting = true);

                        var gameId = '';
                        try {
                          final createdGame = await _api.create('games', {
                            'status': 'active',
                            'winning_score': 101,
                            'team1_name': teamA,
                            'team2_name': teamB,
                          });
                          gameId = (createdGame['id'] ?? '').toString();
                          if (gameId.isNotEmpty) {
                            await _api.create('game_teams', {
                              'game_id': gameId,
                              'team_name': teamA,
                              'side': 1,
                            });
                            await _api.create('game_teams', {
                              'game_id': gameId,
                              'team_name': teamB,
                              'side': 2,
                            });
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          AppAlerts.error(
                            context,
                            title: 'Start Failed',
                            text: e.toString(),
                          );
                          setState(() => _starting = false);
                          return;
                        }

                        if (!context.mounted) return;
                        AppAlerts.success(
                          context,
                          title: 'Game Ready',
                          text: '$teamA vs $teamB created successfully.',
                        );
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GamePlayScreen(
                              gameId: gameId,
                              team1Name: teamA,
                              team2Name: teamB,
                              winningScore: 101,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          setState(() => _starting = false);
                        }
                      },
                child: const Text(
                  'START GAME',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamNameField(TextEditingController controller, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color(0xFF475569)),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
