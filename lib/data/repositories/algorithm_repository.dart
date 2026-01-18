import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/algorithm_model.dart';

class AlgorithmRepository {
  static const String _progressKey = 'algorithm_progress';
  
  Future<List<AlgorithmModel>> loadAlgorithms() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/algorithms.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AlgorithmModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load algorithms: $e');
    }
  }

  Future<List<AlgorithmModel>> getAlgorithmsByCategory(String category) async {
    final algorithms = await loadAlgorithms();
    return algorithms.where((algo) => algo.category == category).toList();
  }

  Future<List<AlgorithmModel>> getAlgorithmsByDifficulty(String difficulty) async {
    final algorithms = await loadAlgorithms();
    return algorithms.where((algo) => algo.difficulty == difficulty).toList();
  }

  Future<AlgorithmModel?> getAlgorithmById(String id) async {
    final algorithms = await loadAlgorithms();
    try {
      return algorithms.firstWhere((algo) => algo.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getCategories() async {
    final algorithms = await loadAlgorithms();
    return algorithms.map((algo) => algo.category).toSet().toList();
  }

  // Progress Management
  Future<void> saveProgress(GameProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressList = await getAllProgress();
    
    // Remove existing progress for this algorithm
    progressList.removeWhere((p) => p.algorithmId == progress.algorithmId);
    
    // Add new progress
    progressList.add(progress);
    
    // Save to SharedPreferences
    final jsonList = progressList.map((p) => p.toJson()).toList();
    await prefs.setString(_progressKey, json.encode(jsonList));
  }

  Future<List<GameProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_progressKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => GameProgress.fromJson(json)).toList();
  }

  Future<GameProgress?> getProgress(String algorithmId) async {
    final progressList = await getAllProgress();
    try {
      return progressList.firstWhere((p) => p.algorithmId == algorithmId);
    } catch (e) {
      return null;
    }
  }

  Future<int> getTotalStars() async {
    final progressList = await getAllProgress();
    int total = 0;
    for (final progress in progressList) {
      total += progress.stars;
    }
    return total;
  }

  Future<int> getCompletedCount() async {
    final progressList = await getAllProgress();
    return progressList.where((p) => p.completed).length;
  }

  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }
}
