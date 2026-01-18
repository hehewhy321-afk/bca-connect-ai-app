import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_score.dart';

class GameRepository {
  static const String _scoresKey = 'game_scores';
  static const String _statsKey = 'game_stats';

  Future<void> saveScore(GameScore score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getAllScores(score.gameId);
    scores.add(score);
    
    // Keep only top 10 scores
    scores.sort((a, b) => b.score.compareTo(a.score));
    if (scores.length > 10) {
      scores.removeRange(10, scores.length);
    }
    
    final key = '${_scoresKey}_${score.gameId}';
    final jsonList = scores.map((s) => s.toJson()).toList();
    await prefs.setString(key, json.encode(jsonList));
    
    // Update stats
    await _updateStats(score);
  }

  Future<List<GameScore>> getAllScores(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_scoresKey}_$gameId';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => GameScore.fromJson(json)).toList();
  }

  Future<int> getHighScore(String gameId) async {
    final scores = await getAllScores(gameId);
    if (scores.isEmpty) return 0;
    return scores.first.score;
  }

  Future<GameStats> getStats(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_statsKey}_$gameId';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) {
      return GameStats(
        gameId: gameId,
        highScore: 0,
        timesPlayed: 0,
      );
    }
    
    return GameStats.fromJson(json.decode(jsonString));
  }

  Future<void> _updateStats(GameScore score) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getStats(score.gameId);
    
    final newStats = GameStats(
      gameId: score.gameId,
      highScore: score.score > stats.highScore ? score.score : stats.highScore,
      timesPlayed: stats.timesPlayed + 1,
      lastPlayed: score.timestamp,
      bestTimeMs: score.timeMs != null && (stats.bestTimeMs == null || score.timeMs! < stats.bestTimeMs!)
          ? score.timeMs
          : stats.bestTimeMs,
    );
    
    final key = '${_statsKey}_${score.gameId}';
    await prefs.setString(key, json.encode(newStats.toJson()));
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_scoresKey) || key.startsWith(_statsKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
