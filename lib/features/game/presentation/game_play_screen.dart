import 'package:flutter/material.dart';
import '../../../core/ui/app_alerts.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
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

  void _checkWinner() {
    if (team1Total >= 101 || team2Total >= 101) {
      String winner = team1Total >= 101 ? "Team 1" : "Team 2";
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
                _buildScoreColumn('TEAM 1', team1Total, const Color(0xFF0E7490)),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                _buildScoreColumn('TEAM 2', team2Total, const Color(0xFF0F766E)),
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
                      Text(
                        '${rounds[index]['t1']}',
                        style: const TextStyle(fontSize: 18, color: Color(0xFF0E7490)),
                      ),
                      const Text('-', style: TextStyle(color: Color(0xFF64748B))),
                      Text(
                        '${rounds[index]['t2']}',
                        style: const TextStyle(fontSize: 18, color: Color(0xFF0F766E)),
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
                    Expanded(child: _buildScoreField(_t1Controller, 'Team 1 Score')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildScoreField(_t2Controller, 'Team 2 Score')),
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
                    child: const Text('ADD ROUND', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Text(name, style: const TextStyle(fontSize: 16, color: Color(0xFF475569))),
        Text('$score', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildScoreField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
    );
  }
}
