import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/algorithm_repository.dart';
import '../../../data/models/algorithm_model.dart';
import 'algorithm_game_play_screen.dart';

class AlgorithmCategoryScreen extends StatefulWidget {
  final String category;

  const AlgorithmCategoryScreen({super.key, required this.category});

  @override
  State<AlgorithmCategoryScreen> createState() => _AlgorithmCategoryScreenState();
}

class _AlgorithmCategoryScreenState extends State<AlgorithmCategoryScreen> {
  final _repository = AlgorithmRepository();
  List<AlgorithmModel> _algorithms = [];
  Map<String, GameProgress?> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlgorithms();
  }

  Future<void> _loadAlgorithms() async {
    setState(() => _isLoading = true);
    
    final algorithms = await _repository.getAlgorithmsByCategory(widget.category);
    final progressMap = <String, GameProgress?>{};
    
    for (final algo in algorithms) {
      progressMap[algo.id] = await _repository.getProgress(algo.id);
    }
    
    setState(() {
      _algorithms = algorithms;
      _progressMap = progressMap;
      _isLoading = false;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'Sorting':
        return Iconsax.sort;
      case 'Searching':
        return Iconsax.search_normal_1;
      case 'Data Structures':
        return Iconsax.hierarchy_square;
      case 'Graph Algorithms':
        return Iconsax.diagram;
      default:
        return Iconsax.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlgorithms,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _algorithms.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildHeader(),
                    );
                  }
                  
                  final algo = _algorithms[index - 1];
                  final progress = _progressMap[algo.id];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAlgorithmCard(algo, progress),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final completed = _progressMap.values.where((p) => p?.completed == true).length;
    final totalStars = _progressMap.values.fold(0, (sum, p) => sum + (p?.stars ?? 0));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getDifficultyColor('easy'),
            _getDifficultyColor('medium'),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(_getCategoryIcon(), size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            widget.category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderStat('$completed/${_algorithms.length}', 'Completed'),
              _buildHeaderStat('$totalStars', 'Stars'),
              _buildHeaderStat('${_algorithms.length}', 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmCard(AlgorithmModel algo, GameProgress? progress) {
    final difficultyColor = _getDifficultyColor(algo.difficulty);
    final isCompleted = progress?.completed ?? false;
    final stars = progress?.stars ?? 0;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlgorithmGamePlayScreen(algorithm: algo),
          ),
        ).then((_) => _loadAlgorithms());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? ModernTheme.primaryOrange.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    algo.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCompleted)
                  Row(
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars ? Iconsax.star5 : Iconsax.star,
                        size: 16,
                        color: index < stars ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    algo.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${algo.steps.length} steps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (progress != null) ...[
                  Icon(
                    Iconsax.timer_1,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.bestTime}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Iconsax.play_circle,
                    size: 16,
                    color: ModernTheme.primaryOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to start',
                    style: TextStyle(
                      fontSize: 12,
                      color: ModernTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
