enum GameStatus { active, finished, cancelled }

class Player {
  final String id;
  final String name;
  final String nickname;
  final String? photoUrl;
  final int totalWins;
  final int totalLosses;

  Player({
    required this.id,
    required this.name,
    required this.nickname,
    this.photoUrl,
    this.totalWins = 0,
    this.totalLosses = 0,
  });
}

class Team {
  final String name;
  final Player player1;
  final Player player2;
  int currentScore;

  Team({
    required this.name,
    required this.player1,
    required this.player2,
    this.currentScore = 0,
  });
}

class Round {
  final int roundNumber;
  final int team1Score;
  final int team2Score;
  final DateTime timestamp;

  Round({
    required this.roundNumber,
    required this.team1Score,
    required this.team2Score,
    required this.timestamp,
  });
}

class Game {
  final String id;
  final Team team1;
  final Team team2;
  final List<Round> rounds;
  final GameStatus status;
  final DateTime startTime;
  final int winningScore;

  Game({
    required this.id,
    required this.team1,
    required this.team2,
    required this.rounds,
    this.status = GameStatus.active,
    required this.startTime,
    this.winningScore = 101,
  });
}
