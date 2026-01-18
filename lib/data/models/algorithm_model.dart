class AlgorithmModel {
  final String id;
  final String name;
  final String category;
  final String difficulty;
  final List<AlgorithmStep> steps;
  final String explanation;
  final List<String> tags;
  final String? commonMistake;

  AlgorithmModel({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.steps,
    required this.explanation,
    required this.tags,
    this.commonMistake,
  });

  factory AlgorithmModel.fromJson(Map<String, dynamic> json) {
    return AlgorithmModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      difficulty: json['difficulty'],
      steps: (json['steps'] as List)
          .map((step) => AlgorithmStep.fromJson(step))
          .toList(),
      explanation: json['explanation'],
      tags: List<String>.from(json['tags'] ?? []),
      commonMistake: json['commonMistake'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'difficulty': difficulty,
      'steps': steps.map((step) => step.toJson()).toList(),
      'explanation': explanation,
      'tags': tags,
      'commonMistake': commonMistake,
    };
  }
}

class AlgorithmStep {
  final int order;
  final String text;

  AlgorithmStep({
    required this.order,
    required this.text,
  });

  factory AlgorithmStep.fromJson(Map<String, dynamic> json) {
    return AlgorithmStep(
      order: json['order'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'text': text,
    };
  }
}

class GameProgress {
  final String algorithmId;
  final int bestTime;
  final int bestMistakes;
  final int stars;
  final bool completed;
  final DateTime lastPlayed;

  GameProgress({
    required this.algorithmId,
    required this.bestTime,
    required this.bestMistakes,
    required this.stars,
    required this.completed,
    required this.lastPlayed,
  });

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      algorithmId: json['algorithmId'],
      bestTime: json['bestTime'],
      bestMistakes: json['bestMistakes'],
      stars: json['stars'],
      completed: json['completed'],
      lastPlayed: DateTime.parse(json['lastPlayed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algorithmId': algorithmId,
      'bestTime': bestTime,
      'bestMistakes': bestMistakes,
      'stars': stars,
      'completed': completed,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }
}
