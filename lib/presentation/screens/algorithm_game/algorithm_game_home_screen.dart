import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/algorithm_repository.dart';
import 'algorithm_category_screen.dart';

class AlgorithmGameHomeScreen extends StatefulWidget {
  const AlgorithmGameHomeScreen({super.key});

  @override
  State<AlgorithmGameHomeScreen> createState() => _AlgorithmGameHomeScreenState();
}

class _AlgorithmGameHomeScreenState extends State<AlgorithmGameHomeScreen> {
  final _repository = AlgorithmRepository();
  int _totalStars = 0;
  int _completedCount = 0;
  int _totalAlgorithms = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stars = await _repository.getTotalStars();
    final completed = await _repository.getCompletedCount();
    final algorithms = await _repository.loadAlgorithms();
    
    setState(() {
      _totalStars = stars;
      _completedCount = completed;
      _totalAlgorithms = algorithms.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm Master'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.info_circle),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: ModernTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Iconsax.game, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Master Algorithms Through Play',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Arrange algorithm steps in correct order',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('⭐', _totalStars.toString(), 'Stars'),
                        _buildStat('✅', '$_completedCount/$_totalAlgorithms', 'Completed'),
                        _buildStat('🎯', '${(_completedCount / (_totalAlgorithms > 0 ? _totalAlgorithms : 1) * 100).toInt()}%', 'Progress'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Categories
              const Text(
                'Choose Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              _buildCategoryCard(
                context,
                'Sorting',
                'Bubble, Selection, Merge, Quick Sort',
                Iconsax.sort,
                const Color(0xFF6366F1),
                8,
              ),
              
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                context,
                'Searching',
                'Binary Search, Linear Search',
                Iconsax.search_normal_1,
                const Color(0xFF8B5CF6),
                2,
              ),
              
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                context,
                'Data Structures',
                'Stack, Queue, Linked List, BST',
                Iconsax.hierarchy_square,
                const Color(0xFFEC4899),
                8,
              ),
              
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                context,
                'Graph Algorithms',
                'BFS, DFS, Dijkstra',
                Iconsax.diagram,
                const Color(0xFF10B981),
                5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
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

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int algorithmCount,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlgorithmCategoryScreen(category: title),
          ),
        ).then((_) => _loadStats());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$algorithmCount algorithms',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: color),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Arrange shuffled algorithm steps in correct order'),
              SizedBox(height: 12),
              Text('🎮 How to Play', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Drag steps from bottom to top slots\n• Or tap to place in order\n• Complete all steps correctly'),
              SizedBox(height: 12),
              Text('⭐ Scoring', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• 3 stars: Perfect (< 30s, 0 mistakes)\n• 2 stars: Good (< 60s, < 3 mistakes)\n• 1 star: Completed'),
              SizedBox(height: 12),
              Text('💡 Tips', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Read explanation after completing\n• Practice makes perfect\n• All progress saved locally'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
