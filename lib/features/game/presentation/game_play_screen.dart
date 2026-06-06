import 'package:flutter/material.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({
    super.key,
    required this.team1Name,
    required this.team2Name,
    this.gameId,
    this.winningScore = 101,
  });

  final String team1Name;
  final String team2Name;
  final String? gameId;
  final int winningScore;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  final ResourceApi _api = ResourceApi();
  int team1Total = 0;
  int team2Total = 0;
  List<Map<String, int>> rounds = [];

  final TextEditingController _t1Controller = TextEditingController();
  final TextEditingController _t2Controller = TextEditingController();

  void _addRound() {
    int s1 = int.tryParse(_t1Controller.text) ?? 0;
    int s2 = int.tryParse(_t2Controller.text) ?? 0;

    if (s1 == 0 && s2 == 0) {
      AppAlerts.warning(
        context,
        title: 'Invalid Score',
        text: 'Please enter score for at least one team.',
      );
      return;
    }

    setState(() {
      rounds.add({'t1': s1, 't2': s2});
      team1Total += s1;
      team2Total += s2;
      _t1Controller.clear();
      _t2Controller.clear();
    });

    _checkWinner();
  }

  Future<void> _checkWinner() async {
    if (team1Total >= widget.winningScore ||
        team2Total >= widget.winningScore) {
      final winner = team1Total >= widget.winningScore
          ? widget.team1Name
          : widget.team2Name;
      await _saveFinishedGame(winner);
      if (!mounted) return;
      AppAlerts.confirm(
        context,
        title: 'Game Over',
        text: '$winner wins the game. Back to dashboard?',
        onConfirm: () {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }
  }

  Future<void> _saveFinishedGame(String winner) async {
    final gameId = widget.gameId;
    if (gameId == null || gameId.isEmpty) return;

    final finishedAt = DateTime.now().toUtc().toIso8601String();
    await _api.update('games', gameId, {
      'status': 'finished',
      'finished_at': finishedAt,
      'team1_name': widget.team1Name,
      'team2_name': widget.team2Name,
      'team1_score': team1Total,
      'team2_score': team2Total,
      'winner': winner,
      'rounds': rounds,
    });

    await _api.create('reports', {
      'report_type': 'Game result',
      'format': 'local',
      'game_id': gameId,
      'title': '${widget.team1Name} vs ${widget.team2Name}',
      'summary':
          '$winner won ${team1Total.toString()} - ${team2Total.toString()}',
      'winner': winner,
      'team1_name': widget.team1Name,
      'team2_name': widget.team2Name,
      'team1_score': team1Total,
      'team2_score': team2Total,
      'round_count': rounds.length,
      'created_at': finishedAt,
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ACTIVE GAME')),
      body: Column(
        children: [
          // Score Board
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFEFF), Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreColumn(
                  widget.team1Name,
                  team1Total,
                  const Color(0xFF0E7490),
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                _buildScoreColumn(
                  widget.team2Name,
                  team2Total,
                  const Color(0xFF0F766E),
                ),
              ],
            ),
          ),

          // Rounds List
          Expanded(
            child: ListView.builder(
              itemCount: rounds.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRoundScore(
                        widget.team1Name,
                        rounds[index]['t1'] ?? 0,
                        const Color(0xFF0E7490),
                      ),
                      const Text(
                        '-',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      _buildRoundScore(
                        widget.team2Name,
                        rounds[index]['t2'] ?? 0,
                        const Color(0xFF0F766E),
                      ),
                    ],
                  ),
                  subtitle: const Center(child: Text('Round Score')),
                );
              },
            ),
          ),

          // Score Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreField(
                        _t1Controller,
                        '${widget.team1Name} Score',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildScoreField(
                        _t2Controller,
                        '${widget.team2Name} Score',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _addRound,
                    child: const Text(
                      'ADD ROUND',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String name, int score, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundScore(String name, int score, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text('$score', style: TextStyle(fontSize: 18, color: color)),
        ],
      ),
    );
  }

  Widget _buildScoreField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
