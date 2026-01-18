import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class TargetShooterGameScreen extends StatefulWidget {
  const TargetShooterGameScreen({super.key});

  @override
  State<TargetShooterGameScreen> createState() => _TargetShooterGameScreenState();
}

class _TargetShooterGameScreenState extends State<TargetShooterGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = 30;
  int _combo = 0;
  Timer? _timer;
  
  // Targets
  final List<Target> _targets = [];
  Timer? _targetSpawnTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _targetSpawnTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('target_shooter');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _timeLeft = 30;
      _combo = 0;
      _targets.clear();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
    
    _targetSpawnTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _spawnTarget();
    });
  }

  void _spawnTarget() {
    if (!_isPlaying || _targets.length >= 8) return;
    
    final size = 50.0 + _random.nextDouble() * 30;
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
    
    setState(() {
      _targets.add(Target(
        id: DateTime.now().millisecondsSinceEpoch,
        x: _random.nextDouble() * 0.8 - 0.4,
        y: _random.nextDouble() * 0.8 - 0.4,
        size: size,
        color: colors[_random.nextInt(colors.length)],
        lifespan: 2000 + _random.nextInt(1000),
      ));
    });
    
    // Remove expired targets
    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        _targets.removeWhere((t) => 
          DateTime.now().millisecondsSinceEpoch - t.id > t.lifespan
        );
      });
    });
  }

  void _hitTarget(Target target) {
    if (!_isPlaying) return;
    
    setState(() {
      _targets.remove(target);
      _combo++;
      final points = (10 * (1 + _combo * 0.1)).round();
      _score += points;
      _timeLeft += 1; // Bonus time
    });
    
    HapticFeedback.mediumImpact();
  }

  void _missedTap() {
    setState(() {
      _combo = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _endGame() {
    _timer?.cancel();
    _targetSpawnTimer?.cancel();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });
    
    HapticFeedback.heavyImpact();
    _saveScore();
  }

  Future<void> _saveScore() async {
    if (_score > _bestScore) {
      setState(() {
        _bestScore = _score;
      });
    }
    
    await _repository.saveScore(GameScore(
      gameId: 'target_shooter',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) {
          if (!_isPlaying) return;
          
          bool hitAny = false;
          for (var target in _targets) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            final targetX = screenWidth / 2 + (target.x * screenWidth / 2);
            final targetY = screenHeight / 2 + (target.y * screenHeight / 2);
            
            final dx = details.localPosition.dx - targetX;
            final dy = details.localPosition.dy - targetY;
            final distance = sqrt(dx * dx + dy * dy);
            
            if (distance < target.size / 2) {
              _hitTarget(target);
              hitAny = true;
              break;
            }
          }
          
          if (!hitAny) {
            _missedTap();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C3E50),
                const Color(0xFF4CA1AF),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Header
                _buildHeader(),
                
                // Stats
                if (_isPlaying) _buildStats(),
                
                // Targets
                ..._targets.map((target) => _buildTarget(target)),
                
                // Start screen
                if (!_isPlaying && !_isGameOver) _buildStartScreen(),
                
                // Game over
                if (_isGameOver) _buildGameOverDialog(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 16,
      left: 16,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Iconsax.arrow_left, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text(
            '🎯 Target Shooter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('⏱️', '${_timeLeft}s'),
                _buildStatItem('🎯', '$_score'),
                _buildStatItem('🔥', 'x$_combo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTarget(Target target) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: MediaQuery.of(context).size.width / 2 + (target.x * MediaQuery.of(context).size.width / 2) - target.size / 2,
      top: MediaQuery.of(context).size.height / 2 + (target.y * MediaQuery.of(context).size.height / 2) - target.size / 2,
      child: Container(
        width: target.size,
        height: target.size,
        decoration: BoxDecoration(
          color: target.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: target.color.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.circle,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎯',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              'Target Shooter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap targets before they disappear!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: $_bestScore points',
              style: const TextStyle(
                fontSize: 14,
                color: ModernTheme.primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'START GAME',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏰',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Time\'s Up!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultCard('Score', _score.toString(), '🎯'),
                  _buildResultCard('Best', _bestScore.toString(), '🏆'),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ModernTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class Target {
  final int id;
  final double x;
  final double y;
  final double size;
  final Color color;
  final int lifespan;

  Target({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.lifespan,
  });
}
