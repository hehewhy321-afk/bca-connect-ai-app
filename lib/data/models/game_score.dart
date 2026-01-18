class GameScore {
  final String gameId;
  final int score;
  final DateTime timestamp;
  final int? timeMs; // For reaction time games
  final int? accuracy; // For accuracy-based games

  GameScore({
    required this.gameId,
    required this.score,
    required this.timestamp,
    this.timeMs,
    this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
      'timeMs': timeMs,
      'accuracy': accuracy,
    };
  }

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      gameId: json['gameId'],
      score: json['score'],
      timestamp: DateTime.parse(json['timestamp']),
      timeMs: json['timeMs'],
      accuracy: json['accuracy'],
    );
  }
}

class GameStats {
  final String gameId;
  final int highScore;
  final int timesPlayed;
  final DateTime? lastPlayed;
  final int? bestTimeMs;

  GameStats({
    required this.gameId,
    required this.highScore,
    required this.timesPlayed,
    this.lastPlayed,
    this.bestTimeMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'highScore': highScore,
      'timesPlayed': timesPlayed,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'bestTimeMs': bestTimeMs,
    };
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      gameId: json['gameId'],
      highScore: json['highScore'],
      timesPlayed: json['timesPlayed'],
      lastPlayed: json['lastPlayed'] != null ? DateTime.parse(json['lastPlayed']) : null,
      bestTimeMs: json['bestTimeMs'],
    );
  }
}
