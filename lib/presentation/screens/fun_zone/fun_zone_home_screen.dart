import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _FunZoneHomeScreenState extends State<FunZoneHomeScreen> with TickerProviderStateMixin {
  final _repository = GameRepository();
  final _audioPlayer = AudioPlayer();
  Map<String, GameStats> _stats = {};
  int _logoTapCount = 0;
  DateTime? _lastTapTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
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
      _isLoading = false;
    });
  }

  Future<void> _handleLogoTap() async {
    final now = DateTime.now();
    
    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _logoTapCount = 0;
    }
    
    _lastTapTime = now;
    _logoTapCount++;
    
    // Easter egg: Play sound after 3-4 taps
    if (_logoTapCount >= 3 && _logoTapCount <= 4) {
      HapticFeedback.heavyImpact();
      try {
        await _audioPlayer.play(AssetSource('data/amit-sound.mp3'));
        
        // Show fun message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('🎉'),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You found the secret! 🎮',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: ModernTheme.primaryOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Reset counter after playing
        _logoTapCount = 0;
      } catch (e) {
        // Silently handle audio playback errors
        debugPrint('Error playing sound: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGamesPlayed = _stats.values.fold(0, (sum, stat) => sum + stat.timesPlayed);
    final totalHighScore = _stats.values.fold(0, (sum, stat) => sum + stat.highScore);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.transparent,
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
                      ModernTheme.primaryOrange,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated background circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                          .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                          .then()
                          .scale(duration: 3.seconds, begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                          .scale(duration: 2.5.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3))
                          .then()
                          .scale(duration: 2.5.seconds, begin: const Offset(1.3, 1.3), end: const Offset(1, 1)),
                    ),
                    
                    // Content
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Tappable game logo (Easter egg)
                            GestureDetector(
                              onTap: _handleLogoTap,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '🎮',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                                  .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3))
                                  .then(delay: 1.seconds),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'FUN ZONE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                            const SizedBox(height: 8),
                            Text(
                              'Take a break & play amazing games!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.game,
                      value: totalGamesPlayed.toString(),
                      label: 'Games Played',
                      color: const Color(0xFF6366F1),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.cup,
                      value: totalHighScore.toString(),
                      label: 'Total Score',
                      color: ModernTheme.primaryOrange,
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.star5,
                      value: '14',
                      label: 'Games',
                      color: const Color(0xFFEC4899),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),
                  ),
                ],
              ),
            ),
          ),
          
          // Games Grid
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1.5.seconds),
                  childCount: 6,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate([
                  _buildModernGameCard(
                    context,
                    title: 'Color Match',
                    emoji: '🎨',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                    ),
                    stats: _stats['color_match'],
                    onTap: () => _navigateToGame(context, const ColorMatchGameScreen()),
                    index: 0,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Swipe Mania',
                    emoji: '👆',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    stats: _stats['swipe_mania'],
                    onTap: () => _navigateToGame(context, const SwipeManiaGameScreen()),
                    index: 1,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Tap Master',
                    emoji: '⚡',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                    ),
                    stats: _stats['tap_master'],
                    onTap: () => _navigateToGame(context, const TapMasterGameScreen()),
                    index: 2,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Flappy Code',
                    emoji: '🐦',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    ),
                    stats: _stats['flappy_code'],
                    onTap: () => _navigateToGame(context, const FlappyCodeGameScreen()),
                    index: 3,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Memory Match',
                    emoji: '🧠',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    stats: _stats['memory_match'],
                    onTap: () => _navigateToGame(context, const MemoryMatchGameScreen()),
                    index: 4,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Number Rush',
                    emoji: '🔢',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                    stats: _stats['number_rush'],
                    onTap: () => _navigateToGame(context, const NumberRushGameScreen()),
                    index: 5,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Snake Classic',
                    emoji: '🐍',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                    ),
                    stats: _stats['snake_game'],
                    onTap: () => _navigateToGame(context, const SnakeGameScreen()),
                    index: 6,
                  ),
                  _buildModernGameCard(
                    context,
                    title: '2048',
                    emoji: '🎲',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAD961), Color(0xFFF76B1C)],
                    ),
                    stats: _stats['game_2048'],
                    onTap: () => _navigateToGame(context, const Game2048Screen()),
                    index: 7,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Brick Breaker',
                    emoji: '🧱',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                    ),
                    stats: _stats['brick_breaker'],
                    onTap: () => _navigateToGame(context, const BrickBreakerGameScreen()),
                    index: 8,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Target Shooter',
                    emoji: '🎯',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                    ),
                    stats: _stats['target_shooter'],
                    onTap: () => _navigateToGame(context, const TargetShooterGameScreen()),
                    index: 9,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Spin Match',
                    emoji: '🔄',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
                    ),
                    stats: _stats['spin_match'],
                    onTap: () => _navigateToGame(context, const SpinMatchGameScreen()),
                    index: 10,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Balloon Pop',
                    emoji: '🎈',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                    ),
                    stats: _stats['balloon_pop'],
                    onTap: () => _navigateToGame(context, const BalloonPopGameScreen()),
                    index: 11,
                  ),
                  _buildModernGameCard(
                    context,
                    title: 'Reflex Duel',
                    emoji: '⚔️',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF232526), Color(0xFF414345)],
                    ),
                    stats: _stats['reflex_duel'],
                    onTap: () => _navigateToGame(context, const ReflexDuelGameScreen()),
                    index: 12,
                  ),
                ]),
              ),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernGameCard(
    BuildContext context, {
    required String title,
    required String emoji,
    required Gradient gradient,
    required GameStats? stats,
    required VoidCallback onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background emoji
            Positioned(
              right: -15,
              bottom: -15,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 80,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji and play count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      if ((stats?.timesPlayed ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${stats!.timesPlayed}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // High score
                  if ((stats?.highScore ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🏆',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stats!.highScore}',
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
            ),
          ],
        ),
      ).animate().fadeIn(
        duration: 400.ms,
        delay: (index * 50).ms,
      ).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Future<void> _navigateToGame(BuildContext context, Widget gameScreen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
    _loadStats(); // Refresh stats after returning
  }
}
