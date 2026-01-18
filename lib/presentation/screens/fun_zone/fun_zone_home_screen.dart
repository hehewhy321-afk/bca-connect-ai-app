import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';
import 'color_match_game_screen.dart';
import 'swipe_mania_game_screen.dart';
import 'tap_master_game_screen.dart';
import 'flappy_code_game_screen.dart';
import 'memory_match_game_screen.dart';
import 'number_rush_game_screen.dart';
import 'snake_game_screen.dart';
import 'game_2048_screen.dart';
import 'brick_breaker_game_screen.dart';
import 'target_shooter_game_screen.dart';
import 'spin_match_game_screen.dart';
import 'balloon_pop_game_screen.dart';
import 'reflex_duel_game_screen.dart';

class FunZoneHomeScreen extends StatefulWidget {
  const FunZoneHomeScreen({super.key});

  @override
  State<FunZoneHomeScreen> createState() => _FunZoneHomeScreenState();
}

class _FunZoneHomeScreenState extends State<FunZoneHomeScreen> {
  final _repository = GameRepository();
  Map<String, GameStats> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    
    final colorMatchStats = await _repository.getStats('color_match');
    final swipeManiaStats = await _repository.getStats('swipe_mania');
    final tapMasterStats = await _repository.getStats('tap_master');
    final flappyCodeStats = await _repository.getStats('flappy_code');
    final memoryMatchStats = await _repository.getStats('memory_match');
    final numberRushStats = await _repository.getStats('number_rush');
    final snakeGameStats = await _repository.getStats('snake_game');
    final game2048Stats = await _repository.getStats('game_2048');
    final brickBreakerStats = await _repository.getStats('brick_breaker');
    final targetShooterStats = await _repository.getStats('target_shooter');
    final spinMatchStats = await _repository.getStats('spin_match');
    final balloonPopStats = await _repository.getStats('balloon_pop');
    final reflexDuelStats = await _repository.getStats('reflex_duel');
    
    setState(() {
      _stats = {
        'color_match': colorMatchStats,
        'swipe_mania': swipeManiaStats,
        'tap_master': tapMasterStats,
        'flappy_code': flappyCodeStats,
        'memory_match': memoryMatchStats,
        'number_rush': numberRushStats,
        'snake_game': snakeGameStats,
        'game_2048': game2048Stats,
        'brick_breaker': brickBreakerStats,
        'target_shooter': targetShooterStats,
        'spin_match': spinMatchStats,
        'balloon_pop': balloonPopStats,
        'reflex_duel': reflexDuelStats,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalGamesPlayed = _stats.values.fold(0, (sum, stat) => sum + stat.timesPlayed);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        '🎮',
                        style: TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'FUN ZONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a break & play!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Stats Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    ModernTheme.primaryOrange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('🎮', totalGamesPlayed.toString(), 'Games Played'),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatItem('🏆', '13', 'Games Available'),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatItem('⭐', _getTotalHighScore().toString(), 'Total Score'),
                ],
              ),
            ),
          ),
          
          // Games Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGameCard(
                  context,
                  title: 'Color Match Madness',
                  subtitle: 'Match colors, not words!',
                  emoji: '🎨',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                  ),
                  stats: _stats['color_match'],
                  onTap: () => _navigateToGame(context, const ColorMatchGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Swipe Mania',
                  subtitle: 'Swipe the opposite way!',
                  emoji: '👆',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  stats: _stats['swipe_mania'],
                  onTap: () => _navigateToGame(context, const SwipeManiaGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Tap Master',
                  subtitle: 'Test your reaction speed!',
                  emoji: '⚡',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                  ),
                  stats: _stats['tap_master'],
                  onTap: () => _navigateToGame(context, const TapMasterGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Flappy Code',
                  subtitle: 'Fly through the pipes!',
                  emoji: '🐦',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  stats: _stats['flappy_code'],
                  onTap: () => _navigateToGame(context, const FlappyCodeGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Memory Match',
                  subtitle: 'Find matching pairs!',
                  emoji: '🧠',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  stats: _stats['memory_match'],
                  onTap: () => _navigateToGame(context, const MemoryMatchGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Number Rush',
                  subtitle: 'Quick math challenges!',
                  emoji: '🔢',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                  ),
                  stats: _stats['number_rush'],
                  onTap: () => _navigateToGame(context, const NumberRushGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Snake Classic',
                  subtitle: 'Eat and grow longer!',
                  emoji: '🐍',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                  stats: _stats['snake_game'],
                  onTap: () => _navigateToGame(context, const SnakeGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: '2048',
                  subtitle: 'Merge tiles to 2048!',
                  emoji: '🎲',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFAD961), Color(0xFFF76B1C)],
                  ),
                  stats: _stats['game_2048'],
                  onTap: () => _navigateToGame(context, const Game2048Screen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Brick Breaker',
                  subtitle: 'Break all the bricks!',
                  emoji: '🧱',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                  ),
                  stats: _stats['brick_breaker'],
                  onTap: () => _navigateToGame(context, const BrickBreakerGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Target Shooter',
                  subtitle: 'Hit targets fast!',
                  emoji: '🎯',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                  ),
                  stats: _stats['target_shooter'],
                  onTap: () => _navigateToGame(context, const TargetShooterGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Spin Match',
                  subtitle: 'Match spinning symbols!',
                  emoji: '🔄',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
                  ),
                  stats: _stats['spin_match'],
                  onTap: () => _navigateToGame(context, const SpinMatchGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Balloon Pop',
                  subtitle: 'Pop before they escape!',
                  emoji: '🎈',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  ),
                  stats: _stats['balloon_pop'],
                  onTap: () => _navigateToGame(context, const BalloonPopGameScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: 'Reflex Duel',
                  subtitle: 'Test your reflexes!',
                  emoji: '⚔️',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF232526), Color(0xFF414345)],
                  ),
                  stats: _stats['reflex_duel'],
                  onTap: () => _navigateToGame(context, const ReflexDuelGameScreen()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ModernTheme.primaryOrange,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Gradient gradient,
    required GameStats? stats,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.game, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${stats?.timesPlayed ?? 0}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatBadge('🏆', '${stats?.highScore ?? 0}'),
                      const SizedBox(width: 8),
                      if (stats?.bestTimeMs != null)
                        _buildStatBadge('⚡', '${stats!.bestTimeMs}ms'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalHighScore() {
    return _stats.values.fold(0, (sum, stat) => sum + stat.highScore);
  }

  Future<void> _navigateToGame(BuildContext context, Widget gameScreen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
    _loadStats(); // Refresh stats after returning
  }
}
